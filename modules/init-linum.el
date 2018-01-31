;;;; Line numbers
;;;
;;; The number one thing that can make Emacs slow is the line number mode.
;;; This module turn it on for all modes except the ones that for which we
;;; don't need it (e.g. using an exception list).
;;;
;;; See also init-ui.el

(require 'linum)
(require 'nlinum)
(require 'init-prefs)

(defun nlinum--setup-window-fudge ()
  "Workaround a bug in older versions of Emacs"
  (let ((width (if (display-graphic-p)
                   (ceiling
                    (let ((width nil))
                      (if width
                          (/ (* nlinum--width 1.0 width)
                             (frame-char-width))
                        (/ (* nlinum--width 1.0
                              16)
                           (frame-char-height)))))
                 nlinum--width)))
    (set-window-margins nil (if nlinum-mode width)
                        (cdr (window-margins)))))

(defun exordium-inhibit-line-numbers-p ()
  (or (cl-member major-mode exordium-inhibit-line-numbers-modes)
      (and exordium-inhibit-line-numbers-star-buffers
           (eq 0 (string-match "*" (buffer-name))))
      (> (buffer-size) exordium-inhibit-line-numbers-buffer-size)))

;;;###autoload
(define-globalized-minor-mode exordium-global-nlinum-mode nlinum-mode
  (lambda () (unless (or (minibufferp)
                         (exordium-inhibit-line-numbers-p))
               (nlinum-mode))))

(cond ((and (fboundp 'global-nlinum-mode)
            (eq exordium-display-line-numbers :nlinum))
       ;; Use nlinum - a lazy, faster mode for line numbers
       ;;
       (let ((min-version "24.5"))
         (when (version< emacs-version min-version)
           ;; Workaround a bug in Emacs causing emacsclient to display
           ;; "*ERROR*: Invalid face: linum".  See
           ;; http://lists.gnu.org/archive/html/bug-gnu-emacs/2015-01/msg00079.html
           (fset 'nlinum--setup-window 'nlinum--setup-window-fudge)))

       (exordium-global-nlinum-mode t))

      ((and (fboundp 'global-linum-mode)
            (eq exordium-display-line-numbers t))
       ;; Use linum - non-lazy mode for line numbers
       ;;
       ;; Make line numbers display correctly when user zooms with C-+/C--
       ;; FIXME: this is broken, just a workaround for now.
       (when (facep 'linum-highlight-face)
         (let ((h (face-attribute 'default :height)))
           (set-face-attribute 'linum nil :height h)
           (set-face-attribute 'linum-highlight-face nil :height h)))
       ;;
       ;; Turn on linum
       (global-linum-mode t)

       (defadvice linum-on (around linum-on-inhibit-for-modes)
         "Stop the load of linum-mode for some major modes."
         (unless (exordium-inhibit-line-numbers-p)
           ad-do-it))
       (ad-activate 'linum-on)))

(provide 'init-linum)
