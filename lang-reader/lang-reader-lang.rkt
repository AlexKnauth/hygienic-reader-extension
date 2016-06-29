#lang racket/base

(provide #%module-begin
         (all-from-out racket/base))

(require (only-in racket/base [#%module-begin -#%module-begin])
         syntax/parse/define
         lang-extension/lang-reader
         )

(define-simple-macro
  (#%module-begin
   #:lang-reader name:id lang-reader:expr
   mod-body:expr
   ...)
  (-#%module-begin
   mod-body
   ...
   (define name lang-reader)
   (define/lang-reader [-read -read-syntax -get-info]
     name)
   (provide name
            (rename-out [-read read]
                        [-read-syntax read-syntax]
                        [-get-info get-info]))))

