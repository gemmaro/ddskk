;;; skk-comp.el --- $BJd40$N$?$a$N%W%m%0%i%`(B
;; Copyright (C) 1988, 1989, 1990, 1991, 1992, 1993, 1994, 1995, 1996, 1997
;;               1999
;; Masahiko Sato <masahiko@kuis.kyoto-u.ac.jp>

;; Author: Masahiko Sato <masahiko@kuis.kyoto-u.ac.jp>
;; Maintainer: Mikio Nakajima <minakaji@osaka.email.ne.jp>
;; Version: $Id: skk-comp.el,v 1.6 1999/12/13 23:45:14 minakaji Exp $
;; Keywords: japanese
;; Last Modified: $Date: 1999/12/13 23:45:14 $

;; This file is part of SKK.

;; SKK is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either versions 2, or (at your option)
;; any later version.

;; SKK is distributed in the hope that it will be useful
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with SKK, see the file COPYING.  If not, write to the Free
;; Software Foundation Inc., 59 Temple Place - Suite 330, Boston,
;; MA 02111-1307, USA.

;;; Commentary:
;; $B"&$5(B (TAB) -> $B"&$5$H$&(B (.) -> $B"&$5$$$H$&(B (,) -> $B"&$5$H$&(B(.) -> $B"&$5$$$H$&(B

;;; Code:
(eval-when-compile (require 'skk))
(require 'skk-foreword)

;;;###autoload
(defgroup skk-comp nil "SKK completion related customization."
  :prefix "skk-"
  :group 'skk )

;;; -- user variables
(defcustom skk-dabbrev-like-completion nil
  "*Non-nil $B$G$"$l$P!"8+=P$78l$NJd40$K$*$$$F!":G8e$KJd40$5$l$?8l$K$D$$$F99$KJd40$,9T$o$l$k!#(B
$BNc$($P!"(B

  \"$B$5(B\" (,) -> \"$B$5$H$&(B\" (,) -> \"$B$5$H$&$;$s$;$$(B\"

nil $B$G$"$l$P!"@hF,$NJ8;z$r6&DL$K$9$kJ8;zNs$K$D$$$FJd40$,9T$J$o$l$k!#(B
$BNc$($P!"(B

  \"$B$5(B\" (,) -> \"$B$5$H$&(B\" (,) -> \"$B$5$$$H$&(B\" (,) -> \"$B$5$/$i(B\""
  :type 'boolean
  :group 'skk-comp )

(defcustom skk-completion-function 'skk-completion-original
  "*skk-completion $B$G;HMQ$9$k4X?t!#(B
skk-comp.el $B0J30$NJd405!G=$rMxMQ$G$-$k$h$&$K4X?t$r(B funcall $B$9$k7A$K$7$F$*$/!#(B"
  :type 'function
  :group 'skk-comp )

(defcustom skk-previous-completion-function 'skk-previous-completion-original
  "*skk-previous-completion $B$G;HMQ$9$k4X?t!#(B
skk-comp.el $B0J30$NJd405!G=$rMxMQ$G$-$k$h$&$K4X?t$r(B funcall $B$9$k7A$K$7$F$*$/!#(B"
  :type 'function
  :group 'skk-comp )

(defcustom skk-comp-load-hook nil
  "*skk-comp.el $B$r%m!<%I$7$?8e$K%3!<%k$5$l$k%U%C%/!#(B"
  :type 'hook
  :group 'skk-comp )

;;; -- internal variables
;; ---- buffer local variables
;; $B6uJ8;zNs$KBP$7$F(B skk-completion $B$r8F$V$3$H$b$"$j$&$k$N$G!"(B"" $B$r(B nil $B$G$OBe(B
;; $BMQ$G$-$J$$!#(B
(skk-deflocalvar skk-completion-word ""
  "$BJd40$9$Y$-8+=P$78l!#(B
skk-dabbrev-like-completion $B$,(B non-nil $B$N>l9g$O!">o$K:G8e$KJd40$7$?8+=P$78l$,(B
$BBeF~$5$l$k!#(B" )
;; $B<-=qEPO?;~%_%K%P%C%U%!$GJd40$7$?>l9g!"85$N%P%C%U%!$KLa$C$?$H$-$K(B
;; skk-completion-word $B$NCM$,GK2u$5$l$F$$$J$$J}$,%Y%?!<!#(B

(skk-deflocalvar skk-completion-stack nil
  "$BJd40$7$?8l$rJ]B8$7$F$*$/%9%?%C%/!#(B" )

(skk-deflocalvar skk-completion-depth 0
  "$BJd40$7$?8l$r(B skk-completion-stack $B$+$i<h$j=P$90LCV!#(B" )

;;;###autoload
(defun skk-start-henkan-with-completion (arg)
  "$B"&%b!<%I$GFI$_$NJd40$r9T$J$C$?8e!"JQ49$9$k!#(B
$B$=$l0J30$N%b!<%I$G$O%*%j%8%J%k$N%-!<%^%C%W$K3d$jIU$1$i$l$?%3%^%s%I$r%(%_%e%l!<(B
$B%H$9$k!#(B"
  (interactive "*P")
  (if (and skk-henkan-on (not skk-henkan-active))
      (progn
        (skk-completion (not (eq last-command 'skk-completion)))
        (skk-start-henkan arg) )
    (skk-emulate-original-map arg) ))

;;;###autoload
(defun skk-completion (first)
  ;; skk-try-completion $B$N%5%V%k!<%A%s!#(B
  ;; skk-comp.el $B0J30$NJd405!G=$rMxMQ$G$-$k$h$&$K4X?t$r(B funcall $B$9$k7A$K$7$F$*$/!#(B
  (funcall skk-completion-function first) )

(defun skk-completion-original (first)
  ;; default $B$N(B skk-completion-function.
  (let ((inhibit-quit t)
	;; skk-num $B$,(B require $B$5$l$F$J$$$H(B buffer-local $BCM$r2u$962$l$"$j!#(B
        skk-num-list
        completion-word c-word )
    (skk-kana-cleanup 'force)
    (and first (setq skk-completion-stack nil skk-completion-depth 0))
    (and (or first skk-dabbrev-like-completion)
	 (setq skk-completion-word
	       (buffer-substring-no-properties skk-henkan-start-point (point)) ))
    (and (string= skk-completion-word "")
	 (skk-error "$B6uJ8;z$+$iJd40$9$k$3$H$O$G$-$^$;$s!*(B"
		    "Cannot complete an empty string!" ))
    (if (> skk-completion-depth 0)
	;; ($B2a5n$KC5:w:Q$_$NFI$_$r%"%/%;%9Cf(B)
	(setq skk-completion-depth (1- skk-completion-depth)
	      c-word (nth skk-completion-depth skk-completion-stack))
      ;; ($B?75,$NFI$_$r<-=q%P%C%U%!$+$iC5:w(B)
      ;; skk-completion-word $B$O%P%C%U%!%m!<%+%kCM$J$N$G!"<-=q%P%C%U%!$K0\$kA0$K(B
      ;; $B0l;~JQ?t$K0\$7JQ$($F$*$/!#(B
      (setq completion-word skk-completion-word)
      (with-current-buffer (skk-get-jisyo-buffer skk-jisyo)
	(if first (goto-char skk-okuri-nasi-min))
	(save-match-data
	  ;; case-fold-search $B$O!"<-=q%P%C%U%!$G$O>o$K(B nil$B!#(B
	  (while
	      (and (not c-word)
		   (search-forward
		    (concat "\n"
			    (if skk-use-numeric-conversion
				(skk-num-compute-henkan-key completion-word)
			      completion-word ))
		    nil t ))
	    (if (eq (following-char) ?\040) ;SPC
		nil
	      (setq c-word (concat completion-word
				   (buffer-substring-no-properties
				    ;; $B8+=P$78l$K6uGr$O4^$^$l$J$$!#(B" /" $B$r%5!<(B
				    ;; $B%A$9$kI,MW$O$J$$!#(B
				    (point) (1- (search-forward " ")) )))))))
      (and (not c-word) skk-abbrev-mode skk-use-look
	   (setq c-word (skk-look-completion)) )
      ;; $B?75,$K8+$D$1$?$H$-$@$1(B cons $B$9$k!#(B
      (setq skk-completion-stack (cons c-word skk-completion-stack)) )
    ;; $B<-=q%P%C%U%!$N30!#(B
    (if (not c-word)
	(progn
	  (setq skk-completion-depth (1+ skk-completion-depth))
	  (if skk-japanese-message-and-error
	      (error "\"%s\" $B$GJd40$9$Y$-8+=P$78l$O(B%s$B$"$j$^$;$s(B"
		     skk-completion-word (if first "" "$BB>$K(B") )
	    (error "No %scompletions for \"%s\""
		   (if first "" "more ") skk-completion-word )) )
      (delete-region skk-henkan-start-point (point))
      (insert c-word) )))

;;;###autoload
(defun skk-previous-completion ()
  ;; skk-abbrev-comma, skk-insert-comma $B$N%5%V%k!<%A%s!#D>A0$KJd40$r9T$C$?8+(B
  ;; $B=P$7$rA^F~$9$k!#(B
  ;; skk-comp.el $B0J30$NJd405!G=$rMxMQ$G$-$k$h$&$K4X?t$r(B funcall $B$9$k7A$K$7$F$*$/!#(B
  (funcall skk-previous-completion-function) )

(defun skk-previous-completion-original ()
  ;; default $B$N(B skk-previous-completion-function.
  (let ((inhibit-quit t)
        (c-word 
	 (progn
	   (setq skk-completion-depth (1+ skk-completion-depth))
	   (nth skk-completion-depth skk-completion-stack) )))
    (if c-word
	(progn
	  (delete-region skk-henkan-start-point (point))
	  (insert c-word) )
      (setq skk-completion-depth (1- skk-completion-depth))
      (skk-error "\"%s\"$B$GJd40$9$Y$-8+=P$78l$OB>$K$"$j$^$;$s(B"
                 "No more previous completions for \"%s\""
                 skk-completion-word ))))

(run-hooks 'skk-comp-load-hook)

(provide 'skk-comp)
;;; Local Variables:
;;; End:
;;; skk-comp.el ends here
