# org-diary

This package allows you to maintain a simple diary, or work-log, using the
power of `org-mode`.

The package implements a derived mode of `org-mode`, so you can may use all
the standard org-mode facilities you're used to.



## Overview

The idea is that you load `Diary.org` and automatically receive a couple
of common features:

* The ability to jump to today's entry
  * Which is nothing more than a heading with today's date.
* The ability to insert a templated entry.
  * The idea being you have a standard template for each entry.

When exported any subsections that are empty are automatically removed.


## Installation / Usage

Save the file `org-diary.el` to a directory upon your load-path, then
require it:

```lisp
(require 'org-diary)
```

After that visiting a file named `Diary.org` will automatically load the mode.

You'll need to create a template-entry which will be inserted whenever you run `M-x org-diary-new-entry`, see the example below for details.


## Example

There is an example [Diary.org](Diary.org) file contained within this
repository which demonstrates how things can be used.


## Bugs?

Please report them as issues.
