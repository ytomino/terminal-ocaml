terminal library for Objective-Caml
===================================

What's this?
------------

Objective-Caml library to manipulate a terminal.
This supports Windows and POSIX.

Prerequisites
-------------

OCaml >= 4.08
 https://ocaml.org/

How to make
-----------

Install
+++++++

::

 make install PREFIX=/usr/local

Specify your preferred directory to ``PREFIX``.
The libraries would be installed into ``$PREFIX/lib/ocaml`` (default is
``ocamlc -where``).

Uninstall
+++++++++

::

 make uninstall PREFIX=/usr/local

Build examples
++++++++++++++

::

 make -C examples

Note about view port
--------------------

In Windows, console API has a concept of *screen buffer* and *window*.
*screen buffer* has fixed size.
*Window* may move when an user operates scroll bar(s) or resize a console window.
``Terminal.size`` gets size of the *screen buffer*.
``Terminal.view`` gets range of the *window*.
``Terminal.screen`` creates new *screen buffer*.

In POSIX platform, *screen buffer* and *window* are always same size.
It may be resized when an user resize a terminal window.

::
 
 +- Screen Buffer-+
 |  scrolled text |
 | +- Window ---+ | ...seen from here
 | |visible text| |
 | |C:\>        | |
 | +------------+ | ...seen until here
 +----------------+

License
-------

**license of terminal-ocaml** ::

 Copyright 2012-2021 YT. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 1. Redistributions of source code must retain the above copyright
    notice, this list of conditions and the following disclaimer.
 2. Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in the
    documentation and/or other materials provided with the distribution.
 
 THIS SOFTWARE IS PROVIDED BY THE AUTHOR(S) ``AS IS'' AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 IN NO EVENT SHALL THE AUTHOR(S) BE LIABLE FOR ANY DIRECT, INDIRECT,
 INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
