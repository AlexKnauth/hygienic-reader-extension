#lang racket/base

(provide define-it refer-to-it)

(require syntax/parse/define
         (for-syntax racket/base))

(define-simple-macro (define-it)
  #:with x (syntax-local-identifier-as-binding
            (syntax-local-introduce #'it))
  (define x 42))

(define-syntax-parser refer-to-it
  [(_) (syntax-local-introduce #'it)])
