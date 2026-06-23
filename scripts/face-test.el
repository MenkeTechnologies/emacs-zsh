;;; face-test.el --- Assert zshrs-mode font-lock faces -*- lexical-binding: t; -*-

;; Loads zshrs-mode, fontifies a sample, and asserts the face applied at the
;; first occurrence of each probe token. Run:
;;   emacs --batch -L . -l scripts/face-test.el

;;; Code:

(require 'zshrs-mode)

(defvar zshrs-face-test--sample
  (concat
   "#!/usr/bin/env zsh\n"
   "typeset -a names\n"
   "for f in *.txt; do\n"
   "    bindkey '^X' accept-line\n"
   "    local out=\"hello world\"\n"
   "    echo $PATH\n"
   "    base64 < \"$f\"\n"
   "done\n"
   "# a trailing comment\n"))

(defun zshrs-face-test--face-of (token)
  "Return the face text-property at the start of the first whole-symbol TOKEN.
Case-sensitive and symbol-bounded so e.g. \"for\" does not match \"fortune\"."
  (goto-char (point-min))
  (let ((case-fold-search nil))
    (if (re-search-forward (concat "\\_<" (regexp-quote token) "\\_>") nil t)
        (let ((face (get-text-property (match-beginning 0) 'face)))
          (if (listp face) (car face) face))
      'NOT-FOUND)))

(let ((checks
       '(("typeset" . font-lock-keyword-face)
         ("for"     . font-lock-keyword-face)
         ("do"      . font-lock-keyword-face)
         ("done"    . font-lock-keyword-face)
         ("local"   . font-lock-keyword-face)
         ("bindkey" . font-lock-builtin-face)
         ("base64"  . zshrs-extension-face)
         ("PATH"    . font-lock-variable-name-face)))
      (failed 0))
  (with-temp-buffer
    (insert zshrs-face-test--sample)
    (zshrs-mode)
    (font-lock-ensure)
    ;; quoted string + comment via syntax table.  Probe an inner word, not the
    ;; delimiter / `#' itself.
    (let* ((str-face (zshrs-face-test--face-of "hello"))
           (com-face (zshrs-face-test--face-of "trailing")))
      (dolist (probe checks)
        (let* ((token (car probe))
               (want (cdr probe))
               (got (zshrs-face-test--face-of token))
               (ok (eq got want)))
          (unless ok (setq failed (1+ failed)))
          (princ (format "%s  %-12s want=%-30s got=%s\n"
                         (if ok "PASS" "FAIL") token want got))))
      (let ((ok (eq str-face 'font-lock-string-face)))
        (unless ok (setq failed (1+ failed)))
        (princ (format "%s  %-12s want=%-30s got=%s\n"
                       (if ok "PASS" "FAIL") "<string>" 'font-lock-string-face str-face)))
      (let ((ok (eq com-face 'font-lock-comment-face)))
        (unless ok (setq failed (1+ failed)))
        (princ (format "%s  %-12s want=%-30s got=%s\n"
                       (if ok "PASS" "FAIL") "<comment>" 'font-lock-comment-face com-face)))))
  (princ (if (zerop failed) "\nALL FACE CHECKS PASSED\n" (format "\n%d CHECK(S) FAILED\n" failed)))
  (kill-emacs (if (zerop failed) 0 1)))

;;; face-test.el ends here
