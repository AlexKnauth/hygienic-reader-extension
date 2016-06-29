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

(define-syntax-rule (?set! x v)
  (unless x (set! x v)))

(define-syntax-rule (fn-delay f-expr)
  (λ args
    (let ([f f-expr])
      (unless f (error 'fn-delay "~s hasn't been initialized" 'f-expr))
      (apply f args))))

;; lang-extension->lang-reader : Symbol Lang-Extension -> Lang-Reader
;; A wrapper around make-meta-reader that deals with Lang-Readers
(define (lang-extension->lang-reader name lang-extension)
  (define ?read #f)
  (define ?read-syntax #f)
  (define ?get-info #f)
  (define delayed-read (fn-delay -read))
  (define delayed-read-syntax (fn-delay -read-syntax))
  (define delayed-get-info (fn-delay -get-info))
  (define result
    (make-meta-reader/lang-reader
     name
     "language path"
     lang-reader-module-paths
     (λ (old-read) (?set! ?read old-read) delayed-read)
     (λ (old-read-syntax) (?set! ?read-syntax old-read-syntax) delayed-read-syntax)
     (λ (old-get-info) (?set! ?get-info old-get-info) delayed-get-info)))
  (define/lang-reader [-read -read-syntax -get-info]
    (lang-extension (make-lang-reader (fn-delay ?read) (fn-delay ?read-syntax) (fn-delay ?get-info))))
  result)

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

