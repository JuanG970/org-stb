;;; examples.el --- Usage examples for org-stb -*- lexical-binding: t; -*-

;;; Commentary:

;; This file contains practical examples of using org-stb.

;;; Code:

(require 'org-stb)

;;; Example 1: Basic single-item shifts

;; Move current agenda item forward by 1 hour
;; (With cursor on an agenda item)
;; M-x org-stb-shift-1-hour
;; or C-c s h

;; Move current item backward by 1 hour
;; M-x org-stb-shift-back-1-hour
;; or C-c s H

;; Move current item forward by 30 minutes
;; M-x org-stb-shift-30-min
;; or C-c s m

;;; Example 2: Custom time shifts

;; Shift by 90 minutes forward
;; M-x org-stb-shift-time RET 90

;; Shift by 2.5 hours forward (150 minutes)
;; M-x org-stb-shift-time RET 150

;; Shift backward by 45 minutes
;; M-x org-stb-shift-time RET -45

;;; Example 3: Batch operations

;; Shift all items in current agenda forward by 3 hours
;; M-x org-stb-shift-all-hours RET 3

;; Shift all items backward by 2 hours
;; M-x org-stb-shift-all-hours RET -2

;;; Example 4: Custom configurations

;; Set default increment to 15 minutes
;; (setq org-stb-default-increment 15)

;; Then use:
;; M-x org-stb-shift-by-increment
;; or C-c s i

;;; Example 5: Programmatic usage

(defun my/reschedule-morning-meeting ()
  "Move morning meeting 30 minutes later."
  (interactive)
  (save-excursion
    (org-agenda-goto)
    (org-stb-shift-time 30)))

(defun my/push-afternoon-back ()
  "Push all afternoon items back by 1 hour."
  (interactive)
  (org-stb-shift-all-hours 1))

;;; Example 6: Integration with custom agenda views

;; In your config.el
;; (after! org-agenda
;;   (org-stb-setup)  ; Enable in all agenda buffers
;;   
;;   ;; Add custom key bindings
;;   (map! :map org-agenda-mode-map
;;         :n "gh" #'org-stb-shift-1-hour
;;         :n "gH" #'org-stb-shift-back-1-hour
;;         :n "gm" #'org-stb-shift-30-min
;;         :n "gM" #'org-stb-shift-back-30-min))

;;; Example 7: Workflow scenarios

;; Scenario: Meeting ran over, need to push everything back
;; 1. Open agenda: SPC o a a
;; 2. Navigate to first affected item
;; 3. C-c s a (org-stb-shift-all-hours)
;; 4. Enter: 1 (shift all by 1 hour)

;; Scenario: Quick 30-min adjustment for one task
;; 1. In agenda, navigate to task
;; 2. C-c s m (shift forward 30 min)
;; Or: C-c s M (shift backward 30 min)

;; Scenario: Fine-tuning with custom increment
;; 1. Set increment: (setq org-stb-default-increment 15)
;; 2. Navigate to task
;; 3. C-c s i (multiple times as needed)

(provide 'examples)
;;; examples.el ends here
