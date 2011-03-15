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
;; 2011  -- v2pre1

;;; Code:

(provide 'zen-mode)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; zen v2 uses emacs custom themes which is much cleverer than the old method
;; but also more complex to install because you need to copy the zen themes to ~/.emacs.d

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
  "File to store url encumberings.
Needs to be writable and Polipo needs to be configured to read it."
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
