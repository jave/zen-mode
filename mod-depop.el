;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; modeline-depopulator
;;a  little hack to see info in msg area or a popup, rather than
;; have every modeline being poluted with information that is really
;; global


;; - battery status
;; - time
;; - network status

;;TODO
;; should really be a part of zen-mode.

;; erc channels should be shown with colors


(require 'battery)
(require 'timeclock)
(require 'popup)

(defun mod-depop-info-string ()
  ( erc-modified-channels-update)
  (format "%s\n%s\n%s\n%s\n%s"
          (format-time-string "%H:%M %Y-%m-%d" (current-time))
          (battery-format battery-echo-area-format (funcall
                                                    battery-status-function))
          (timeclock-status-string)
          (shell-command-to-string "nmcli   dev")
          (erc-modified-channels-display)
          
          ))


(global-set-key [f5] '(lambda () (interactive) (popup-tip (mod-depop-info-string))))
