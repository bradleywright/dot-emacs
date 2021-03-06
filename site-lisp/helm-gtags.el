;;; helm-gtags.el --- GNU GLOBAL helm.el interface
;; $Id: helm-gtags.el,v 1.27 2010-02-06 12:33:13 rubikitch Exp $

;; Copyright (C) 2008, 2009, 2010  rubikitch

;; Author: rubikitch <rubikitch@ruby-lang.org>
;; Keywords: global, languages
;; URL: http://www.emacswiki.org/cgi-bin/wiki/download/helm-gtags.el

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; * `helm-gtags-select' is `helm' interface of `gtags-find-tag'.
;; * `helm-c-source-gtags-select' is a source for `gtags-find-tag'.
;; * Replace *GTAGS SELECT* buffer with `helm' interface.

;;; Commands:
;;
;; Below are complete command list:
;;
;;  `helm-gtags-select'
;;    Tag jump using gtags and `helm'.
;;  `helm-gtags-resume'
;;    Select previously selected helm gtags buffer.
;;
;;; Customizable Options:
;;
;; Below are customizable option list:
;;
;;  `helm-gtags-enable-initial-pattern'
;;    *If non-nil, initial input of `helm-gtags-select' is current symbol.
;;    default = nil
;;  `helm-gtags-classify'
;;    *If non-nil, use separate source file by file.
;;    default = nil

;;; History:

;; $Log: helm-gtags.el,v $
;; Revision 1.27  2010-02-06 12:33:13  rubikitch
;; Added more actions to `helm-c-source-gtags-select'.
;; http://d.hatena.ne.jp/shinking/20100130/1264869641
;;
;; Revision 1.26  2009/12/28 04:07:00  rubikitch
;; remove warnings
;;
;; Revision 1.25  2009/12/28 03:59:17  rubikitch
;; New command `helm-gtags-resume'
;;
;; Revision 1.24  2009/12/28 01:39:51  rubikitch
;; Support multiple helm gtags buffer (resume)
;;
;; Revision 1.23  2009/12/21 10:41:21  rubikitch
;; Use `helm-persistent-highlight-point' if available.
;;
;; Revision 1.22  2009/12/19 01:22:27  rubikitch
;; cleanup
;;
;; Revision 1.21  2009/12/19 00:45:52  rubikitch
;; Avoid `select deleted buffer' error
;;
;; Revision 1.20  2009/12/19 00:31:55  rubikitch
;; Fixed variable bug
;;
;; Revision 1.19  2009/05/06 18:37:20  rubikitch
;; Resumable
;;
;; Revision 1.18  2009/04/01 14:59:27  rubikitch
;; Disable no-filename display (`helm-gtags-classify' == t) because `aggs-select-it' needs file-name.
;;
;; Revision 1.17  2009/03/18 17:50:08  rubikitch
;; If `helm-gtags-classify' is t, enable classification and suppress filename output.
;; If it is other true symbol, enable classification and output filename.
;;
;; Revision 1.16  2009/03/18 17:35:01  rubikitch
;; refactoring
;;
;; Revision 1.15  2009/03/18 17:31:39  rubikitch
;; Apply SUGAWARA's patch to suppress filename output when `helm-gtags-classify' is non-nil.
;;
;; Revision 1.14  2009/01/27 09:51:34  rubikitch
;; * Push context when jumping with `helm-gtags-select'.
;; * New variable: `helm-gtags-enable-initial-pattern'.
;;
;; Revision 1.13  2008/12/20 22:11:04  rubikitch
;; Fixed an error in Emacs23 by Andy Stewart. Thanks.
;;
;; Revision 1.12  2008/10/24 07:14:14  rubikitch
;; use `ad-get-arg'
;;
;; Revision 1.11  2008/09/06 06:01:07  rubikitch
;; Classify candidates by file name using meta source.
;; If `helm-gtags-classify' is non-nil, classification is enabled.
;;
;; Revision 1.10  2008/08/24 20:45:07  rubikitch
;; silence byte compiler
;;
;; Revision 1.9  2008/08/24 08:22:48  rubikitch
;; Rename `helm-candidates-buffer' -> `helm-candidate-buffer'
;;
;; Revision 1.8  2008/08/23 23:01:53  rubikitch
;; *** empty log message ***
;;
;; Revision 1.7  2008/08/20 19:00:36  rubikitch
;; *** empty log message ***
;;
;; Revision 1.6  2008/08/20 18:58:42  rubikitch
;; preselect entry of current line of source code.
;;
;; Revision 1.5  2008/08/19 21:50:00  rubikitch
;; adjust to new `search' spec.
;;
;; Revision 1.4  2008/08/18 17:20:23  rubikitch
;; save c source buffer's position
;; silence byte compiler
;;
;; Revision 1.3  2008/08/16 10:26:56  rubikitch
;; adjust to argument change of `helm-candidates-in-buffer-1'
;;
;; Revision 1.2  2008/08/14 20:47:14  rubikitch
;; ag-hijack-gtags-select-mode: cleanup
;;
;; Revision 1.1  2008/08/13 14:17:41  rubikitch
;; Initial revision
;;

