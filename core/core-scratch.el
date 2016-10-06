;;; core-scratch.el

(setq initial-major-mode 'doom-mode
      initial-scratch-message "\n  Loading..."
      inhibit-startup-screen t
      ;; shuts up emacs at startup
      inhibit-startup-echo-area-message user-login-name)

(defvar doom-buffer nil
  "The global and persistent scratch buffer for doom.")
(defvar doom-buffer-name " *doom*"
  "The name of the doom scratch buffer.")
(defvar doom-buffer-edited nil
  "If non-nil, the scratch buffer has been edited.")

(define-derived-mode doom-mode fundamental-mode
  (concat "v" doom-version)
  "Major mode for special DOOM buffers.")

;; Don't kill the scratch buffer
(add-hook! 'kill-buffer-query-functions
  (not (eq doom-buffer (current-buffer))))

(add-hook 'emacs-startup-hook 'doom--reload-scratch-buffer)

;; Don't rename these buffers. That could cause problems.
(after! uniquify
  (setq uniquify-ignore-buffers-re (regexp-quote doom-buffer-name)))

(defun doom*scratch-split-hack (&rest _)
  "Removes the window margins before attempting a vertical-split on the scratch
buffer. Without this, it would refuse to split, saying 'too small to split'."
  (when (eq (current-buffer) doom-buffer)
    (set-window-margins nil 0 0)))
(advice-add 'split-window :before 'doom*scratch-split-hack)

(defun doom|mode-erase-on-insert ()
  "Erase the buffer and prepare it to be used like a normal buffer."
  (erase-buffer)
  (set-window-margins (get-buffer-window doom-buffer) 0 0)
  (setq doom-buffer-edited t
        mode-line-format (doom-modeline)
        doom--scratch-width nil)
  (remove-hook 'evil-insert-state-entry-hook 'doom|mode-erase-on-insert t))

(defun doom-reload-scratch-buffer (&optional dir)
  "Update the DOOM scratch buffer (or create it, if it doesn't exist)."
  (when (and (get-buffer-window-list doom-buffer nil t)
             (or (not doom-buffer-edited) dir)
             (not (minibuffer-window-active-p (minibuffer-window))))
    (doom--reload-scratch-buffer dir)))

