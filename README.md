hygienic-reader-extension [![Build Status](https://travis-ci.org/AlexKnauth/hygienic-reader-extension.png?branch=master)](https://travis-ci.org/AlexKnauth/hygienic-reader-extension)
===
A racket library for adding hygiene to reader extensions

documentation: http://docs.racket-lang.org/hygienic-reader-extension/index.html

```racket
(extend-reader reader-proc extend-readtable)  →  (-> A ... Any)
  reader-proc      : (-> A ... Any)
  extend-readtable : (-> Readtable #:outer-scope (-> Syntax Syntax) Readtable)
```
Extends the given `reader-proc` by making a function that calls it
with the `current-readtable` parameter extended with `extend-readtable`.

In addition to a readtable, it passes an `outer-scope` argument to the
`extend-readtable` function, which that function can pass into the
readtable procedures it adds. Those readtable procedures should use
the `hygienic-app` function to transform any input syntax objects into
the output syntax. 

```racket
(hygienic-app proc stx #:outer-scope outer-scope)  →  Syntax
  proc        : (-> Syntax Syntax)
  stx         : Syntax
  outer-scope : (-> Syntax Syntax)
```
Applies `proc` to `stx`, but with extra scopes added to the input and
output to make it hygienic.

This is meant to be used within a readtable-proc added using the
`extend-reader` function, and the `outer-scope` argument should come
from the `outer-scope` argument passed to the `extend-readtable`
argument to that function.
