#lang racket/base

(provide reader-module-paths)

;; From at-exp/lang/reader.rkt
;; https://github.com/racket/racket/blob/master/pkgs/at-exp-lib/at-exp/lang/reader.rkt#L19

;; reader-module-paths : Byte-String -> (U False (Vectorof Module-Path))
;; To be used as the third argument to make-meta-reader from syntax/module-reader
(define (reader-module-paths bstr)
  (let* ([str (bytes->string/latin-1 bstr)]
         [sym (string->symbol str)])
    (and (module-path? sym)
         (vector
          ;; try submod first:
          `(submod ,sym reader)
          ;; fall back to /lang/reader:
          (string->symbol (string-append str "/lang/reader"))))))

