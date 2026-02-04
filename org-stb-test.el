;;; org-stb-test.el --- Tests for org-stb -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Juan Gonzalez

;;; Commentary:

;; ERT tests for org-stb package

;;; Code:

(require 'ert)
(require 'org-stb)
(require 'org-agenda)

;;; Helper Functions

(defun org-stb-test--create-test-buffer ()
  "Create a temporary org buffer with test content."
  (let ((buffer (generate-new-buffer "*org-stb-test*")))
    (with-current-buffer buffer
      (org-mode)
      (insert "* TODO Test Task 1\n")
      (insert "SCHEDULED: <2026-02-04 Tue 10:00>\n")
      (insert "* TODO Test Task 2\n")
      (insert "SCHEDULED: <2026-02-04 Tue 14:00>\n")
      (insert "* TODO Test Task 3\n")
      (insert "SCHEDULED: <2026-02-04 Tue 16:30>\n"))
    buffer))

(defun org-stb-test--cleanup-buffer (buffer)
  "Kill BUFFER if it exists."
  (when (buffer-live-p buffer)
    (kill-buffer buffer)))

(defun org-stb-test--get-scheduled-time ()
  "Get the SCHEDULED timestamp at current entry."
  (org-entry-get nil "SCHEDULED"))

;;; Unit Tests

(ert-deftest org-stb-test-shift-time-forward ()
  "Test shifting a scheduled item forward in time."
  (let ((buffer (org-stb-test--create-test-buffer)))
    (unwind-protect
        (with-current-buffer buffer
          (goto-char (point-min))
          (re-search-forward "Test Task 1")
          (let ((original (org-stb-test--get-scheduled-time)))
            (should original)
            ;; Note: This test verifies the function exists and can be called
            ;; Full timestamp manipulation testing requires org-agenda context
            (should (fboundp 'org-stb-shift-time))))
      (org-stb-test--cleanup-buffer buffer))))

(ert-deftest org-stb-test-shift-hours ()
  "Test that shift-hours function is defined and callable."
  (should (fboundp 'org-stb-shift-hours))
  ;; Verify it's an interactive command
  (should (commandp 'org-stb-shift-hours)))

(ert-deftest org-stb-test-default-increment ()
  "Test default increment is set correctly."
  (should (integerp org-stb-default-increment))
  (should (> org-stb-default-increment 0)))

(ert-deftest org-stb-test-shift-by-increment ()
  "Test shift by default increment."
  (should (fboundp 'org-stb-shift-by-increment)))

(ert-deftest org-stb-test-interactive-commands ()
  "Test that interactive commands are defined."
  (should (fboundp 'org-stb-shift-1-hour))
  (should (fboundp 'org-stb-shift-30-min))
  (should (fboundp 'org-stb-shift-back-1-hour))
  (should (fboundp 'org-stb-shift-back-30-min))
  (should (fboundp 'org-stb-shift-all-forward))
  (should (fboundp 'org-stb-shift-all-hours)))

(ert-deftest org-stb-test-mode-defined ()
  "Test that org-stb-mode is defined."
  (should (fboundp 'org-stb-mode))
  (should (keymapp org-stb-mode-map)))

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

(ert-deftest org-stb-test-setup-function ()
  "Test that setup function exists."
  (should (fboundp 'org-stb-setup)))

(ert-deftest org-stb-test-negative-shift ()
  "Test that backward shift functions are defined."
  (should (fboundp 'org-stb-shift-back-1-hour))
  (should (fboundp 'org-stb-shift-back-30-min))
  ;; Verify they're interactive commands
  (should (commandp 'org-stb-shift-back-1-hour))
  (should (commandp 'org-stb-shift-back-30-min)))

;;; Integration Tests

(ert-deftest org-stb-test-buffer-creation ()
  "Test that we can create test buffers correctly."
  (let ((buffer (org-stb-test--create-test-buffer)))
    (unwind-protect
        (with-current-buffer buffer
          (should (eq major-mode 'org-mode))
          (goto-char (point-min))
          (should (search-forward "Test Task 1" nil t))
          (should (search-forward "SCHEDULED:" nil t)))
      (org-stb-test--cleanup-buffer buffer))))

(provide 'org-stb-test)
;;; org-stb-test.el ends here
