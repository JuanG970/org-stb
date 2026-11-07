;;; org-stb.el --- Simple Time Balancing for Org Agenda -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Juan Gonzalez

;; Author: Juan Gonzalez
;; Version: 0.1.0
;; Package-Requires: ((emacs "26.1") (org "9.0"))
;; Keywords: org, calendar, scheduling
;; URL: https://github.com/yourusername/org-stb

;;; Commentary:

;; org-stb (Simple Time Balancing) provides utilities for rescheduling
;; org-agenda items. Core features:
;;
;; - Shift items by any amount of time
;; - Shift all scheduled items in chain
;; - Move by time increments (e.g., 30 min)
;;
;; Core principles: KISS, DRY, TDD

;;; Code:

(require 'org-agenda)

(defgroup org-stb nil
  "Simple Time Balancing for Org Agenda."
  :group 'org
  :prefix "org-stb-")

(defcustom org-stb-default-increment 30
  "Default time increment in minutes."
  :type 'integer
  :group 'org-stb)

;;; Core Functions

(defconst org-stb--planning-properties '("SCHEDULED" "DEADLINE")
  "Planning properties `org-stb-shift-time' can shift, in priority order.")

(defun org-stb--entry-timestamp ()
  "Return the planning timestamp of the current entry.
The value is a cons (PROPERTY . TIMESTAMP), choosing the first
property from `org-stb--planning-properties' that is set.  Return
nil when the entry carries none of them."
  (catch 'found
    (dolist (property org-stb--planning-properties)
      (let ((value (org-entry-get nil property)))
        (when value
          (throw 'found (cons property value)))))))

(defun org-stb--goto-planning-timestamp (property)
  "Move point onto the timestamp of PROPERTY in the current entry.
Signal `user-error' when the planning line cannot be located."
  (org-back-to-heading t)
  (let ((end (save-excursion (org-end-of-subtree t))))
    (unless (re-search-forward
             (concat "^[ \t]*" property ":[ \t]*"
                     "\\(<[^>\n]+>\\|\\[[^]\n]+\\]\\)")
             end t)
      (user-error "Cannot locate the %s timestamp of this entry" property))
    (goto-char (match-beginning 1))))

(defun org-stb--shift-entry (minutes)
  "Shift the planning timestamp of the entry at point by MINUTES.
The timestamp under point wins; otherwise the SCHEDULED timestamp is
used, falling back to DEADLINE.  Signal `user-error' when the entry
has no planning timestamp at all."
  (if (org-at-timestamp-p 'lax)
      (org-timestamp-change minutes 'minute)
    (let ((planning (or (org-stb--entry-timestamp)
                        (user-error
                         "Entry has no SCHEDULED or DEADLINE timestamp"))))
      (org-stb--goto-planning-timestamp (car planning))
      (org-timestamp-change minutes 'minute))))

(defun org-stb-shift-time (minutes)
  "Shift the current agenda item by MINUTES.
Positive values shift forward, negative values shift backward.
The timestamp the agenda line points at is shifted; when the line
points at the heading instead, SCHEDULED is used and DEADLINE is the
fallback.  Signal `user-error' when the entry has neither."
  (interactive "nShift by minutes: ")
  (let ((marker (or (org-get-at-bol 'org-marker)
                    (user-error "No item at point"))))
    (org-with-point-at marker
      (org-stb--shift-entry minutes))
    (when (derived-mode-p 'org-agenda-mode)
      (org-agenda-redo))))

(defun org-stb-shift-hours (hours)
  "Shift the current agenda item by HOURS.
Positive values shift forward, negative values shift backward."
  (interactive "nShift by hours: ")
  (org-stb-shift-time (* hours 60)))

(defun org-stb-shift-by-increment ()
  "Shift the current agenda item by `org-stb-default-increment'."
  (interactive)
  (org-stb-shift-time org-stb-default-increment))

(defun org-stb-shift-all-forward (minutes)
  "Shift all timestamped items in the current agenda forward by MINUTES.
Items without a SCHEDULED or DEADLINE timestamp are skipped."
  (interactive "nShift all items by minutes: ")
  (save-excursion
    (goto-char (point-min))
    (let ((count 0))
      (while (not (eobp))
        (when (org-get-at-bol 'org-marker)
          (condition-case nil
              (org-with-point-at (org-get-at-bol 'org-marker)
                (org-stb--shift-entry minutes)
                (setq count (1+ count)))
            (error nil)))
        (forward-line 1))
      (org-agenda-redo)
      (message "Shifted %d items by %d minutes" count minutes))))

(defun org-stb-shift-all-hours (hours)
  "Shift all scheduled items in the current agenda by HOURS."
  (interactive "nShift all items by hours: ")
  (org-stb-shift-all-forward (* hours 60)))

;;; Interactive Commands

(defun org-stb-shift-1-hour ()
  "Shift current item forward by 1 hour."
  (interactive)
  (org-stb-shift-hours 1))

(defun org-stb-shift-30-min ()
  "Shift current item forward by 30 minutes."
  (interactive)
  (org-stb-shift-time 30))

(defun org-stb-shift-back-1-hour ()
  "Shift current item backward by 1 hour."
  (interactive)
  (org-stb-shift-hours -1))

(defun org-stb-shift-back-30-min ()
  "Shift current item backward by 30 minutes."
  (interactive)
  (org-stb-shift-time -30))

;;; Minor Mode

(defvar org-stb-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c s h") #'org-stb-shift-1-hour)
    (define-key map (kbd "C-c s H") #'org-stb-shift-back-1-hour)
    (define-key map (kbd "C-c s m") #'org-stb-shift-30-min)
    (define-key map (kbd "C-c s M") #'org-stb-shift-back-30-min)
    (define-key map (kbd "C-c s a") #'org-stb-shift-all-hours)
    (define-key map (kbd "C-c s i") #'org-stb-shift-by-increment)
    map)
  "Keymap for `org-stb-mode'.")

;;;###autoload
(define-minor-mode org-stb-mode
  "Minor mode for simple time balancing in org-agenda."
  :lighter " STB"
  :keymap org-stb-mode-map
  :group 'org-stb)

;;;###autoload
(defun org-stb-setup ()
  "Set up org-stb for use with org-agenda."
  (add-hook 'org-agenda-mode-hook #'org-stb-mode))

(provide 'org-stb)
;;; org-stb.el ends here
