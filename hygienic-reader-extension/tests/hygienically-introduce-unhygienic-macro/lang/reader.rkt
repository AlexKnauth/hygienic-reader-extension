#lang lang-extension
#:lang-extension hygienically-introduce-unhygienic-macro make-the-lang-reader
#:lang-reader hygienically-introduce-unhygienic-macro/lang

(require lang-reader/lang-reader
         hygienic-reader-extension/extend-reader
         "../unhygienic-macro.rkt")

;; wrap-reader : (-> (-> A ... Any) (-> A ... Any))
(define (wrap-reader reader-proc)
  (extend-reader reader-proc extend-readtable))

;; make-the-lang-reader : (-> Lang-Reader Lang-Reader)
(define (make-the-lang-reader -lang-reader)
  (define/lang-reader [-read -read-syntax -get-info] -lang-reader)
  (make-lang-reader
   (wrap-reader -read)
   (wrap-reader -read-syntax)
   -get-info))

;; introduce-refer-to-it : (-> Syntax Syntax)
(define (introduce-refer-to-it stx)
  #'(refer-to-it))

;; extend-readtable : (-> Readtable #:outer-scope (-> Syntax Syntax) Readtable)
(define (extend-readtable rt #:outer-scope outer-scope)
  (make-readtable rt
    #\$ 'dispatch-macro (reader-proc outer-scope)))

;; reader-proc : (-> (-> Syntax Syntax) Readtable-Proc)
(define ((reader-proc outer-scope) c in src ln col pos)
  (hygienic-app introduce-refer-to-it #'#f
                #:outer-scope outer-scope))

