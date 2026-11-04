;;; org-stb-test.el --- Tests for org-stb -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Juan Gonzalez

;;; Commentary:

;; ERT tests for org-stb package

;;; Code:

(require 'ert)
(require 'cl-lib)
(require 'org-stb)
(require 'org-agenda)

;;; Fixtures

(defun org-stb-test--write-fixture (file)
  "Write the three-entry agenda fixture to FILE."
  (with-temp-file file
    (insert "* TODO Task A\nSCHEDULED: <2026-02-04 Wed 10:00>\n"
            "* TODO Task B\nSCHEDULED: <2026-02-04 Wed 14:00>\n"
            "* TODO Task C\nSCHEDULED: <2026-02-04 Wed 16:30>\n")))

(defun org-stb-test--cleanup (file)
  "Kill fixture buffers and delete FILE."
  (let ((agenda (get-buffer "*Org Agenda*"))
        (org-buffer (get-file-buffer file)))
    (when (buffer-live-p agenda) (kill-buffer agenda))
    (when (buffer-live-p org-buffer) (kill-buffer org-buffer))
    (when (file-exists-p file) (delete-file file))))

(defmacro org-stb-test--with-agenda (&rest body)
  "Run BODY in a fresh agenda buffer built from a temporary org file.
The fixture path is available as `org-stb-test--file'."
  (declare (indent 0) (debug t))
  `(let* ((org-stb-test--file (make-temp-file "org-stb-test-" nil ".org"))
          (org-agenda-files (list org-stb-test--file))
          (org-agenda-span 1))
     (unwind-protect
         (progn
           (org-stb-test--write-fixture org-stb-test--file)
           (org-agenda-list nil "2026-02-04" 1)
           (with-current-buffer "*Org Agenda*"
             (goto-char (point-min))
             ,@body))
       (org-stb-test--cleanup org-stb-test--file))))

(defun org-stb-test--goto-agenda-line (heading)
  "Move to the agenda line for HEADING in the current agenda buffer."
  (goto-char (point-min))
  (unless (re-search-forward (concat "TODO " (regexp-quote heading) "$") nil t)
    (error "No agenda line for %s" heading))
  (beginning-of-line)
  (unless (org-get-at-bol 'org-marker)
    (error "Agenda line for %s has no org-marker" heading)))

(defun org-stb-test--get-scheduled-time ()
  "Get the SCHEDULED timestamp at current entry."
  (org-entry-get nil "SCHEDULED"))

(defun org-stb-test--entry-text (file heading)
  "Return the heading and SCHEDULED lines for HEADING in FILE."
  (with-current-buffer (find-file-noselect file)
    (goto-char (point-min))
    (unless (re-search-forward
             (concat "^\\* TODO " (regexp-quote heading) "$") nil t)
      (error "Heading %s not found in %s" heading file))
    (buffer-substring-no-properties
     (line-beginning-position)
     (progn (forward-line 2) (point)))))

;;; Behavioral tests

(ert-deftest org-stb-test-shift-1-hour-forward ()
  "Shifting forward one hour updates the scheduled timestamp."
  (org-stb-test--with-agenda
    (org-stb-test--goto-agenda-line "Task A")
    (org-stb-shift-1-hour)
    (should (equal (org-stb-test--entry-text org-stb-test--file "Task A")
                   "* TODO Task A\nSCHEDULED: <2026-02-04 Wed 11:00>\n"))
    (should (equal (org-stb-test--entry-text org-stb-test--file "Task B")
                   "* TODO Task B\nSCHEDULED: <2026-02-04 Wed 14:00>\n"))))

(ert-deftest org-stb-test-shift-back-1-hour ()
  "Shifting backward one hour updates the scheduled timestamp."
  (org-stb-test--with-agenda
    (org-stb-test--goto-agenda-line "Task B")
    (org-stb-shift-back-1-hour)
    (should (equal (org-stb-test--entry-text org-stb-test--file "Task B")
                   "* TODO Task B\nSCHEDULED: <2026-02-04 Wed 13:00>\n"))))

(ert-deftest org-stb-test-shift-30-min-on-scheduled-line ()
  "Shifting a scheduled agenda line by 30 minutes updates it."
  (org-stb-test--with-agenda
    (org-stb-test--goto-agenda-line "Task C")
    (org-stb-shift-30-min)
    (should (equal (org-stb-test--entry-text org-stb-test--file "Task C")
                   "* TODO Task C\nSCHEDULED: <2026-02-04 Wed 17:00>\n"))))

(ert-deftest org-stb-test-shift-all-forward ()
  "Batch shifting moves every entry and reports the entry count."
  (org-stb-test--with-agenda
    (let (messages)
      (cl-letf (((symbol-function 'message)
                 (lambda (fmt &rest args)
                   (push (apply #'format fmt args) messages))))
        (org-stb-shift-all-forward 30))
      (should (member "Shifted 3 items by 30 minutes" messages)))
    (should (equal (org-stb-test--entry-text org-stb-test--file "Task A")
                   "* TODO Task A\nSCHEDULED: <2026-02-04 Wed 10:30>\n"))
    (should (equal (org-stb-test--entry-text org-stb-test--file "Task B")
                   "* TODO Task B\nSCHEDULED: <2026-02-04 Wed 14:30>\n"))
    (should (equal (org-stb-test--entry-text org-stb-test--file "Task C")
                   "* TODO Task C\nSCHEDULED: <2026-02-04 Wed 17:00>\n"))))

(ert-deftest org-stb-test-shift-outside-agenda-signals-user-error ()
  "Calling the shifter outside an agenda line signals `user-error'."
  (let ((file (make-temp-file "org-stb-test-" nil ".org")))
    (unwind-protect
        (progn
          (with-temp-file file
            (insert "* TODO Task A\nSCHEDULED: <2026-02-04 Wed 10:00>\n"))
          (with-current-buffer (find-file-noselect file)
            (goto-char (point-min))
            (should-error (org-stb-shift-time 30) :type 'user-error)
            (should (equal (org-stb-test--get-scheduled-time)
                           "<2026-02-04 Wed 10:00>"))))
      (org-stb-test--cleanup file))))

;;; Unit Tests

(ert-deftest org-stb-test-keybindings ()
  "Test that keybindings are set up correctly."
  (should (keymapp org-stb-mode-map))
  (should (equal (lookup-key org-stb-mode-map (kbd "C-c s h"))
                 #'org-stb-shift-1-hour))
  (should (equal (lookup-key org-stb-mode-map (kbd "C-c s H"))
                 #'org-stb-shift-back-1-hour))
  (should (equal (lookup-key org-stb-mode-map (kbd "C-c s m"))
                 #'org-stb-shift-30-min))
  (should (equal (lookup-key org-stb-mode-map (kbd "C-c s M"))
                 #'org-stb-shift-back-30-min))
  (should (equal (lookup-key org-stb-mode-map (kbd "C-c s a"))
                 #'org-stb-shift-all-hours))
  (should (equal (lookup-key org-stb-mode-map (kbd "C-c s i"))
                 #'org-stb-shift-by-increment)))

(provide 'org-stb-test)
;;; org-stb-test.el ends here
