#!/usr/bin/env bash
# Regenerate zshrs-stdlib.el from the zshrs binary's own reflection tables, so
# the font-lock keywords carry the real language surface and never drift. Run
# after a zshrs upgrade.
#
#   ./scripts/gen-stdlib.sh             # uses `zshrs` on $PATH and `emacs`
#   ZSHRS=/path/to/zshrs EMACS=/path/to/emacs ./scripts/gen-stdlib.sh
#
# Source of truth (the binary, not a hand-maintained list):
#   zshrs --dump-reflection | jq ...
#     builtins     : .builtins | keys[]      (regex-filtered to word identifiers)
#     extensions   : .extensions | keys[]    (regex-filtered to word identifiers)
#     special_vars : .special_vars | keys[]  (regex-filtered to word identifiers)
#
# Builtins EXCLUDE the static keyword names (font-locked as keywords in
# zshrs-mode.el) and the extension names (font-locked with their own face), so
# every name lands in exactly one category.
#
# zshrs has a SMALL surface (~137 builtins / ~113 extensions / ~245 special
# vars), so the alternations are precomputed with Emacs' `regexp-opt` (a trie).
# No hash tables, no "Regular expression too big" problem. All regexp work
# happens inside Emacs (scripts/gen-stdlib.el); the shell only passes paths.
set -euo pipefail

zshrs="${ZSHRS:-zshrs}"
emacs_bin="${EMACS:-emacs}"
here="$(cd "$(dirname "$0")/.." && pwd)"
out="$here/zshrs-stdlib.el"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# Only word identifiers can be matched with a \_<NAME\_> regexp; drop sigil and
# dotted names (#, $, *, .sh.command, ...).
ident_re='^[A-Za-z_][A-Za-z0-9_]*$'

refl="$tmp/refl.json"
"$zshrs" --dump-reflection > "$refl"

jq -r '.extensions | keys[]'   "$refl" | grep -E "$ident_re" | sort -u > "$tmp/ext.txt"
jq -r '.special_vars | keys[]' "$refl" | perl -pe 's/^\$//' | grep -E "$ident_re" | sort -u > "$tmp/sv.txt"
jq -r '.builtins | keys[]'     "$refl" | grep -E "$ident_re" | sort -u > "$tmp/b_all.txt"

# Static keyword names font-locked as keywords in zshrs-mode.el — kept in sync
# with zshrs--control-keywords + zshrs--declarations there.
sort -u > "$tmp/kw.txt" <<'KW'
always
case
do
done
elif
else
end
esac
fi
for
foreach
if
in
repeat
select
then
until
while
function
break
continue
exit
logout
return
declare
export
float
integer
let
local
readonly
set
shift
typeset
KW

# builtins minus keywords minus extensions
comm -23 "$tmp/b_all.txt" "$tmp/kw.txt" | comm -23 - "$tmp/ext.txt" > "$tmp/b.txt"

nb="$(wc -l < "$tmp/b.txt" | tr -d ' ')"
nx="$(wc -l < "$tmp/ext.txt" | tr -d ' ')"
ns="$(wc -l < "$tmp/sv.txt" | tr -d ' ')"
ver="$("$zshrs" --version 2>/dev/null | grep -oE 'v?[0-9]+\.[0-9]+\.[0-9]+' | head -1)"

"$emacs_bin" --batch -l "$here/scripts/gen-stdlib.el" \
  --eval "(zshrs-gen \"$tmp/b.txt\" \"$tmp/ext.txt\" \"$tmp/sv.txt\" \"$out\" \"${ver:-unknown}\" \"$nb\" \"$nx\" \"$ns\")"

echo "wrote $out ($(wc -c < "$out" | tr -d ' ') bytes; $nb builtins, $nx extensions, $ns special vars, zshrs ${ver:-unknown})"
