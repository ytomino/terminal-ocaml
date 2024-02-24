terminal library for Objective-Caml
===================================

What's this?
------------

Objective-Caml library to manipulate a terminal.
This supports Windows and POSIX.

Prerequisites
-------------

OCaml >= 4.11
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
