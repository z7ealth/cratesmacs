;;; cratesmacs.el --- Highlight outdated Rust deps in Cargo.toml -*- lexical-binding: t; -*-

;; Author: Hector Salinas
;; Version: 0.1
;; Package-Requires: ((emacs "26.1"))
;; Keywords: rust, cargo, tools
;; URL: https://github.com/hsalinas/cratesmacs

;;; Commentary:

;; Automatically runs `cargo outdated` when opening `Cargo.toml` and displays
;; ✓ or ✗ inline depending on dependency status.

;;; Code:

(require 'cl-lib)

(defgroup cratesmacs nil
  "Automatically check and annotate outdated Cargo dependencies."
  :prefix "cratesmacs-"
  :group 'tools)

(defcustom cratesmacs-command "cargo outdated --depth=1"
  "Shell command used to fetch outdated dependencies."
  :type 'string
  :group 'cratesmacs)

(defvar-local cratesmacs--overlays nil
  "Overlays used to annotate Cargo.toml dependencies.")

(defun cratesmacs--clear-overlays ()
  "Remove all overlays created by cratesmacs."
  (mapc #'delete-overlay cratesmacs--overlays)
  (setq cratesmacs--overlays nil))

(defun cratesmacs--collect-outdated ()
  "Return a list of outdated dependencies from `cargo outdated` output."
  (let* ((buf-dir (if buffer-file-name
                      (file-name-directory buffer-file-name)
                    default-directory))
         (project-root (locate-dominating-file buf-dir "Cargo.toml"))
         (default-directory (or project-root default-directory))
         (output (shell-command-to-string cratesmacs-command))
         (lines (split-string output "\n"))
         (outdated '()))
    (message "cargo outdated output:\n%s" output)
    ;; skip until we reach "Name" header
    (while (and lines (not (string-match-p "^Name" (car lines))))
      (setq lines (cdr lines)))
    (setq lines (cdr lines)) ;; drop header
    ;; collect outdated packages (where latest != current)
    (dolist (line lines)
      (when (string-match "^\\([^ ]+\\) +[^ ]+ +[^ ]+ +\\([^ ]+\\)" line)
        (let ((dep (match-string 1 line))
              (latest (match-string 2 line)))
          (unless (string= latest "-")
            (push dep outdated)))))
    outdated))

(defun cratesmacs--annotate-deps ()
  "Parse Cargo.toml buffer and annotate dependencies with ✓ or ✗."
  (when (and buffer-file-name
             (string-equal (file-name-nondirectory buffer-file-name) "Cargo.toml"))
    (save-excursion
      (goto-char (point-min))
      (cratesmacs--clear-overlays)
      (let ((outdated (ignore-errors (cratesmacs--collect-outdated)))
            (in-deps-section nil))
        (while (not (eobp))
          (let ((line (thing-at-point 'line t)))
            ;; Toggle section parsing
            (cond
             ((string-match-p "^[ \t]*\\[\\(dev-\\)?dependencies\\]" line)
              (setq in-deps-section t))
             ((string-match-p "^[ \t]*\\[.*\\]" line) ; any other section
              (setq in-deps-section nil)))

            ;; If we're in the deps section, try matching deps
            (when (and in-deps-section
                       (string-match "^\\([a-zA-Z0-9_-]+\\)[ \t]*=" line))
              (let* ((dep (match-string 1 line))
                     (start (line-end-position))
                     (icon (if (and outdated (member dep outdated))
                               (propertize " ✗" 'face 'error)
                             (propertize " ✓" 'face 'success)))
                     (ov (make-overlay start start)))
                (overlay-put ov 'after-string icon)
                (push ov cratesmacs--overlays))))
          (forward-line 1))))))

(defun cratesmacs--maybe-run ()
  "Safely run outdated check if the buffer is ready and is Cargo.toml."
  (when (and buffer-file-name
             (string-equal (file-name-nondirectory buffer-file-name) "Cargo.toml")
             (eq major-mode 'conf-toml-mode)) ;; Ensure we’re not in a scratch buffer
    (run-with-idle-timer
     0.1 nil #'cratesmacs--annotate-deps)))

;;;###autoload
(define-minor-mode cratesmacs-mode
  "Minor mode to check Cargo dependencies and show icons in `Cargo.toml`."
  :lighter " 🦀Cratesmacs"
  :global t
  :group 'cratesmacs
  (if cratesmacs-mode
      (add-hook 'find-file-hook #'cratesmacs--maybe-run)
    (remove-hook 'find-file-hook #'cratesmacs--maybe-run)))

(provide 'cratesmacs)

;;; cratesmacs.el ends here
