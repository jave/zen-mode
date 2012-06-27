;;; zen-mode.el --- remove/restore Emacs distractions quickly

;;; Copyright (C) 2008,2009,2010,2011,2012 FSF

;;Author: Joakim Verona, joakim@verona.se
;;License: GPL V3 or later

;;; Commentary:
;;  See README.org

;;; History:
;; 
;; 2008.08.17 -- v0.1
;; 2009  -- v.02pre3
;; 2011  -- v2pre1
;; 20120627 -- 20120627
;;; Code:

;;??
;;;###autoload (add-to-list 'custom-theme-load-path load-file-name)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; zen v2 uses emacs custom themes which is much cleverer than the old method
;; but also more complex to install because you need to copy the zen themes to ~/.emacs.d

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun zen-state () 
  "Current zen state.  0 means no zen.  other states correspond to a set of themes."
  (length (zen-active-states))
  )


;;todo support stackable zen states, use custom-enabled-themes for state 
(defun zen-active-states ()
  "return a list of curretly active zen states."
  (delq nil (mapcar (lambda (theme) (if (memq theme custom-enabled-themes) theme nil)) zen-states)))

(defcustom zen-states '(zen-1 zen-2 zen-3)
  "the zen states.
each state is a theme.
the list is ordered, so zen-3 is adden on top of zen-2 and zen-1.")


(defun zen-state-themes (state)
  "Themes corresponding to zen STATE."
  (delq nil (subseq zen-states 0 state))
  )

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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

(defcustom zen-sound-of-one-hand-clapping
  (lambda () (emms-play-file "/home/joakim/build_myprojs/sbagen/examples/jave/ts-brain-delta-nopink.sbg"))
  "What does one hand clapping sound like?
Play this sound to enter furhur into Zen."
  :group 'zen-mode
  :type 'function ;;maybe hoox instead?
  :set (lambda (name val) (eval val))
  )

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
  "Command for reloading Polipo forbidden file."
  :group 'zen-mode)

(defun zen-polipo-reload ()
  "Signal reload to Polipo."
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

(defun zen-set-state (new-state)
  "Which zen NEW-STATE to enter."
  (interactive "Nzen:")
  (if (> 0 new-state) (setq new-state 0))
  (if (>= new-state (length zen-states))  (setq new-state (length zen-states))) ;;TODO
  (message "Now entering Zen %d" new-state)  
  ;; 0 means a wordly state.
  ;;first remove the old states
  (let ((non-zen-themes  custom-enabled-themes))
    (mapc (lambda (el) (setq non-zen-themes (delq el non-zen-themes))) zen-states)
    ;;enable-theme doesnt work in the way I expected

    ;; this works. somewhat.
    (custom-set-variables (list 'custom-enabled-themes
                                (list 'quote (append (zen-state-themes new-state) non-zen-themes )) nil)))

  )

(defun zen-more ()
  "More Zen. You can do it!"
  (interactive)
  (zen-set-state (+ 1 ( zen-state))))


(defun zen-less ()
  "Less Zen. The spirit is willing but the flesh is weak."
  (interactive)
  (zen-set-state (-  ( zen-state) 1)))

;;keys
;;TODO the proper way
(defun zen-keys ()
  (global-set-key (kbd "<f11> <f11>") 'zen-set-state)
  (global-set-key (kbd "<f11> m") 'zen-more)
  (global-set-key (kbd "<f11> l") 'zen-less)
  (global-set-key (kbd "<f11> p") 'zen-pommodoro)
  )

(defun zen-neurosky-filter (proc string)
  (when (buffer-live-p (process-buffer proc))
    (with-current-buffer (process-buffer proc)
      (let ((moving (= (point) (process-mark proc)))
            (attention (string-to-number string)))
        (save-excursion
          ;;  Insert the text, advancing the process marker.
          (goto-char (process-mark proc))
          (insert (format "%d:%s \n" attention (make-string  attention 35)))

          (set-marker (process-mark proc) (point)))
        (if moving (goto-char (process-mark proc)))))))



;;interface emacs to the neurosky mindset.
;;the "synapse" tool is started first, which is a BT->REST adapter
;; its a bit shaky still. you need to run it twice, 1st to start the adapter, 2nd to start the emacs listener
(defun zen-neurosky ()
  (interactive)
  (let* ((synapse-proc (unless (get-process "zen-synapse")
                         (start-process-shell-command "zen-synapse" "*zen-synapse*" "/usr/bin/env python /usr/lib/python2.7/site-packages/synapse-gui.py")))
         (neurosky-proc
          (start-process-shell-command "zen-neurosky" "*zen-neurosky*" "unbuffer -p nc  localhost 13854 |unbuffer -p  mac2unix |unbuffer -p grep attention |sed 's/.* \\([0-9]*\\)}}.*/\\1/g'"))
         

         )
    (set-process-filter neurosky-proc 'zen-neurosky-filter)))

(defun zen-pommodoro ()
  (interactive)
  "enter your desired zen state for pommodoro.
uses org-timer if you have it."


  
  ;;first enter zen TODO defcustom or something
  (zen-set-state 2)
  
  ;;if we have org, we can use it

  ;;change org timmer settings only for the duration of the pommodoro,
  (cond  ((require 'org-timer nil t)
          (let ( (org-timer-default-timer 25)
                 (org-clock-in-hook org-clock-in-hook))
            (add-hook 'org-clock-in-hook '(lambda ()
                                            (if (not org-timer-current-timer) 
                                                (org-timer-set-timer '(16)))))
            (org-clock-in)))
         (t (message "you dont seem to have org-timer, so I dont know how to time your pommodoro yet."))))
;;TODO when using the org timer, and not on org item when starting, theres an error, which is annoying

;;;###autoload
(when (boundp 'custom-theme-load-path)
  (add-to-list 'custom-theme-load-path
               (file-name-as-directory (file-name-directory load-file-name))))

(provide 'zen-mode)

;;; zen-mode.el ends here
