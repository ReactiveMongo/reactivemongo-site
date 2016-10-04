---
layout: default
major_version: 0.11
title: Release details
---

## ReactiveMongo {{site._0_11_latest_minor}} – Release details

**What's new?**

Enhancements:

- New APIs, for the [commands](advanced-topics/commands.html) and [streaming](tutorial/consume-streams.html)
- Compatibility with MongoDB 3.2
- [SSL support](tutorial/connect-database.html)
- Built-in micro-DSL for BSON
- Convenient operations on a collection (`.count`, `.runCommand`)

There is also a new version of the [Play Framework plugin](tutorial/play2.html).

> MongoDB versions older than 2.6 are not longer supported by ReactiveMongo.

### Documentation

The documentation is available [online](index.html). You can also browse the [Scaladoc](../api/index.html).

### Migration notes

The package `reactivemongo.api.collections.default` has been refactored as the package [`reactivemongo.api.collections.bson`](http://reactivemongo.org/releases/0.11/api/index.html#reactivemongo.api.collections.bson.package).
If you get a compilation error like the following one, you need to update the corresponding imports.

    object default is not a member of package reactivemongo.api.collections
    [error] import reactivemongo.api.collections.default.BSONCollection

The **`.save`** operation on a BSON collection has been removed, and must be replaced by `.update(selectorDoc, updateDoc, upsert = true)`. This is to make the ReactiveMongo API more coherent, and benefit from the upsert semantic of the MongoDB update command.

{% highlight text %}
No Json serializer as JsObject found for type play.api.libs.json.JsObject.
Try to implement an implicit OWrites or OFormat for this type.
{% endhighlight %}

When using the **[support for Play JSON](json/overview.html)**, if the previous error occurs, it necessary to make sure `import reactivemongo.play.json._` is used, to import default BSON/JSON conversions.

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
