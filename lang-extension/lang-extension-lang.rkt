#lang racket/base

(provide #%module-begin
         (all-from-out racket/base))

(require (only-in lang-reader/lang-reader-lang [#%module-begin lang-reader-module-begin])
         syntax/parse/define
         "meta-reader-util.rkt"
         )

(define-simple-macro
  (#%module-begin
   #:lang-extension name:id lang-extension:expr
   #:lang-reader name/lang:id
   mod-body:expr
   ...)
  (lang-reader-module-begin
   #:lang-reader name/lang (lang-extension->lang-reader 'name name)
   mod-body
   ...
   (define name lang-extension)
   (provide name)))

