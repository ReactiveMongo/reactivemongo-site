---
layout: default
major_version: 0.10.5
title: Release details
---

## ReactiveMongo {{page.major_version}} – Release details

This is a minor release including mostly bugfixes and some enhancements.

> The supported MongoDB versions are from 2.4 to 2.6.

### What's new?

1. Two Releases:
    - `0.10.5.0.akka23` (Scala 2.10 and 2.11): compiled against Akka 2.3 and Play-iteratees 2.3
    - `0.10.5.0.akka22` (Scala 2.10 _only_): compiled against Akka 2.2 and Play-iteratees 2.2
2. Enhancements:
    - API: add `MongoConnectionOptions`, support for options in mongodb URIs
    - BSON library: `BSONObjectID` is now a serializable class with a private constructor
    - BSON library: do not rely on exceptions in deserialization when possible
    - Commands: `Eval`
    - BufferCollection: `RawBSONDocumentSerializer`
    - Upgrade to SBT 0.13.5
    - Macros: support for `@Ignore` and `@transient` annotations
3. Bugfixes:
    - BSON library: fix `BSONDateTimeNumberLike` typeclass
    - Cursor: fix exception propagation
    - Commands: fix `ok` deserialization for some cases
    - Commands: fix `CollStatsResult`
    - Commands: fix `AddToSet` in aggregation
    - Core: fix connection leak in some cases
    - GenericCollection: do not ignore `WriteConcern` in `save()`
    - GenericCollection: do not ignore `WriteConcern` in bulk inserts
    - GridFS: fix `uploadDate` deserialization field
    - Indexes: fix parsing for `Ascending` and `Descending`
    - Macros: fix type aliases
    - Macros: allow custom annotations

### Documentation

The [documentation](index.html) is also available and deprecates the old wiki. And of course, you can browse the [Scaladoc](../api/index.html).

### Stats

Here is the list of the commits included in this release (since 0.9, the top commit is the most recent one):

~~~
$ git shortlog -s -n refs/tags/v0.10.0..0.10.5.x.akka23
    39  Stephane Godbillon
     5  Andrey Neverov
     4  lucasrpb
     3  Faissal Boutaounte
     2  杨博 (Yang Bo)
     2  Nikolay Sokolov
     1  David Liman
     1  Maksim Gurtovenko
     1  Age Mooij
     1  Paulo "JCranky" Siqueira
     1  Daniel Armak
     1  Viktor Taranenko
     1  Vincent Debergue
     1  Andrea Lattuada
     1  pavel.glushchenko
     1  Jacek Laskowski
~~~
