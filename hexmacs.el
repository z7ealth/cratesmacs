;;; hexmacs.el --- Highlight outdated Hex deps in mix.exs -*- lexical-binding: t; -*-

;; Author: Hector Salinas
;; Version: 0.1
;; Package-Requires: ((emacs "26.1"))
;; Keywords: elixir, hex, tools
;; URL: https://github.com/hsalinas/hexmacs

;;; Commentary:

;; Automatically runs `mix hex.outdated` when opening `mix.exs` and displays
;; ✓ or ✗ inline depending on dependency status.

;;; Code:

(require 'cl-lib)

(defgroup hexmacs nil
  "Automatically check and annotate outdated Hex dependencies."
  :prefix "hexmacs-"
  :group 'tools)

(defcustom hexmacs-command "mix hex.outdated"
  "Shell command used to fetch outdated dependencies."
  :type 'string
  :group 'hexmacs)

(defvar-local hexmacs--overlays nil
  "Overlays used to annotate mix.exs dependencies.")

(defun hexmacs--clear-overlays ()
  "Remove all overlays created by hexmacs."
  (mapc #'delete-overlay hexmacs--overlays)
  (setq hexmacs--overlays nil))

(defun hexmacs--collect-outdated ()
  "Return a list of outdated dependencies by parsing `mix hex.outdated` output.
Considers only those with status `Update possible`."
  (let* ((buf-dir (if buffer-file-name
                      (file-name-directory buffer-file-name)
                    default-directory))
         (project-root (locate-dominating-file buf-dir "mix.exs"))
         (default-directory (or project-root default-directory))
         (output (shell-command-to-string hexmacs-command))
         (lines (split-string output "\n"))
         (outdated '()))
    (message "Running in directory: %s" default-directory)
    (message "mix hex.outdated output:\n%s" output)
    ;; skip header line(s) until we find the one that starts with "Dependency"
    (while (and lines (not (string-match-p "^Dependency" (car lines))))
      (setq lines (cdr lines)))
    ;; drop header line ("Dependency ...")
    (setq lines (cdr lines))
    ;; parse lines and collect outdated deps
    (dolist (line lines)
      (when (string-match
             "^\\([^ ]+\\) +[^ ]+ +[^ ]+ +\\(Update possible\\|Update not possible\\|Up-to-date\\)" line)
        (let ((dep (match-string 1 line))
              (status (match-string 2 line)))
          (when (string-equal status "Update possible")
            (push dep outdated)))))
    outdated))

(defun hexmacs--annotate-deps ()
  "Parse mix.exs buffer and annotate deps with ✓ or ✗."
  (when (and buffer-file-name
             (string-equal (file-name-nondirectory buffer-file-name) "mix.exs"))
    (save-excursion
      (goto-char (point-min))
      (hexmacs--clear-overlays)
      (let ((outdated (hexmacs--collect-outdated)))
        (while (re-search-forward "{:\\([^}]+?\\)," nil t)
          (let* ((dep (match-string 1))
                 (start (line-end-position))
                 (icon (if (member dep outdated)
                           (propertize " ✗" 'face 'error)
                         (propertize " ✓" 'face 'success)))
                 (ov (make-overlay start start)))
            (overlay-put ov 'after-string icon)
            (message "Checking dep '%s', outdated list: %S" dep outdated)
            (push ov hexmacs--overlays)))))))

(defun hexmacs--maybe-run ()
  "Run outdated check and annotate if current buffer is mix.exs."
  (when (and buffer-file-name
             (string-equal (file-name-nondirectory buffer-file-name) "mix.exs"))
    (hexmacs--annotate-deps)))

;;;###autoload
(define-minor-mode hexmacs-mode
  "Minor mode to check Hex dependencies and show icons in `mix.exs`."
  :lighter " 🧪Hexmacs"
  :global t
  :group 'hexmacs
  (if hexmacs-mode
      (add-hook 'find-file-hook #'hexmacs--maybe-run)
    (remove-hook 'find-file-hook #'hexmacs--maybe-run)))

(provide 'hexmacs)

;;; hexmacs.el ends here
