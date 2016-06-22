#lang hygienic-reader-extension/tests/hygienic-quote racket

(require rackunit)

(check-equal? '3 3)

(define (quote x) 5)
(check-equal? (quote 3) 5)
(check-equal? '3 3)  

;; this shouldn't conflict with the earlier definition of quote
(define 'foo 6)            ; (define (quote foo) 6), sort of
(check-equal? '3 3)        ; but that quote does not bind this one
(check-equal? (quote 3) 5) ; or this one

