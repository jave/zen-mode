;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; modeline-depopulator is a little hack to see info in msg area or a
;;popup or a separate frame, rather than have every modeline being
;;poluted with information that is really global


;; - battery status
;; - time
;; - network status

;; the are several attempts at the same idea now here.
;; currently i like the "temporary frame layout" idea better than the "popup window"
;; idea.



(require 'battery)
(require 'timeclock)
(require 'popup)
(require 'sauron)

(defun mod-depop-info-string ()
  ( erc-modified-channels-update)
  (format "%s\n%s\n%s\n%s\n%s"
          ;;i just took some random faces with list-faces-display to create angry fruit salad
          (propertize           (format-time-string "%H:%M   %Y-%m-%d" (current-time))
                                'face 'Info-title-1-face)
          (if battery-status-function (propertize (battery-format battery-echo-area-format (funcall
                                                                                            battery-status-function))
                                                  'face 'abook-summary-modified-flag))
          (propertize  (shell-command-to-string "nmcli   dev")
                       'face 'change-log-email)
          (timeclock-status-string)
          
          (erc-modified-channels-display)
          
          ))

(defun mod-depop-popup ()
  (interactive) (popup-tip (mod-depop-info-string)))

(global-set-key [f5] 'mod-depop-popup)

;;this is now really the global info idea, not sauron specifically
(setq mod-depop-toggle-current-register 0 )
(defun mod-depop-toggle-view ()
  "look at the mod-depop buffer, then come back"
  (interactive)
  (if  (= 1 mod-depop-toggle-current-register)
      (progn
        ;;1st i tried "winner" but it wasnt predictable.
        ;;then i try saving window conf to register
        
        ;;(winner-undo)
        (setq mod-depop-toggle-current-register 0 )
        (jump-to-register ?9)
        )
    (progn
      ;;TODO how do i make the buffer NOT pop up in last visited ido buffers
      ;;(winner-remember)
      (setq mod-depop-toggle-current-register 1)

      (window-configuration-to-register ?9)
      (switch-to-buffer "*Sauron*" t)
      (delete-other-windows)
      ;;hey, i want to look at other things as well!
      (split-window-below)
      ;;it would be nice to incorporate 'display-time-world as well!
      (require 'time)

      (cond
       ;;experiment with either a world clock or mod-depop-info-string here
       (nil 
        (switch-to-buffer (get-buffer-create display-time-world-buffer-name) t)
        (display-time-world))
       (t
        (switch-to-buffer (get-buffer-create "*mod-depop*") t)
        (erase-buffer)
        (insert (mod-depop-info-string))
        ))
      
      (split-window-right)
      ;;it would also be nice to see connection status here. (i have that somewhere...)
      
      (switch-to-buffer "*Org Agenda*" t)
      (goto-char (point-min))
      (search-forward "====")
      (recenter-top-bottom 0)
      ;;hey, this is pretty dumb. I should add a new window conf register and switch between them.
      ;;now im just hoping the sauron buffer is current when i toggle
      ;;check if (get-register ?8) is nil, if so build conf, and store it. then toggle depending on if we are in that state or not
      (other-window 2)
      ))
  )
;;I never use the F1 help binding, so I use it for mod depop instead
(global-set-key [f1] 'mod-depop-toggle-view)

;;;;; global info
;; (defun jv-global-info ()
;;   (interactive)
  
;;   (display-buffer
;;    (get-buffer-create "*global-mode-line*")
;;    '((use-side-window bottom 0)
;;      (dedicate . t)
;;      (pop-up-window-set-height  . 1)))
  
;;   (set-window-parameter (current-window) window-other-window t))
