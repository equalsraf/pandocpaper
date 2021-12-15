---
title: The things I do to avoid backslashes
author:
- name: Regulus Aquilius Flavius
  href: https://raf.zyks.org
keywords: [Publishing, LaTeX, markdown]
date: 7 December 2021
abstract: |
  LaTeX was my primary academic tool for a number of years. Recent challenge to its use are the need for web publication, and easier adoption through the use of micro markup formats. I am no exception and have used markdown as a format for some of my text, but LaTeX was still the entry point for generators. In this paper we take a quick glance at the tools we use when using pandoc.
bibliography: references.bib
---

# Introduction

In this paper we will go over requirements for document formats in academia.
I will also briefly describe some of the related formats in this field.
This is heavily biased by my own use cases, so take it for what it is.

## Requirements

Multiple final output formats, Postscript, PDF, HTML, EPUB.
PDF is the most common final output format for papers online, however there is also a need for html or epub as reflowable format for other mediums.
Postscript is still seen as an intermediate format used between the authors and the publishers, primarily to facilitate final style edits by the publisher.

Complex mathematical equations are one of the flagship features of TeX and LaTeX.
Its two main characteristics are:

1. output quality is second to none
1. math is inserted as a small language which is faster to edit than typical UIs for math equations (once you learn it)

The other prevalent feature in academic text are references, such as cross references to images, sections and equations. 
But more importantly bibliographic references that take in a database of publications, format it according to a specification and enable inline citation or the creation of a bibliography index.

Finally ease of adoption for authors, is the last requirement.
In this regard LaTeX is hardly easy, but most authors can survive with minimal knowledge of its internals.
If templates are already available, the author can insert his metadata in the proper places and text and figures to generate the final paper.

## Formats

First lets have a look at different formats out there that are involved in writing documents (Figure @fig:diagram).

