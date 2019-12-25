# Core Lisp Quick Start Tutorial

These instructions are written from the perspective of someone who
knows very little Common Lisp, and is just interested in getting a
fast ISLisp processor running.

1. Consult [[BUILD]] on how to compile Core Lisp. Then, after
   compiling, return here.

It is assumed that you have a source file similar to the following:

```lisp
#lang core-lisp
;; system.lsp
(defun foo ()
    1)

(defun bar ()
    2)
(:export #'foo #'bar)
```

Note that the first and last lines are critical.

2. Run `islisp`.

3. `(core-lisp:import m :from "/Full/path/to/system.lsp" :binding (#'foo #'bar))`.

4. `(foo)` should evaluate to "1".

## Suggestions

I'm still figuring this out,
but my impression is that ISLisp is intended to be used in a slightly less dynamic way than Common Lisp.
There is still dynamic typing,
but otherwise the language may be best processed by whole-program compilation.
The absence of packages is notable.

Given this, I'm using an old-fashioned UNIX Makefile like the following:

```make
.POSIX:
.DELETE_ON_ERROR:
system.lsp: file1.lsp file2.lsp file3.lsp
         cat $^ > $@
```
