#lang racket/base

(provide #%module-begin)

(require "lang-reader.rkt"
         (only-in "lang-reader-lang.rkt" [#%module-begin lang-reader-module-begin])
         syntax/parse/define
         )

(define-simple-macro
  (#%module-begin
   #:lang-reader name
   #:syntax/module-reader
   syntax-module-reader-stuff
   ...)
  (lang-reader-module-begin
   #:lang-reader name (make-lang-reader -read -read-syntax -get-info)
   (module reader syntax/module-reader
     syntax-module-reader-stuff
     ...)
   (require (only-in 'reader [read -read] [read-syntax -read-syntax] [get-info -get-info]))))

