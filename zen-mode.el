;;; zen-mode.el --- remove/restore Emacs frame distractions quickly

;;; Copyright (C) 2008,2009,2010,2011 FSF

;;Author: Joakim Verona, joakim@verona.se
;;License: GPL V3 or later

;;; Commentary:
;;  See README.org

;;; History:
;; 
;; 2008.08.17 -- v0.1
;; 2009  -- v.02pre3

;;; Code:

(provide 'zen-mode)

(defvar zen-mode-is-active-p nil "If zen mode is currently active
or not.")
(defvar zen-mode-previous-state nil "The state of features to be
disabled in zen-mode, before entering zen-mode.")

(defgroup zen-mode nil "zen-mode"); :group 'some-apropriate-root-group)

(defcustom zen-mode-what-is-not-zen '(scroll-bar-mode menu-bar-mode tool-bar-mode frame-mode)
  "These Emacs features are not considered Zen.
They will be disabled when entering Zen.  They will be restored
to their previous settings when leaving Zen."
  :group 'zen-mode
  :type
  '(set :tag "zen"
    (const scroll-bar-mode)
    (const menu-bar-mode)
    (const tool-bar-mode)
    (const frame-mode) ;frame-mode is the inverse of fullscreen, for consistency
  )
  )


(defun zen-mode-get-feature-state (feature)
  "An uniform get/set facility for each feature zen handles.
FEATURE is a symbol from 'zen-mode-what-is-not-zen'."
  (cond
   ((eq feature 'scroll-bar-mode)
    scroll-bar-mode)
   ((eq feature 'menu-bar-mode)
    menu-bar-mode)
   ((eq feature 'tool-bar-mode)
    tool-bar-mode)
   ((eq feature 'frame-mode)
    (if (eq 'fullboth (frame-parameter nil 'fullscreen)) nil t))
   ;emacs seems to assume a maximized window is also "fullboth".
   ;zen-mode needs to make a difference between fullscreen and maximized
 )
  )

(defun zen-mode-set-feature-state (feature state)
  "Set zen FEATURE to STATE."
  (let*
      ((modeflag (if state t -1)))
    (cond
     ((eq feature 'scroll-bar-mode)
      (scroll-bar-mode modeflag))
     ((eq feature 'menu-bar-mode)
      (menu-bar-mode modeflag))
     ((eq feature 'tool-bar-mode)
      (tool-bar-mode modeflag))
     ((eq feature 'frame-mode)
      (zen-frame-mode state))
    ))
)

(defun zen-frame-mode (state)
  ;;(message "zen-frame-mode :>>%s<<" state)
  (cond
   ;;fullscreen seems to be quirky in some emacsen, this is a feeble workaround
   (state (set-frame-parameter nil 'fullscreen 'fullboth-bug)
          (set-frame-parameter nil 'fullscreen 'nil))
    (t
            (set-frame-parameter nil 'fullscreen 'fullboth))))


(defun zen-mode-store-state ()
  "Store the state of all features zen is interested in."
  (setq zen-mode-previous-state nil)
  (let
      ((f zen-mode-what-is-not-zen))
    (while f
      (setq zen-mode-previous-state
            (append zen-mode-previous-state
                    (list (list (car f)
                                (zen-mode-get-feature-state (car f))) )))
      (setq f (cdr f))))
  zen-mode-previous-state)

(defun zen-mode-disable-nonzen-features ()
  "Disable all non-zen features."
  (let
      ((f zen-mode-what-is-not-zen))
    (while f
      (zen-mode-set-feature-state (car f) nil)
      (setq f (cdr f)))))

(defun zen-mode-restore-state ()
  "Restore the feature state as before entering zen."
  (let
      ((f zen-mode-previous-state))
    (while f
      (zen-mode-set-feature-state (caar  f) (cadar f))
      (setq f (cdr f))))
  )

(defun zen-mode-hard-unzen ()
  "hard reset"
  (zen-mode-set-feature-state 'scroll-bar-mode t)
  (zen-mode-set-feature-state 'menu-bar-mode t)
  (zen-mode-set-feature-state 'tool-bar-mode t)
  (zen-mode-set-feature-state 'frame-mode t))

     

(defun zen-mode ()
  "Toggle Zen mode."
  (interactive)
  ;(message "state: %s" zen-mode-previous-state)
  
  (if zen-mode-is-active-p
        (progn;deactivate zen
          (message "Leaving Zen")
          (setq zen-mode-is-active-p nil)
          (zen-mode-restore-state)
          )
      (progn;activate zen
        (message "Entering Zen")
        (setq zen-mode-is-active-p t)
        (zen-mode-store-state)
        (zen-mode-disable-nonzen-features))))

(provide 'zen-mode)

;;; zen-mode.el ends here
