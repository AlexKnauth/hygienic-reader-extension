#lang racket/base

(provide make-lang-reader define/lang-reader lang-reader/reader-module)

(require racket/match
         syntax/parse/define
         )

(struct lang-reader [read read-syntax get-info])

;; A Lang-Extension is a (-> Lang-Reader Lang-Reader)

;; make-lang-reader : Read-Proc Read-Syntax-Proc Get-Info-Proc -> Lang-Reader
(define (make-lang-reader -read -read-syntax -get-info)
  (lang-reader -read -read-syntax -get-info))

(define-simple-macro
  (define/lang-reader [-read:id -read-syntax:id -get-info:id] lang-reader-instance:expr)
  (match-define (lang-reader -read -read-syntax -get-info) lang-reader-instance))

;; lang-reader/reader-module : Module-Path -> Lang-Reader
(define (lang-reader/reader-module modpath)
  (make-lang-reader
   (dynamic-require modpath 'read)
   (dynamic-require modpath 'read-syntax)
   (dynamic-require modpath 'get-info)))