(defvar doom--scratch-width nil)
(defvar doom--scratch-height nil)
(defun doom--reload-scratch-buffer (&optional dir)
  ;; Rename the old scratch buffer, if it exists.
  (let ((old-scratch (get-buffer "*scratch*")))
    (when old-scratch
      (with-current-buffer old-scratch
        (rename-buffer doom-buffer-name)
        (setq doom-buffer old-scratch))))
  ;; Ensure the doom buffer is alive!
  (unless (buffer-live-p doom-buffer)
    (setq doom-buffer nil))
  (unless doom-buffer
    (setq doom-buffer (get-buffer-create doom-buffer-name)))
  ;; Fill it with the splash screen content
  (with-current-buffer doom-buffer
    (doom-mode)
    (add-hook 'evil-insert-state-entry-hook 'doom|mode-erase-on-insert nil t)
    (add-hook 'after-change-major-mode-hook 'doom|mode-erase-on-insert nil t)
    (setq doom-buffer-edited nil)
    (let ((width 78)
          updates-p height)
      (mapc (lambda (window)
              (set-window-margins window 0 0)
              (let ((pad (max 0 (- (truncate (/ (window-width window) 2)) (truncate (/ width 2))))))
                (set-window-margins window pad pad)
                (setq height (max 0
                                  (min (or height 9999)
                                       (- (truncate (/ (window-height window) 2)) 12))))))
            (get-buffer-window-list doom-buffer nil t))
      (when (or (not doom--scratch-width)
                (not doom--scratch-height)
                (/= doom--scratch-width width)
                (/= doom--scratch-height height))
        (erase-buffer)
        (insert (propertize
                 (concat
                  (make-string (if height (max 0 height) 0) ?\n)
                  "=================     ===============     ===============   ========  ========\n"
                  "\\\\ . . . . . . .\\\\   //. . . . . . .\\\\   //. . . . . . .\\\\  \\\\. . .\\\\// . . //\n"
                  "||. . ._____. . .|| ||. . ._____. . .|| ||. . ._____. . .|| || . . .\\/ . . .||\n"
                  "|| . .||   ||. . || || . .||   ||. . || || . .||   ||. . || ||. . . . . . . ||\n"
                  "||. . ||   || . .|| ||. . ||   || . .|| ||. . ||   || . .|| || . | . . . . .||\n"
                  "|| . .||   ||. _-|| ||-_ .||   ||. . || || . .||   ||. _-|| ||-_.|\\ . . . . ||\n"
                  "||. . ||   ||-'  || ||  `-||   || . .|| ||. . ||   ||-'  || ||  `|\\_ . .|. .||\n"
                  "|| . _||   ||    || ||    ||   ||_ . || || . _||   ||    || ||   |\\ `-_/| . ||\n"
                  "||_-' ||  .|/    || ||    \\|.  || `-_|| ||_-' ||  .|/    || ||   | \\  / |-_.||\n"
                  "||    ||_-'      || ||      `-_||    || ||    ||_-'      || ||   | \\  / |  `||\n"
                  "||    `'         || ||         `'    || ||    `'         || ||   | \\  / |   ||\n"
                  "||            .===' `===.         .==='.`===.         .===' /==. |  \\/  |   ||\n"
                  "||         .=='   \\_|-_ `===. .==='   _|_   `===. .===' _-|/   `==  \\/  |   ||\n"
                  "||      .=='    _-'    `-_  `='    _-'   `-_    `='  _-'   `-_  /|  \\/  |   ||\n"
                  "||   .=='    _-'          '-__\\._-'         '-_./__-'         `' |. /|  |   ||\n"
                  "||.=='    _-'                                                     `' |  /==.||\n"
                  "=='    _-'                         E M A C S                          \\/   `==\n"
                  "\\   _-'                                                              `-_   /\n"
                  " `''                                                                     ``'")
                 'face 'font-lock-comment-face)
                "\n\n"
                (s-center 73 (doom--scratch-menu))
                "\n\n\n"
                (propertize (concat (s-center 78 "~  ~")
                                    "\n"
                                    (s-center 78 (format "Loaded %d packages in %s"
                                                         (length doom-packages) (emacs-init-time))))
                            'face 'font-lock-comment-face))
        (setq doom--scratch-width width
              doom--scratch-height height)))
    (goto-char 1521)
    (when dir (setq default-directory dir))
    (setq mode-line-format (doom-modeline 'scratch))
    ;; Readjust the scratch buffer if it is visible, when the frame changes.
    (add-hook 'window-configuration-change-hook 'doom-reload-scratch-buffer)))

(defun doom--scratch-menu ()
  (let ((all-the-icons-scale-factor 1.3)
        (all-the-icons-default-adjust -0.05)
        (start (point)) end)
    (with-temp-buffer
      (insert-text-button
       (concat (all-the-icons-octicon
                "mark-github"
                :face 'font-lock-keyword-face)
               (propertize " Homepage" 'face 'font-lock-keyword-face))
       'action '(lambda (_) (browse-url "https://github.com/hlissner/.emacs.d"))
       'follow-link t)

      (insert "    ")

      (insert-text-button
       (concat (all-the-icons-octicon
                "file-text"
                :face 'font-lock-keyword-face)
               (propertize " Recent files" 'face 'font-lock-keyword-face))
       'action '(lambda (_) (call-interactively 'counsel-recentf))
       'follow-link t)

      (insert "   ")

      (insert-text-button
       (concat (all-the-icons-octicon
                "list-ordered"
                :face 'font-lock-keyword-face)
               (propertize " Changelog" 'face 'font-lock-keyword-face))
       'action '(lambda (_) (find-file (f-expand "CHANGELOG.org" doom-emacs-dir)))
       'follow-link t)

      (insert "   ")

      (insert (all-the-icons-octicon "clock")
              " Uptime: "
              (emacs-uptime "%yy %dd %hh %mm %z%ss"))

      (setq end (point))
      (buffer-string))))

(provide 'core-scratch)
;;; core-scratch.el ends here
