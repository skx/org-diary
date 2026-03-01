;;; org-diary.el --- A package for maintaining a self-contained diary.

;; Author: Steve Kemp <steve@steve.fi>
;; Version: 1.0
;; Keywords: outlines, diary, journal
;; URL: https://github.com/skx/org-diary

;; Package-Requires: ((emacs "28.0") (org "9.0"))

;; This file is not part of GNU Emacs.

;; This file is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this file.  If not, see <https://www.gnu.org/licenses/>.


;;; Commentary:

;; This is a derived mode of org-mode, which contains a couple of helpers
;; for maintaining a simple diary.
;;
;; A diary is nothing more than an org-mode file which contains a list
;; of date-based headers, for example:
;;
;;   * 01/01/2022
;;   ** Meetings
;;   ** TODO
;;   * 02/01/2022
;;   ** Meetings
;;   ** TODO
;;   * 03/01/2022
;;   ** Meetings
;;   ** TODO
;;   * DD/MM/YYYY
;;   ** Meetings
;;   ** TODO
;;   * END
;;
;; The idea is that you might maintain a standard entry template, and you
;; can add a new entry for each new-day.
;;

;;; Code:

(eval-when-compile (require 'subr-x))

;; List of things we expand within a new entry, as we create it.
;;
;; The pairs are "regexp" + "replacement" which is invoked via "apply".
(setq org-diary-template-variables '(
                                   ( "YYYY"       . (format-time-string "%Y"))
                                   ( "MM"         . (format-time-string "%m"))
                                   ( "DD"         . (format-time-string "%d"))
                                   ( "HOUR"       . (format-time-string "%H"))
                                   ( "MINUTE"     . (format-time-string "%M"))
                                   ( ":noexport:" . (format ""))))



(defvar org-diary-date-format "^\\* %d/%m/%Y"
  "Format string for matching date-based headers.

Currently supported placeholders include:
%Y is the year as decimal number, including the century.
%m is the month as a decimal number (range 01 to 12).
%d is the day as a decimal number (range 01 to 31).
%V is the ISO 8601 week number as a decimal number (range 01 to 53).
%a is the locale’s abbreviated name of the day of week, %A the full name.
%b is the locale's abbreviated name of the month, %B the full name.")


;; Define a keymap for this mode.
(defvar org-diary-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-p") 'org-previous-visible-heading)
    (define-key map (kbd "C-n") 'org-next-visible-heading)
    map))


;; Define our derived mode
(define-derived-mode org-diary-mode
  org-mode "org-diary"
  "Major mode for maintaining an org-based diary.")


;; Ensure it is used for Diary.org files
(add-to-list 'auto-mode-alist
             '("[dD][iI][aA][rR][yY]\\.[oO][rR][gG]" . org-diary-mode))


;; Now add functions



(defun org-diary-today ()
  "Jump to today's entry within the current `org-diary' file, if it exists."
  (interactive)
  (if (not (eq major-mode 'org-diary-mode))
      (error "Error: You're not visiting an org-diary file/buffer"))
  (let ((pos nil))
    (save-excursion
      (org-save-outline-visibility t
        (outline-show-all)
        (goto-char (point-min))
        (if (re-search-forward (format-time-string org-diary-date-format) nil t)
            (setq pos (point))
          (message "No entry for today found."))))
    (if pos
        (progn
          (outline-show-all)
          (goto-char pos)
          (run-hooks 'org-diary-after-today-hook)
          t)
      nil)))


(defun org-diary-new-entry ()
  "Create a new entry for today, if it is not yet present."
    (interactive)
    (if (org-diary-today)
        (message "An entry for today is already present!")
      (progn
        (org-diary-insert-new)
        (org-diary-today) ; jump to the new entry
        (run-hooks 'org-diary-after-new-entry-hook))))


(defun org-diary-insert-new ()
  "Actually insert a new diary-template.

It is assumed a Diary.org file will contain a template, contained between
the literal text '* DD/MM/YYYY' and '* END'.  This will be copied into a new
entry, and have its variables expanded."
  (let ((start nil)
        (text nil)
        (case-fold-search nil) ; This ensures our replacements match "HOURS" not "Worked Hours"
        (end nil))
    (save-excursion
      (outline-show-all)
      (goto-char (point-min))
      (if (not (re-search-forward "^\* DD/MM/YYYY" (point-max) t))
          (error "This buffer does not contain a template-block to insert as a new entry"))
      (beginning-of-line)
      (backward-char 1)
      (setq start (point))
      ;; point is at the line before "* DD/MM"
      ;; So we want to skip forward
      (forward-line 2)
      (re-search-forward "END$")
      (beginning-of-line)
      (backward-char 1)
      (setq end (point))
      (setq text (buffer-substring start end))
      (goto-char start)

      (dolist (item org-diary-template-variables)
          (setq text (replace-regexp-in-string (car item) (apply (cdr item)) text)))

        (insert text))))


(defun org-diary-clear-subtree ()
  "Delete the subtree we're inside.

  We move to the start of the heading, record our position, then the
  end of the tree and work backwards until we've gone too far."
    (let (start)
      (save-excursion
        (org-back-to-heading t)
        (setq start (point))
        (org-end-of-subtree t)
        (while (>= (point) start)
          (delete-char -1)))))

(defun org-diary-remove-empty-sections (backend)
  "Remove empty sections from a diary on export.

Empty here means either literally empty, or having the content which
literally reads 'None' or 'None.'.

BACKEND is the name of the exporting backend in-use."
  (save-excursion
    (outline-show-all)
    (goto-char (point-min))

    (org-map-entries
     '(lambda ()
        (let* ((entry (string-trim (substring-no-properties (format "%s" (org-get-entry))))))
          (if (or (string-collate-equalp "None." entry)
                  (string-collate-equalp "None" entry)
                  (string-collate-equalp "" entry))
                  (org-diary-clear-subtree)))))))


;; Add a pre-export hook to remove empty sections.
(add-hook 'org-export-before-parsing-hook 'org-diary-remove-empty-sections)

;; Add a hook to jump to today's entry, if present, on-load
(add-hook 'org-diary-mode-hook
    (lambda()
        (message "Loading today's entry")
        (org-diary-today)))


(provide 'org-diary)

;;; org-diary.el ends here
