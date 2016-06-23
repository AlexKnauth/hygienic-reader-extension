#lang scribble/manual

@(require (for-label racket/base
                     racket/contract/base
                     hygienic-reader-extension/extend-reader
                     (only-in syntax/module-reader make-meta-reader)
                     ))

@title{Making reader extensions hygienic}

source code: @url{https://github.com/AlexKnauth/hygienic-reader-extension}

@defmodule[hygienic-reader-extension/extend-reader]

@defproc[(extend-reader
          [reader-proc (-> A ... any/c)]
          [extend-readtable (-> readtable? #:outer-scope (-> syntax? syntax?) readtable?)])
         (-> A ... any/c)]{
Extends the given @racket[reader-proc] by making a function that calls
it with the @racket[current-readtable] parameter extended with the
result of calling @racket[extend-readtable] function.

In addition to a readtable, it passes an @racket[outer-scope] argument
to the @racket[extend-readtable] function, which that function can
pass into the readtable procedures it adds. Those readtable procedures
should use the @racket[hygienic-app] function to transform any input
syntax objects into the output syntax object.
}

@defproc[(hygienic-app [proc (-> syntax? syntax?)]
                       [stx syntax?]
                       [#:outer-scope outer-scope (-> syntax? syntax?)])
         syntax?]{
Applies @racket[proc] to @racket[stx], but with extra scopes added to
the input and output to make it hygienic.

This is meant to be used within a readtable procedure added by the
@racket[extend-readtable] argument to the @racket[extend-reader]
function. The @racket[outer-scope] argument should come from the
@racket[outer-scope] argument passed to that @racket[extend-readtable]
function.
}

@section{Example: a hygienic version of quote}

To make a hygienic version of the quote reader macro, the core
problem-specific functionality is implemented by this function:

@codeblock[#:keep-lang-line? #false]{
#lang racket
;; add-quote : (-> Syntax Syntax)
(define (add-quote stx)
  #`(quote #,stx))
}

But to make it into a lang-extension, we need to use
@racket[make-meta-reader] from @racketmodname[syntax/module-reader].
A basic template for a lang-extension implemented this way is this,
in a file with the path of the language directory plus
@racketvalfont{/lang/reader.rkt}.

@codeblock{
#lang racket

(provide (rename-out [-read read] [-read-syntax read-syntax] [-get-info get-info]))

(require syntax/module-reader
         lang-extension/meta-reader-util)

;; wrap-reader : (-> (-> A ... Any) (-> A ... Any))
(define (wrap-reader reader-proc)
  ....)

(define-values [-read -read-syntax -get-info]
  (make-meta-reader
   'hygienic-quote
   "language path"
   lang-reader-module-paths
   wrap-reader ; for read
   wrap-reader ; for read-syntax
   identity))  ; for get-info
}

To implement @racket[wrap-reader], we can use the @racket[extend-reader]
function from @racketmodname[hygienic-reader-extension/extend-reader].
To use it we need to define an @racket[extend-readtable] function to
pass as the second argument.

@codeblock[#:keep-lang-line? #false]{
#lang racket
(require syntax/module-reader
         lang-extension/meta-reader-util
         hygienic-reader-extension/extend-reader)

;; wrap-reader : (-> (-> A ... Any) (-> A ... Any))
(define (wrap-reader reader-proc)
  (extend-reader reader-proc extend-readtable))

;; extend-readtable : (-> Readtable #:outer-scope (-> Syntax Syntax) Readtable)
(define (extend-readtable rt #:outer-scope outer-scope)
  (make-readtable rt
    #\' 'terminating-macro quote-proc))

;; quote-proc : Readtable-Proc
(define (quote-proc c in src ln col pos)
  ....)
}

For an unhygienic version, the @racket[....] here could be filled in
with @racket[(add-quote (read-syntax/recursive src in))]:

@codeblock[#:keep-lang-line? #false]{
#lang racket
;; add-quote : (-> Syntax Syntax)
(define (add-quote stx)
  #`(quote #,stx))

;; extend-readtable : (-> Readtable #:outer-scope (-> Syntax Syntax) Readtable)
(define (extend-readtable rt #:outer-scope outer-scope)
  (make-readtable rt
    #\' 'terminating-macro quote-proc))

;; quote-proc : Readtable-Proc
(define (quote-proc c in src ln col pos)
  (add-quote (read-syntax/recursive src in)))
}

However, to make it hygienic, we need to use the @racket[hygienic-app]
function when applying @racket[add-quote] to the input.

@codeblock[#:keep-lang-line? #false]{
#lang racket
;; add-quote : (-> Syntax Syntax)
(define (add-quote stx)
  #`(quote #,stx))

;; extend-readtable : (-> Readtable #:outer-scope (-> Syntax Syntax) Readtable)
(define (extend-readtable rt #:outer-scope outer-scope)
  (make-readtable rt
    #\' 'terminating-macro quote-proc))

;; quote-proc : Readtable-Proc
(define (quote-proc c in src ln col pos)
  (hygienic-app add-quote (read-syntax/recursive src in)
                #:outer-scope ....))
}

But then what about the @racket[#:outer-scope] argument? We need to
pass in the @racket[outer-scope] that we got from
@racket[extend-readtable], somehow, but it needs to go through
@racket[quote-proc]. So instead of @racket[quote-proc] directly being
a @racketcommentfont{Readtable-Proc}, we can make it a function that
produces one. Then we can have it pass the @racket[outer-scope] along.

@codeblock[#:keep-lang-line? #false]{
#lang racket
;; add-quote : (-> Syntax Syntax)
(define (add-quote stx)
  #`(quote #,stx))

;; extend-readtable : (-> Readtable #:outer-scope (-> Syntax Syntax) Readtable)
(define (extend-readtable rt #:outer-scope outer-scope)
  (make-readtable rt
    #\' 'terminating-macro (quote-proc outer-scope)))

;; quote-proc : (-> (-> Syntax Syntax) Readtable-Proc)
(define ((quote-proc outer-scope) c in src ln col pos)
  (hygienic-app add-quote (read-syntax/recursive src in)
                #:outer-scope outer-scope))
}

And we're done! The whole file is this:

@codeblock{
#lang racket

(provide (rename-out [-read read] [-read-syntax read-syntax] [-get-info get-info]))

(require syntax/module-reader
         lang-extension/meta-reader-util
         hygienic-reader-extension/extend-reader)

;; wrap-reader : (-> (-> A ... Any) (-> A ... Any))
(define (wrap-reader reader-proc)
  (extend-reader reader-proc extend-readtable))

(define-values [-read -read-syntax -get-info]
  (make-meta-reader
   'hygienic-quote
   "language path"
   lang-reader-module-paths
   wrap-reader ; for read
   wrap-reader ; for read-syntax
   identity))  ; for get-info

;; add-quote : (-> Syntax Syntax)
(define (add-quote stx)
  #`(quote #,stx))

;; extend-readtable : (-> Readtable #:outer-scope (-> Syntax Syntax) Readtable)
(define (extend-readtable rt #:outer-scope outer-scope)
  (make-readtable rt
    #\' 'terminating-macro (quote-proc outer-scope)))

;; quote-proc : (-> (-> Syntax Syntax) Readtable-Proc)
(define ((quote-proc outer-scope) c in src ln col pos)
  (hygienic-app add-quote (read-syntax/recursive src in)
                #:outer-scope outer-scope))
}

It's hygienic because in a file like this:

@codeblock{
#lang hygienic-reader-extension/tests/hygienic-quote racket

'3                   ; this produces 3, of course
(define (quote x) 5) ; just defining a function, no big deal
(quote 3)            ; this is 5. It's just calling the function
'3                   ; still 3

;; this shouldn't conflict with the earlier definition of quote
(define 'foo 6) ; (define (quote foo) 6), sort of
'3              ; and still 3, because that quote does not bind this one
(quote 3)       ; still 5, because this still refers to the function
}

