---
layout: default
major_version: 0.9
title: Release Notes
sitemap: false
---

## ReactiveMongo {{page.major_version}}

This version includes a refactoring of the code base and provides some nice new features :-)

Note that, while we are stabilizing the API, some changes may occur between this version and the next in order to provide a more consistent experience.

Here are a quick view of the 0.8⇒0.9 changes:

### 1. BSON library

{% highlight scala %}
// 0.8
val doc = BSONDocument(
  "name" -> BSONString("Foo"),
  "age" -> BSONInteger(22),
  "coll" -> BSONArray(
    BSONString("foo"),
    BSONString("bar"),
    BSONString("baz")
  ),
  "pet" -> BSONDocument(
    "name" -> BSONString("rox"),
    "race" -> BSONString("dog")
  )
)

doc.getAs[BSONString]("name") // returns Some(BSONString("Foo"))
doc.getAs[BSONInteger]("age") // returns Some(BSONInteger(22))

// 0.9
BSONDocument(
  "name" -> "Foo",
  "age" -> 22,
  "coll" -> Seq(
    "foo",
    "bar",
    "baz"
  ),
  "pet" -> BSONDocument(
    "name" -> "rox",
    "race" -> "dog"
  )
)

doc.getAs[String]("name") // returns Some("Foo")
doc.getAs[Integer]("age") // returns Some(22)
{% endhighlight %}


### 2. Collections have been refactored and greatly improved

We changed the global architecture in order to separate the MongoDB's “collection” concept and the API to use them.

It is now possible (and relatively easy) to implement your own Collection, and then create an abstraction layer without requiring an ORM.

#### Smooth integration of the query builder

The `QueryBuilder` and the Collection have been merged the resulting new Collection API is far more friendly.

The types of query and result are now specified in different places, allowing of specify only one of them.

Example of a basic query:

{% highlight scala %}
// 0.8
collection.find[BSONDocument, User](BSONDocument("name" -> BSONString("foo")))

// 0.9
collection.find(BSONDocument("name" -> "foo")).cursor[User]
{% endhighlight %}

The same one, with sorting:

{% highlight scala %}
// 0.8
collection.find[User](QueryBuilder(BSONDocument("name" -> BSONString("foo"))).sort(BSONDocument("age" -> BSONInteger(1)))

// 0.9
collection.find(BSONDocument("name" -> "foo"))
          .sort(BSONDocument("age" -> 1))
          .cursor[User]
{% endhighlight %}

#### Specialized collections

Collections can now be specialized to support other structures than BSON and their own Readers/Writers typeclasses. This job can be done by extending the `GenericCollection` and `GenericQueryBuilder` traits in the `reactivemongo.api.collections` package.

The default collection implementation is a specialized collection that uses the shipped-in BSON library, with `BSONDocumentWriter` and `BSONDocumentReader` as de/serialization typeclasses.

The idea is to make integration with third party libraries (like other BSON libraries, JSON libraries, etc.) easier. There is an example of such a specialized collection in the Play Framework plugin, using the Play JSON library.

{% highlight scala %}
// example using JSON-specialized collection in the PlayFramework plugin
case class User(name: String, age: Int)
implicit val formatter = User.format[User]
coll = db.collection[JsObject]("users")
coll.find(BSONDocument("name" -> "foo")).cursor[User]
{% endhighlight %}

#### BSON Macros

You can now use Macros to generate your `BSONDocumentReader`s and `BSONDocumentWriter`s at compile-time.

{% highlight scala %}
case class Person(firstName: String, lastName: String)
implicit val personFormat = Macros.handler[Person]
collection.insert(Person("Jack", "London"))
collection.find(BSONDocument("firstName" -> "Jack")).cursor[Person].toList // returns a Future[List[Person]]
{% endhighlight %}


### 3. Performance improvements and bugfixes

Enumerating a very big collection has been greatly speeded up. A regression regarding authentication with MongoDB 2.4 has also been fixed.

### … And many, many other improvements!

This new version is ready to use!

If you use SBT, you just have to edit `build.sbt` and add the following:

{% highlight scala %}
libraryDependencies ++= Seq(
  "org.reactivemongo" %% "reactivemongo" % "0.9"
)
{% endhighlight %}