#lang racket

(provide (rename-out [-read read] [-read-syntax read-syntax] [-get-info get-info]))

(require syntax/module-reader
         lang-extension/lang-reader
         lang-extension/meta-reader-util
         hygienic-reader-extension/extend-reader)

;; wrap-reader : (-> (-> A ... Any) (-> A ... Any))
(define (wrap-reader reader-proc)
  (extend-reader reader-proc extend-readtable))

;; make-hygienic-quote-lang-reader : (-> Lang-Reader Lang-Reader)
(define (make-hygienic-quote-lang-reader -lang-reader)
  (define/lang-reader [-read -read-syntax -get-info] -lang-reader)
  (make-lang-reader
   (wrap-reader -read)
   (wrap-reader -read-syntax)
   -get-info))

;; add-quote : (-> Syntax Syntax)
(define (add-quote stx)
  #`(quote #,stx))

;; extend-readtable : (-> Readtable #:outer-scope (-> Syntax Syntax) Readtable)
(define (extend-readtable rt #:outer-scope outer-scope)
  (make-readtable rt
    #\' 'terminating-macro (quote-proc outer-scope)))

;; quote-proc : (-> (-> Syntax Syntax) Readtable-Proc)
(define ((quote-proc outer-scope) c in src ln col pos)
  (hygienic-app add-quote (read-syntax/recursive src in)
                #:outer-scope outer-scope))

(define/lang-reader [-read -read-syntax -get-info]
  (lang-extension->lang-reader 'hygienic-quote make-hygienic-quote-lang-reader))

