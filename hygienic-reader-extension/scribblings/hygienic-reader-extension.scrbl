#lang scribble/manual

@(require (for-label racket/base
                     racket/contract/base
                     hygienic-reader-extension/extend-reader
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

