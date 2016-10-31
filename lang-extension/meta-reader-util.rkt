#lang racket/base

(provide make-meta-reader/lang-reader
         lang-extension->lang-reader
         lang-reader-module-paths)

(require racket/unit
         (only-in syntax/module-reader make-meta-reader)
         lang-reader/lang-reader
         )

;; make-meta-reader/lang-reader : make-meta-reader-args ... -> Lang-Reader
(define make-meta-reader/lang-reader (compose make-lang-reader make-meta-reader))

(define-syntax-rule (unknown-fn this-name other-name)
  (λ args
    (error 'fn-delay "~s cannot be called within ~s" 'other-name 'this-name)))

;; lang-extension->lang-reader : Symbol Lang-Extension -> Lang-Reader
;; A wrapper around make-meta-reader that deals with Lang-Readers
(define (lang-extension->lang-reader name lang-extension)
  (make-meta-reader/lang-reader
   name
   "language path"
   lang-reader-module-paths
   (λ (old-read)
     (define/lang-reader [-read -read-syntax -get-info]
       (lang-extension (make-lang-reader old-read
                                         (unknown-fn 'read 'read-syntax)
                                         (unknown-fn 'read 'get-info))))
     -read)
   (λ (old-read-syntax)
     (define/lang-reader [-read -read-syntax -get-info]
       (lang-extension (make-lang-reader (unknown-fn 'read-syntax 'read)
                                         old-read-syntax
                                         (unknown-fn 'read-syntax 'get-info))))
     -read-syntax)
   (λ (old-get-info)
     (define/lang-reader [-read -read-syntax -get-info]
       (lang-extension (make-lang-reader (unknown-fn 'get-info 'read)
                                         (unknown-fn 'get-info 'read-syntax)
                                         old-get-info)))
     -get-info)))

;; From at-exp/lang/reader.rkt
;; https://github.com/racket/racket/blob/master/pkgs/at-exp-lib/at-exp/lang/reader.rkt#L19

;; lang-reader-module-paths : Byte-String -> (U False (Vectorof Module-Path))
;; To be used as the third argument to make-meta-reader from syntax/module-reader.
;; On success, returns a vector of module paths, one of which should point to the
;; reader module for the #lang bstr language.
(define (lang-reader-module-paths bstr)
  (let* ([str (bytes->string/latin-1 bstr)]
         [sym (string->symbol str)])
    (and (module-path? sym)
         (vector
          ;; try submod first:
          `(submod ,sym reader)
          ;; fall back to /lang/reader:
          (string->symbol (string-append str "/lang/reader"))))))

