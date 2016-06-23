#lang racket

(provide (rename-out [-read read] [-read-syntax read-syntax] [-get-info get-info]))

(require syntax/module-reader
         lang-extension/meta-reader-util
         hygienic-reader-extension/extend-reader)

;; wrap-reader : (-> (-> A ... Any) (-> A ... Any))
(define (wrap-reader reader-proc)
  (extend-reader reader-proc extend-readtable))

(define-values [-read -read-syntax -get-info]
  (make-meta-reader
   'hygienic-quote
   "language path"
   lang-reader-module-paths
   wrap-reader ; for read
   wrap-reader ; for read-syntax
   identity))  ; for get-info

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