![Relation between different formats](diagram){#fig:diagram}


**Troff** and **TeX** are language for typographic output of complex text, such as mathematics.
They can produce high quality output formats such as dvi, postscript or pdf.
**TeX** has a slight advantage in the quality of its math output.

**LaTeX** Is a set of macros (that produce **TeX** output), with support for different document classes that abstract the content from the output. For example the article class allows the user to specify an abstract or bibliography without having to worry about the layout of this content in the page. Academic conferences often provide their own *LaTeX* template that enforces the intended format.

**MS** is a series a macros on top of troff, these can be considered equivalent to LaTeX.

DOCX (Microsoft Word) is a What You See is What You Get program for producing documents.
Some publishers do accept submissions in this format.

**Markdown** is a micro markup format, designed for fast formatted input in web pages.
The original specification is restricted the elements seen in HTML, such as titles, text emphasis and links
However further extensions add support for tables, bibliography and other requirements for academic texts.
The most common output format for markdown text is likely **HTML**, but tools such as **Pandoc** support conversion into multiple formats.

Some of these are pretty old and but you might now have heard of troff before.
Interestingly, IEEE still lists **Troff** as one of its preferred formats for submission, but I was unable to find any templates, and likewise you can find mentions of troff begin used for IETF RFCs [@usingtroff].

As seen in the figure, we are abstracting away details from the user, by turning these formats from user input languages to intermediate languages.
For example the author is not concerned with the details of page layout so TeX is never used directly, instead LaTeX is used to define the structure of the document and the text or figures.
Likewise we are assuming markdown (or some of its extensions) are the right abstraction for authors.

In the figure, conversion to html is marked in red, because automated conversion often runs into issues.
Likewise conversion from markdown to *ms* is also limited (using pandoc).

Markdown itself does not provide a solution to express metadata (such as authors, titles, subtitles), tables, math, or references.
In this paper I will consider the pandoc extended markdown which:

- supports tables
- supports metadata, stored in a preamble header or a separate file
- supports math using the same input language as latex (with limitations)
- exports latex and other formats via templates and/or filters


# A pandoc workflow{#sec:workflow}

In this section I will describe my current setup.
The whole process is driven by a Makefile that calls pandoc and other tools to generate the final document.
This process depends not only on pandoc [@pandoc], but also on pandoc-xnos [@xnos] for the internal citations.

The input is a markdown entry file (passed via *INPUT\_FILE*).
In addition you can add bibliographic references from a bibtex file, as long as you mention it in your header metadata.

The outputs of this makefile are files in the *out/pdf* or *out/html* folders.
Within these folders you will find temporary files created during the compilation, and the final output named *document.ext*.

The usual starting point is to call make like this,

```shell
$ make INPUT_FILE=paper.md DRAFT=1
```

The following subsections detail the make targets.

## make pdf

Creates the pdf file (using TeX).
This is based on a template stored in *templates/template.tex*.

## make html

Creates the html file.
This is based on a template stored in *templates/template.html*, and a matching css file.

## make epub

This is a bit of a work in progress.
It takes the html file generated by the html rule and converts this to an epub using calibre [@ebookconvert] from the already existing HTML file.

## make tex{#sec:maketex}

This target outputs the TeX content used to generate the pdf

## make watch

This target continously rebuilds the pdf whenever one of the files in the source folder changes.

## Pattern rulles

I have pattern rules for auto generating pdf and svg versions of figures from several formats (graphviz, blockdiag).
This process is not optimal, it makes the final pdf file depend on all existing diagrams which may or may not be true.
For html we use svg instead of pdf.

# Example

This section is just an example of how the output is turning out.

## Math

You can have inline math such as $E=mc^2$, but also block equations such as

$$
\sqrt{x^2+1}
$${#eq:sq}

The later equation can be referenced by a number (in this case Equation @eq:sq).

## Cross references

The syntax for this is to add a label after the math block, e.g.

```markdown
$$
\sqrt{x^2+1}
$${#eq:sq}
```

However the actual reference is done as with an @ sign,

```markdown
... in equation @eq:sq
```

References to figures are similar but use the *fig:* prefix.
And likewise the labels are placed after the figure

```markdown
![Alt text](file){#fig:diagram}
```


## Bibliographic references

Bibliographic references, such as [@pandoc] are different, and are added as follows:

```markdown
[@citationkey]
```

The key is the same key used in the bibtex file.
You can specify the bibtex file as part of the header metadata

```markdown
---
...
bibliography: references.bib
---
```

# Discussion

Here is some food for thought about the negative side of all this.

## Bloat

*Bloat* is a pretty generic term - but when it comes to editing tools I assume it is related to the size (bytes) the system takes over in your disk, and with the user facing complexity.

Latex is sometimes accused of being bloated, while at the same time being extremely multifaceted - there is a package for everything and popular distributions include lots of packages.
Texlive (a popular Latex distribution) is available in a DVD, and is larger than some operating system installation disks.

Two tricks can be employed to save space in Texlive: avoid installing packages you don't need, and skip installing documentation files.
To skip the instalation of the documentation in new packages, use *tlmgr option docfiles 0*.
If the packages are already installed, the documentation files can be removed from texmf-dist/doc/.

To avoid the larger packages start with a small TexLive scheme: scheme-basic.
The current size of my installation is 200 Megabytes, and is
enough to generate a IEEE paper.

Pandoc is usually built as a single static binary.
The size of this binary in my system is 158 Megabytes, an additional filter increases this further by 14 Megabytes.
The reason for this size is that pandoc supports a large array of input and output formats that go beyond markdown and LaTeX, however there is no way to separate this functionality.

GNU troff is the smallest of the systems we looked at.
The installed size for GNU troff is 11 Megabytes, however this does not include the size of the standard c++ library or other dynamically linked dependencies.

Finally depencies add to this size, pandoc requires an installed version of LaTeX to generate PDF, and some pandoc filters require python.

## Troubleshooting complexity

With the increase in complexity comes increased difficulty in troubleshooting issues.
It is all good and well if you have no issues.
But if you run into a problem you now have to troubleshoot over multiple languages:

1. pandoc's flavour of markdown
1. pandoc's templating engine
1. latex
1. output formats (html, pdf, etc)

Some inner workings of pandoc help with this task. The **fail-if-warning** option causes pandoc to fail on warnings.
And it is possible to generate the intermediate TeX output when we run into problems (Section @sec:maketex).

A word of warning when using a custom LaTeX template, pandoc generates a significant amount of new environment definitions.
When upgrading pandoc you may find that you template no longer works becaus pandoc is not generating the same LaTeX as before.
In such cases it is useful to investigate the default pandoc templates, available via *pandoc -D=latex*.

From my perspective I don't think this setup is easier, since I still have to understand LaTeX internals to handle troubleshooting, and I had to write the LaTex/HTML templates anyway.

## Bibliographic references

Bibliographic references do not rely on LaTeX, even when generating a PDF.
The citeproc option from pandoc, causes it to generate its own references and representation.
This means that references always show up at the end of the document, it is up to you to add a title at the end.

I have not gone further into bibliographic references - I am aware pandoc has additional options (e.g. for biblatex) but those only make sense if you are only generating LaTeX.

Currently I am using a CSL file which is supposed to format references according to IEEE rules, but it does have a string margin space between the reference number and the title.

## Math in HTML

Pandoc supports the use LaTeX math blocks directly as part of the document.
As such convertion to LaTeX is trivial, however conversion to HTML is a challenge.

My favorite approach is to use Gladtex [@gladtex], which converts LaTeX formulas to SVG.
Internally this works as a filter that inspects the pandoc AST, generates svg files for the formulas (via TeX) and replaces the entries in the AST with images.
My only issue with this is that pandoc expects to call this script with a single argument and the script itself does not accept this, so I am using a wrapper script.

## Figure dimensions

There is no pandoc support for specifying image widths.
In HTML I use a CSS declaration to set the maximum image width to 100%, in case they are wider than the page width.
Likewise in the LaTeX template I force the image width to the columnwidth:

```latex
\setkeys{Gin}{width=\columnwidth}
```

however this is not equivalent to the HTML version and I do have to exercise some discipline when designing diagrams to align to this.

## Level 1 headers in HTML

Pandoc uses HTML H1 tags for the first level headers and for the main title.
Naturally the main title would have to be an H1 tag, and since I also use a single hash when writing my titles then all sections are using H1 titles.
Changing the input would not work either, since it would cause the table of contents to list sections as *0.x*.

This is a known limitation of pandoc [@pandoc5071], and is a problem for html accessibility.

# Conclusions

Yes I just added another level of indirection to my life [@rfc1925].
Sadly I don't think this will be replacing LaTeX for publishing academic papers for me, mainly due to the bibliographic issues.

It does seem to work well enough for daily stuff, but I am missing some of the more fancy tricks seen in LaTeX such as tikz/xy.
Although I can add them via some additional Makefile tricks, since TeX is as capable of generating a diagram as graphviz.

You can find the source for this at [this git repo](https://github.com/equalsraf/pandocpaper).


# References

