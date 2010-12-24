;;; zen-mode.el --- remove/restore Emacs frame distractions quickly

;;; Copyright (C) 2008,2009 Joakim Verona

;;Author: Joakim Verona, joakim@verona.se
;;License: GPL V3 or later

;;; Commentary:
;; 
;;zen-mode is Emacs in fullscreen without toolbar and menubar
;;the function toggles between previous state of features and zen
;;
;;Please see BUG list below if Zen doesnt behave as expected.
;;
;;I bind zen-mode to f11 like this:
;;;(global-set-key [f11] 'zen-mode)
;;
;;TODO:
;;
;;- BUG: Currently Zen mode cant see the difference between a maximized
;; frame and a fullscreen frame. This is because of a limitation in
;; Emacs, which will be fixed future-ish. The end result is that
;; currently Zen will probably not do what you expect if you enter zen
;; while in a maximized frame. 
;;
;; - BUG: There are some problems in the Compiz WM, (and maybe other WM:s)
;; regarding fullscreen: When selecting another workspace temporarily
;; and going back, Emacs does not cover the wm panels as it should.
;; This can be resolved with alt-tab a bit, but its annoying.  In
;; Metacity it works well. Maybe Zen could learn to work around these
;; WM:s
;;
;;- Improvement: Zen-master mode, like writeroom mode. (c-u m-x
;; zen-mode), which isn't customizable, it just turns all distractions
;; off, including minibuffer.
;;
;;- Improvement: Levels of Zen-ness. Quickly enter zen with different
;; predetermined settings
;;
;;- Improvement: Optionaly advice some modes like ERC so as not to
;;  interrupt while in Zen, also dont Gnus while in Zen. You are
;;  supposed to concentrate :)
;;
;;- Improvement: Optional procrastination inhibitor. Enter Zen and dont leave until
;; youv'e actually produced someting useful. For instance, 15 minutes
;; must pass and some useful buffer must grow by a number of bytes
;; before you can begin wasting time again.
;;
;; BUG: doesnt remember previous window size and position always

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
    (if (eq 'fullboth (frame-parameter nil 'fullboth)) nil t))
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
