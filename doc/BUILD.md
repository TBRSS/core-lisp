# Core Lisp Build Instructions

Pull requests with instructions for other platforms would be appreciated.

## Building for macOS

This section describes how to build Core Lisp for the macOS platform.
Core Lisp is built using ASDF, which is utterly alien outside the Common Lisp community.
On the other hand, it's not actually that difficult to use.

This section was tested on the following:

- macOS 10.14
- sbcl 1.4.14

I also used Homebrew and quicklisp.
The procedure is as follows:

- If you're thinking of programming on macOS you should have installed Homebrew already, but if not go [here](https://brew.sh/).
- Install the "sbcl" package from Homebrew.
- Install [QuickLisp](https://www.quicklisp.org/beta/).
- Install Core Lisp's dependencies. From its ASDF file you can see that you need at least "vernacular", "global-vars", "alexandria" and "named-readtables".
- `git clone` Core Lisp into ~/common-lisp/core-lisp.
- In that directory, run "sbcl".
- `(asdf:load-system :core-lisp)`
- `(sb-ext:save-lisp-and-die "islisp" :executable t :save-runtime-options t)`
- Once back at the shell, move islisp somewhere on your path like *~/bin*.
