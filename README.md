# org-diary

This package allows you to maintain a simple diary, or work-log, using the
power of `org-mode`.

The package implements a derived mode of `org-mode`, so you can may use all
the standard org-mode facilities you're used to.

This package was built after previously hosting a lot of emacs lisp inline
within a Diary.org file, as visible in this demonstration repository:

* [https://github.com/skx/org-worklog](https://github.com/skx/org-worklog)



## Overview

This is designed for people who wish to maintain a single-file journal,
be it for a work-log, or private entries.  The journal will contain a new
entry for every day based upon a standard template.

Every time you create a new entry the same template will be appended to
the foot of your document, and there is some minimal facilities for jumping
to today's entry and running customizations.

In short there is:

* The ability to insert a new per-day templated entry.
  * We assume you have some standard activities/actions you wish to complete every day.
* The ability to jump to today's entry.
  * Which is nothing more than a heading with today's date.

When exported any subsections that are empty are automatically removed.



## Installation / Usage

Save the file `org-diary.el` to a directory upon your load-path, then
require it:

```lisp
(require 'org-diary)
```

After that visiting a file named `Diary.org` will automatically load the mode.

You'll need to create a template-entry which will be inserted whenever you run `M-x org-diary-new-entry`, see the example below for details.  Within the file anything between the two markers `* DD/MM/YYYY` and `* END` will be taken to be the template.

You can see that in the example below.



## Example

There is an example [Diary.org](Diary.org) file contained within this
repository which demonstrates how things can be used.



## Customizations

If you prefer to use a different date-format for your entries change the value of `org-diary-date-format`.

There are hooks available at various points:

* `org-diary-mode-hook`
  * Called when entering the mode.
* `org-diary-after-new-entry-hook`
  * Called after a new entry is inserted.
* `org-diary-after-today-hook`
  * Called after you jump to today's entry.

Perhaps you might wish to add a tag with the current week-number when entering a new entry?  You could do that like so:

```lisp
;; Add a new tag to all entries, after creating them.
(add-hook 'org-diary-after-new-entry-hook
          (lambda()
            (org-set-tags (format-time-string "%Y_week_%V"))))
```



## Alternatives

This repository was archived as I realized there are really two parts to the code:

* Adding a new entry.
* Opening the diary.org file, and jumping to "today".

The first can be achieved with an org-capture template:

```
    ;; Worklog
    (setq org-capture-templates
        (append org-capture-templates
          '(("w" "Worklog entry" entry
             (file+headline "~/Private/Worklog/Diary.org" "Diary")
         "** %<%d/%m/%Y>    :%<%Y>_week_%<%V>:
*** Meetings
**** Daily                                               :daily:
<%<%Y-%m-%d %a 10:00-10:15>>
- https://gitlab.ci.example/groups/private/project/-/boards/457
\n"
      :empty-lines 1
      :immediate-finish t
      :jump-to-captured t))))

```

The second via a simple wrapper:

```
(defun skx-load-diary ()
  "Load my diary/work-log, and jump to today's entry.

If the buffer was already loaded then leave the folding alone, otherwise
attempt to be pretty by showing the structure."
  (interactive)
  (let* ((file (expand-file-name "~/Private/Worklog/Diary.org"))
         (buf  (get-file-buffer file))
         (already-open (buffer-live-p buf)))
    (find-file file)
    (unless already-open
      ;; Only run this the first time the file is opened
      (outline-show-all)
      (outline-hide-sublevels 4))
    (goto-char (point-min))
    (re-search-forward (concat "^\\*+ " (format-time-string "%d/%m/%Y")) nil t)))
```



## Bugs?

Please report them as issues.
