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

(defvar zen-mode-is-active-p nil "If zen mode is currently active or not.")
(defvar zen-mode-previous-state nil
  "The state of features to be disabled in `zen-mode', before entering `zen-mode'.")

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
    ))




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
   ))


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
      (zen-frame-mode state)))))



(defun zen-frame-mode (state)
  "STATE set fullscreen."
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
      (setq f (cdr f)))))


(defun zen-mode-hard-unzen ()
  "Hard reset."
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; zen2 will use emacs custom themes
;; the theme code is not reliable yet
;; the old and new zen coexist for the time being

(defvar zen-state nil
  "Current zen state.  nil means no zen.  other states correspond to a theme.")



(defun zen-set-fullscreen (name state)
  "Customize setter for fullscreen.  NAME and STATE from customize."
  (message "zen-set-fullscreen :>>%s<<" state)
  (setq zen-fullscreen-mode state)
  (cond
   ;;fullscreen seems to be quirky in some emacsen, this is a feeble workaround
   (state   (set-frame-parameter nil 'fullscreen 'fullboth))
    (t          (set-frame-parameter nil 'fullscreen 'fullboth-bug)
          (set-frame-parameter nil 'fullscreen 'nil))))

(defcustom zen-fullscreen-mode
  nil "Make frame fullscreen."
  :group 'zen-mode
  :set 'zen-set-fullscreen)

(defcustom zen-encumber-file "/etc/polipo/forbidden/zen-forbidden"
  "File to store encumberings.  needs to be writable."
  :group 'zen-mode
  :type '(string))


(defun  zen-set-encumber-urls (name encumber)
  "Customize setter for encumber urls.  NAME and ENCUMBER from customize."
  (message "encumber urls %s" encumber)
  (setq zen-encumbered-urls encumber)
  (zen-make-encumber-file)
  (zen-polipo-reload))

(defun zen-make-encumber-file ()
  "Make the file with encumbered urls for Polipo."
  (with-temp-file zen-encumber-file
    (insert (mapconcat (lambda (x) x) zen-encumbered-urls "\n"))))


(defcustom zen-polipo-reload-command "curl -m 15 -d 'init-forbidden=Read%20forbidden%20file' http://localhost:8123/polipo/status?"
  "Command for reloading polipo forbidden file."
  :group 'zen-mode)

(defun zen-polipo-reload ()
  "Signal reload to polipo."
  ;;http://localhost:8123/polipo/status?
  ;;  post: init-forbidden Read forbidden file
  ;; there isnt any convenient POST support in emacs so use curl
  ;;it appears the curl call can hang because polipo can get into a bad state when the network connection changes
  ;;so theres a 15 sec timeout by default
  (call-process-shell-command zen-polipo-reload-command))


(defcustom zen-encumbered-urls nil
  "Make it harder to reach urls so you remember not to go there."
  :group 'zen-mode
  :type '(repeat string)
  :set 'zen-set-encumber-urls)



(defun zen-state-theme (state)
  "Theme corresponding to zen STATE."
  (intern (format "zen-%d" state)))

(defun zen-set-state (new-state)
  "Which zen NEW-STATE to enter."
  (interactive "Nzen:")
  (if (equal 0 new-state) (setq new-state nil))
  ;;nil or 0 means a wordly state.
  ;;other states are themes
  (if zen-state (disable-theme (zen-state-theme zen-state)))
;;  (if new-state (enable-theme (zen-state-theme new-state)))
;;enable-theme doesnt work in the way I expected
;; this works:
  (if new-state (custom-set-variables '(custom-enabled-themes (append (list (zen-state-theme new-state)) custom-enabled-themes ) t)))
  
  (setq zen-state new-state))

(provide 'zen-mode)

;;; zen-mode.el ends here
