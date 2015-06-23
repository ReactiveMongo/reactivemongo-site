---
layout: default
title: ReactiveMongo 0.11.0 - Release details
---

## ReactiveMongo 0.11.0 – Release details

This is a minor release including mostly bugfixes and some enhancements.

### What's new?

Enhancements:

- New APIs, for the commands and [streaming](tutorial/consume-streams.html)
- Compatibility with MongoDB 3
- [SSL support](tutorial/setup.md)
- Builtin micro-DSL for BSON
- Convenient operations on a collection (`.count`, `.runCommand`)

### Documentation

The [documentation](index.html) is also available and deprecates the old wiki. And of course, you can browse the [Scaladoc](../api/index.html).

### Stats

Here is the list of the commits included in this release (since 0.10, the top commit is the most recent one):

~~~
$ git shortlog -s -n refs/tags/v0.10.0..0.11.0-M1
    77  Stephane Godbillon
    49  Cédric Chantepie
     5  Andrey Neverov
     4  Reid Spencer
     4  lucasrpb
     3  Shunsuke Kirino
     3  Faissal Boutaounte
     2  杨博 (Yang Bo)
     2  Alois Cochard
     2  Nikolay Sokolov
     2  Olivier Samyn
     2  Viktor Taranenko
     1  Maksim Gurtovenko
     1  pavel.glushchenko
     1  Paulo "JCranky" Siqueira
     1  Fehmi Can Saglam
     1  Shirish Padalkar
     1  Dmitry Mikhaylov
     1  David Liman
     1  Age Mooij
     1  Vincent Debergue
     1  Daniel Armak
     1  Jaap Taal
     1  Jacek Laskowski
     1  Andrea Lattuada
~~~
