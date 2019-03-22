;;; inim.el --- Inim minor mode for Nim Repl support

;; Copyright (C) 2018 Andres Mariscal

;; Author: Andres Mariscal <carlos.mariscal.melgar@gmail.com>
;; Created: 26 Sep 2018
;; Version: 0.0.1
;; Keywords: nim languages repl
;; URL: https://github.com/serialdev/inim-mode
;; Package-Requires: ((emacs "24.3", parsec ))
;;; Commentary:
;; Nim Repl support through inim repl

;; Usage

(defcustom inim-shell-buffer-name "*Inim*"
  "Name of buffer for inim."
  :group 'inim
  :type 'string)

(defun inim-is-running? ()
  "Return non-nil if inim is running."
  (comint-check-proc inim-shell-buffer-name))
(defalias 'inim-is-running-p #'inim-is-running?)

;;;###autoload
(defun inim (&optional arg)
  "Run inim.
Unless ARG is non-nil, switch to the buffer."
  (interactive "P")
  (let ((buffer (get-buffer-create inim-shell-buffer-name)))
    (unless arg
      (pop-to-buffer buffer))
    (unless (inim-is-running?)
      (with-current-buffer buffer
        (inim-startup)
        (inferior-inim-mode)
	)
      (pop-to-buffer buffer)
      (other-window -1)
      )
    ;; (with-current-buffer buffer (inferior-inim-mode))
    buffer))



;;;###autoload
(defalias 'run-nim #'inim)
;;;###autoload
(defalias 'inferior-nim #'inim)


(defun inim-startup ()
  "Start inim."
  (comint-exec inim-shell-buffer-name "inim" inim-program nil inim-args))

(defun maintain-indentation (current previous-indent)
  (when current
    (let ((current-indent (length (inim-match-indentation (car current)))))
      (if (< current-indent previous-indent)
	  (progn
	    (comint-send-string inim-shell-buffer-name "\n")
	    (comint-send-string inim-shell-buffer-name (car current))
	    (comint-send-string inim-shell-buffer-name "\n"))
      (progn
	(comint-send-string inim-shell-buffer-name (car current))
	(comint-send-string inim-shell-buffer-name "\n")))
      (maintain-indentation (cdr current) current-indent)
      )))

(defun inim-split (separator s &optional omit-nulls)
  "Split S into substrings bounded by matches for regexp SEPARATOR.
If OMIT-NULLS is non-nil, zero-length substrings are omitted.
This is a simple wrapper around the built-in `split-string'."
  (declare (side-effect-free t))
  (save-match-data
    (split-string s separator omit-nulls)))


(defun inim-match-indentation(data)
  (regex-match "^[[:space:]]*" data 0))


(defun inim-eval-region (begin end)
  "Evaluate region between BEGIN and END."
  (interactive "r")
  (inim t)
  (progn
    (maintain-indentation (inim-split "\n"
				      (buffer-substring-no-properties begin end)) 0)
    (comint-send-string inim-shell-buffer-name ";\n")
  ))


;; (defun inim-type-check ()
;;   (interactive)
;;   (comint-send-string inim-shell-buffer-name (concat "let inimmodetype: () = " (thing-at-point 'symbol) ";"))
;;   (comint-send-string inim-shell-buffer-name "\n")
;;   )

;; (defun inim-type-check-in-container ()
;;   (interactive)
;;   (comint-send-string inim-shell-buffer-name (concat "let inimmodetype: () = " (thing-at-point 'symbol) "[0];"))
;;   (comint-send-string inim-shell-buffer-name "\n")
;;   )


(defun inim-parent-directory (dir)
  (unless (equal "/" dir)
    (file-name-directory (directory-file-name dir))))

(defun inim-find-file-in-hierarchy (current-dir fname)
  "Search for a file named FNAME upwards through the directory hierarchy, starting from CURRENT-DIR"
  (let ((file (concat current-dir fname))
        (parent (inim-parent-directory (expand-file-name current-dir))))
    (if (file-exists-p file)
        file
      (when parent
        (inim-find-file-in-hierarchy parent fname)))))


(defun inim-get-string-from-file (filePath)
  "Return filePath's file content.
;; thanks to “Pascal J Bourguignon” and “TheFlyingDutchman 〔zzbba…@aol.com〕”. 2010-09-02
"
  (with-temp-buffer
    (insert-file-contents filePath)
    (buffer-string)))


(defun inim-eval-buffer ()
  "Evaluate complete buffer."
  (interactive)
  (inim-eval-region (point-min) (point-max)))

(defun inim-eval-line (&optional arg)
  "Evaluate current line.
If ARG is a positive prefix then evaluate ARG number of lines starting with the
current one."
  (interactive "P")
  (unless arg
    (setq arg 1))
  (when (> arg 0)
    (inim-eval-region
     (line-beginning-position)
     (line-end-position arg))))


;;; Shell integration

(defcustom inim-shell-interpreter "inim"
  "default repl for shell"
  :type 'string
  :group 'inim)

(defcustom inim-shell-internal-buffer-name "Inim Internal"
  "Default buffer name for the internal process"
  :type 'string
  :group 'nim
  :safe 'stringp)


(defcustom inim-shell-prompt-regexp "nim> "
  "Regexp to match prompts for inim.
   Matchint top\-level input prompt"
  :group 'inim
  :type 'regexp
  :safe 'stringp)

(defcustom inim-shell-prompt-block-regexp " "
  "Regular expression matching block input prompt"
  :type 'string
  :group 'inim
  :safe 'stringp)

(defcustom inim-shell-prompt-output-regexp ""
  "Regular Expression matching output prompt of evxcr"
  :type 'string
  :group 'inim
  :safe 'stringp)

(defcustom inim-shell-enable-font-lock t
  "Should syntax highlighting be enabled in the inim shell buffer?"
  :type 'boolean
  :group 'inim
  :safe 'booleanp)

(defcustom inim-shell-compilation-regexp-alist '(("[[:space:]]\\^+?"))
  "Compilation regexp alist for inferior inim"
  :type '(alist string))

(defgroup inim nil
  "Nim interactive mode"
  :link '(url-link "https://github.com/serialdev/inim-mode")
  :prefix "inim"
  :group 'languages)

(defcustom inim-program (executable-find "inim")
  "Program invoked by `inim'."
  :group 'inim
  :type 'file)


(defcustom inim-args nil
  "Command line arguments for `inim-program'."
  :group 'inim
  :type '(repeat string))



(defcustom inim-prompt-read-only t
  "Make the prompt read only.
See `comint-prompt-read-only' for details."
  :group 'inim
  :type 'boolean)

(defun inim-comint-output-filter-function (output)
  "Hook run after content is put into comint buffer.
   OUTPUT is a string with the contents of the buffer"
  (ansi-color-filter-apply output))



(define-derived-mode inferior-inim-mode comint-mode "Inim"
  (setq comint-process-echoes t)
  ;; (setq comint-prompt-regexp (format "^\\(?:%s\\|%s\\)"
  ;; 				     inim-shell-prompt-regexp
  ;; 				     inim-shell-prompt-block-regexp))
  (setq comint-prompt-regexp "nim> ")

  (setq mode-line-process '(":%s"))
  (make-local-variable 'comint-output-filter-functions)
  (add-hook 'comint-output-filter-functions
  	    'inim-comint-output-filter-function)
  (set (make-local-variable 'compilation-error-regexp-alist)
       inim-shell-compilation-regexp-alist)
  (setq comint-use-prompt-regexp t)
  (setq comint-inhibit-carriage-motion nil)
  (setq-local comint-prompt-read-only inim-prompt-read-only)
  (when inim-shell-enable-font-lock
    (set-syntax-table nim-mode-syntax-table)
    (set (make-local-variable 'font-lock-defaults)
	 '(nim-mode-font-lock-keywords nil nil nil nil))
    (set (make-local-variable 'syntax-propertize-function)
    	 (eval
    	  "Unfortunately eval is needed to make use of the dynamic value of comint-prompt-regexp"
    	  '(syntax-propertize-rules
    	    '(comint-prompt-regexp
    	       (0 (ignore
    		   (put-text-property
    		    comint-last-input-start end 'syntax-table
    		    python-shell-output-syntax-table)
    		   (font-lock-unfontify--region comint-last-input-start end))))
    	    )))
    (compilation-shell-minor-mode 1)))

(progn
  (define-key nim-mode-map (kbd "C-c C-b") #'inim-eval-buffer)
  (define-key nim-mode-map (kbd "C-c C-r") #'inim-eval-region)
  (define-key nim-mode-map (kbd "C-c C-l") #'inim-eval-line)
  (define-key nim-mode-map (kbd "C-c C-p") #'inim))

;;;###autoload
;; (inim-nim-keymap)


(provide 'inim)

;;; inim.el ends here
