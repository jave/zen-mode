;; panel.el, or now.el. whatever suits.

;;prototype.
;; - there should be inheritance for locations,
;; so, away-af inherits away-wan. so, probably eieio

;;stuff that i want to set:
;; - current printer
;; - current smtp(also during error conditions, such as home network down)
;; - wifi or wan or lan
;; - vpn
;; - bluetooth headset or normal

;; stuff that affects settings:
;; - location (work, home, on train, etc)


(defun now-tablet ()
;;now we are a tablet
  (interactive)
  ;;todo more or less zen 1, fullscreen, menu, buttons
  )

(defun now-desktop ()
;;now we are desktop as opposed to tablet
  ;;todo go back to the zen mode befor we enterd tablet
  (interactive)
  )


;;restart dovecot because bafflingly it doesnt work after reboot:
(defun now--dovecot-restart ()
  (interactive)
  (shell-command "sudo systemctl restart dovecot.service"))

;toggle vpn:
;(shell-command "systemctl status openvpn@verona.service")
(defmacro now-cmd-define (str1 str2)
  )
(defun now--verona-vpn (start)
  (interactive "p")
  (if (eq 1 start) 
      (shell-command "sudo systemctl start openvpn@verona.service")
    (shell-command "sudo systemctl stop openvpn@verona.service")))


(defun now-check-os-updates ()
  (interactive)
  (shell-command "sudo yum --assumeno upgrade"))

(defun now--wan (start)
  (interactive "p")
  (if (eq 1 start) 
      (shell-command "nmcli con up id 'internet.telenor.se'")
    (shell-command "nmcli con down id 'internet.telenor.se'")))

(defun now--wifi (start)
  (interactive "p")
  (if (eq 1 start)
      (shell-command "nmcli nm wifi on")
    (shell-command "nmcli nm wifi off")
      ()))


(defun now-at-af ()
  (interactive)
  (message "you are at af")
  (now--wan 1)
  (now--wifi 0)
  (now--verona-vpn 1))

(defun now-at-home-wifi ()
  (interactive)
  (message "you are at home using wifi")
  (now--wan 0)
  (now--verona-vpn 0)
  (now--wifi 1))

(defun now-at-away-wifi ()
  (interactive)
  (message "you are at away using wifi")
  (now--wan 0)
  (now--verona-vpn 1)
  (now--wifi 1))

(defun now-at-away-lan ()
  (interactive)
  (message "you are at away using lan")
  (now--wan 0)
  (now--verona-vpn 1)
  (now--wifi 0))

(defun now-offline ()
  (interactive)
  (now--wan 0)
  (now--verona-vpn 0)
  (now--wifi 0)
  ;;now do stuff like:
  ;; - disconnect gnus
  ;; - disconnect erc
  )


(defun now--test (start)
  (interactive "p")
  (message "start:%s" start))
;network:
;- when using telenor:
;
;(shell-command "nmcli con up id 'Telenor Mobilt Internet'")

;- when on wifi
;(shell-command "nmcli nm wifi on")

;where to route audio(bt, spkrs), (because the main pulseaudio gui is inconvenient)

(provide 'now)
