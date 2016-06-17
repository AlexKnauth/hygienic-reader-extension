#lang racket/base

(provide extend-reader
         hygienic-app
         )

;; extend-reader : (-> (-> A ... Any)
;;                     (-> Readtable #:outer-scope (-> Syntax Syntax) Readtable)
;;                     (-> A ... Any))
(define (extend-reader proc extend-readtable)
  (lambda args
    (define orig-readtable (current-readtable))
    (define outer-scope (make-syntax-introducer/use-site))
    (parameterize ([current-readtable (extend-readtable orig-readtable #:outer-scope outer-scope)])
      (define stx (apply proc args))
      (if (syntax? stx)
          (outer-scope stx)
          stx))))

;; make-syntax-introducer/use-site : (-> (-> Syntax Syntax))
(define (make-syntax-introducer/use-site)
  (cond [(procedure-arity-includes? make-syntax-introducer 1)
         (make-syntax-introducer #t)]
        [else
         (make-syntax-introducer)]))

;; hygienic-app : (-> (-> Syntax Syntax) Syntax #:outer-scope (-> Syntax Syntax) Syntax)
;; Applies proc to stx, but with extra scopes added to the input and
;; output to make it hygienic.
;; This is meant to be used within a reader-proc added using the
;; extend-reader function, and the outer-scope argument should come
;; from the outer-scope argument passed to the extend-readtable
;; argument to that function.
(define (hygienic-app proc stx #:outer-scope outer-scope)
  (define inner-scope (make-syntax-introducer))
  (outer-scope (inner-scope (proc (inner-scope (outer-scope stx))))))

