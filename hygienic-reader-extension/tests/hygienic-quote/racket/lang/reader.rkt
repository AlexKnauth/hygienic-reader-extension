#lang lang-reader
#:lang-reader hygienic-quote/racket (hygienic-quote racket)
(require lang-reader/lang-reader
         hygienic-reader-extension/tests/hygienic-quote/lang/reader)
(define racket (lang-reader/reader-module 'racket/lang/reader))
