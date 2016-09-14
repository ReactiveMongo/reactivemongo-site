---
layout: default
major_version: "0.10"
title: Release details
---

## ReactiveMongo {{page.major_version}} – Release details

### What's new?

1. [Support for Read Preferences](advanced-topics/read-preferences.html)
2. Macros enhancements (including [support for customizable field names](https://github.com/ReactiveMongo/ReactiveMongo/pull/140))
3. [Connection by URI](tutorial/connect-database.html#connect-using-mongodb-uri)
4. Cursor refactoring
5. Authentication reliabilty improvements
6. Internals refactoring (especially nodeset, actors)
7. Update to Akka 2.2 and Play-Iteratees 2.2
8. Migration to SBT 0.13.1
9. … and many bugfixes :)

> The supported MongoDB versions are from 2.4 to 2.6.

### Documentation

The [documentation](index.html) is also available and deprecates the old wiki. And of course, you can browse the [Scaladoc](../api/index.html).

### Stats

Here is the list of the commits included in this release (since 0.9, the top commit is the most recent one):

~~~
git shortlog -s -n refs/tags/0.9..v0.10.0
    70  Stephane Godbillon
     7  Andraz Bajt
     4  Arthur Gautier
     4  Ivan Mikushin
     3  Thibault Duplessis
     3  Eugene Platonov
     3  Adrien Aubel
     2  Mark van der Tol
     2  Andy Scott
     1  dberg
     1  MarkvanderTol
     1  Jeffrey Ling
     1  Craig McIntosh
     1  Tom McNulty
     1  Valerian
     1  Wojciech Jurczyk
     1  akkie
     1  andy
     1  Jérôme BENOIS
~~~