;;; Code:

(require 'helm)
(require 'helm-config nil t)        ; highlight line if available
(require 'gtags nil t)

(defgroup helm-gtags nil
  "Gtags Helm interface"
  :group 'helm)

(defcustom helm-gtags-enable-initial-pattern nil
  "*If non-nil, initial input of `helm-gtags-select' is current symbol."
  :group 'helm-gtags
  :type 'boolean)

(defvar helm-c-source-gtags-select
  '((name . "GTAGS")
    (init
     . (lambda ()
         (call-process-shell-command
          "global -c" nil (helm-candidate-buffer 'global))))
    (candidates-in-buffer)
    (action
     ("Goto the location" . (lambda (candidate)
                              (gtags-push-context)
                              (gtags-goto-tag candidate "")))
     ("Goto the location (other-window)" . (lambda (candidate)
                                             (gtags-push-context)
                                             (gtags-goto-tag candidate "" t)))
     ("Move to the referenced point" . (lambda (candidate)
                                         (gtags-push-context)
                                         (gtags-goto-tag candidate "r"))))))

;; (setq helm-sources (list helm-c-source-gtags-select))

(defun helm-gtags-select ()
  "Tag jump using gtags and `helm'."
  (interactive)
  (let* ((initial-pattern (regexp-quote (or (thing-at-point 'symbol) ""))))
    (helm '(helm-c-source-gtags-select)
              (if helm-gtags-enable-initial-pattern initial-pattern)
              "Find Tag: " nil)))

;;;; `gtags-select-mode' replacement
(defvar helm-gtags-hijack-gtags-select-mode t
  "Use `helm' instead of `gtags-select-mode'.")
(defcustom helm-gtags-classify nil
  "*If non-nil, use separate source file by file.
If it is t, enable classification and suppress file name output in candidates.
If it is other symbol, display file name in candidates even if classification is enabled."
  :group 'helm-gtags
  :type '(choice boolean symbol))
(defvar aggs-base-source
  '((candidates-in-buffer)
    (get-line . aggs-candidate-display)
    (display-to-real
     . (lambda (c) (if (string-match "^ " c) (concat "_ " c) c)))
    (action ("Goto the location" . aggs-select-it))))
(defvar aggs-buffer "*helm gtags select*")

(defun aggs-candidate-display (s e)
  (buffer-substring-no-properties (aggs-search-not-space-point s e) e))

(defun aggs-search-not-space-point (s e)
  (save-excursion
    (goto-char s)
    (let ((space-point (search-forward " " e t)))
      (if (and space-point (> (- space-point s) 16))
          (- space-point 1) ; for buffer-substring
        (+ s 16)))))

(defun aggs-set-helm-current-position ()
  (declare (special c-source-file))
  ;; It's needed because `helm' saves
  ;; *GTAGS SELECT* buffer's position,
  (save-window-excursion
    (switch-to-buffer c-source-file)
    (setq helm-current-position (cons (point) (window-start)))))

(defun ag-hijack-gtags-select-mode ()
  ;; `save' C source file / `buffer': gtags-select-mode gtags-select-buffer
  ;; They are defined at `gtags-goto-tag'.
  (declare (special save buffer))
  (let* ((c-source-file save)
         (gtags-select-buffer buffer)
         (helm-candidate-number-limit 9999)
         (bfn (with-current-buffer c-source-file buffer-file-name))
         (pwd (with-current-buffer gtags-select-buffer (file-name-directory bfn)))
         (basename (substring bfn (length pwd)))
         (lineno (with-current-buffer c-source-file
                   (save-restriction
                     (widen)
                     (line-number-at-pos))))
         (sources (if helm-gtags-classify
                      '(((name . "GTAGS SELECT meta source")
                         (init . aggs-meta-source-init)))
                    `(((name . "GTAGS SELECT")
                       (init
                        . (lambda ()
                            (aggs-set-helm-current-position)
                            (helm-candidate-buffer gtags-select-buffer)))
                       ,@aggs-base-source))))
         (aggs-buffer (concat "*helm gtags*"
                              (substring (buffer-name gtags-select-buffer) 15))))
    (with-current-buffer (get-buffer-create aggs-buffer)
      (set (make-local-variable 'gtags-select-buffer) gtags-select-buffer)
      (set (make-local-variable 'pwd) pwd))
    (helm
     sources
     nil nil nil (format "\\(\\(%d\\) +%s\\)" lineno (regexp-quote basename))
     aggs-buffer)))

(defun aggs-candidate-buffer-by-filename (filename)
  (get-buffer-create (concat "*helm gtags*" filename)))
(defun aggs-meta-source-init ()
  (declare (special gtags-select-buffer))
  (aggs-set-helm-current-position)
  (with-current-buffer gtags-select-buffer
    (goto-char (point-min))
    (let (files prev-filename)
      (loop while (re-search-forward " [0-9]+ \\([^ ]+\\) " (point-at-eol) t)
            for filename = (match-string 1)
            for bol = (point-at-bol)
            for eol = (point-at-eol)
            do
            (with-current-buffer (aggs-candidate-buffer-by-filename filename)
              (unless (equal prev-filename filename)
                (setq files (cons filename files))
                (erase-buffer))
              (save-excursion (insert-buffer-substring gtags-select-buffer bol eol))
              (goto-char (point-max))
              (insert "\n"))
            (forward-line 1)
            (setq prev-filename filename))
      (helm-set-sources
       (loop for file in (nreverse files) collect
             (append `((name . ,file)
                       (init . (lambda ()
                                 (helm-candidate-buffer
                                  ,(aggs-candidate-buffer-by-filename file)))))
                     aggs-base-source)))
      (helm-funcall-foreach 'init))))

(defun aggs-select-it (candidate)
  (with-temp-buffer
    ;; `pwd' is defined at `ag-hijack-gtags-select-mode'.
    (setq default-directory
          (if (fboundp 'gtags-get-rootpath)
              (let (rootdir)
                (or gtags-rootdir (gtags-get-rootpath)))
            (buffer-local-value 'pwd (get-buffer helm-buffer))))
    (insert candidate "\n")
    (forward-line -1)
    (gtags-select-it nil)
    ;; TODO fboundp
     (when (and helm-in-persistent-action
               (fboundp 'helm-persistent-highlight-point))
      (helm-persistent-highlight-point (point-at-bol) (point-at-eol)))))

(defun helm-gtags-resume ()
  "Select previously selected helm gtags buffer."
  (interactive)
  (helm-resume t))

(defadvice switch-to-buffer (around helm-gtags activate)
  "Use `helm' instead of `gtags-select-mode' when `helm-gtags-hijack-gtags-select-mode' is non-nil."
  (unless (and helm-gtags-hijack-gtags-select-mode
           (string-match "*GTAGS SELECT*"
                         (if (bufferp (ad-get-arg 0))
                             (buffer-name (ad-get-arg 0))
                               (or (ad-get-arg 0) ""))))
    ad-do-it))
;; (progn (ad-disable-advice 'switch-to-buffer 'around 'helm-gtags) (ad-update 'switch-to-buffer)) 

(defadvice gtags-select-mode (around helm-gtags activate)
  "Use `helm' instead of `gtags-select-mode' when `helm-gtags-hijack-gtags-select-mode' is non-nil."
  (if helm-gtags-hijack-gtags-select-mode
      (ag-hijack-gtags-select-mode)
    ad-do-it))
;; (progn (ad-disable-advice 'gtags-select-mode 'around 'helm-gtags) (ad-update 'gtags-select-mode)) 

(provide 'helm-gtags)

;; How to save (DO NOT REMOVE!!)
;; (progn (magit-push) (emacswiki-post "helm-gtags.el"))
;;; helm-gtags.el ends here
