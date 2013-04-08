---
layout: default
title: ReactiveMongo
---

### coucou
yop la


# ReactiveMongo - Asynchronous & Non-Blocking Scala Driver for MongoDB


[ReactiveMongo](https://github.com/zenexity/ReactiveMongo/) is a scala driver that provides fully non-blocking and asynchronous I/O operations. :)


  <p class="notice center">
    The roadmap to the first stable release of ReactiveMongo has been announced! You can read it <a href="http://stephane.godbillon.com/2013/01/17/announcing-reactivemongo-roadmap-reactivemongo-0.8.html">here</a>. Also, ReactiveMongo 0.8 is out and <a href="http://search.maven.org/#browse%7C1306790">available on Maven Central</a>.
  </p>

## Scale better, use less threads

With a classic synchronous database driver, each operation blocks the current thread until a response is received. This model is simple but has a major flaw - it can't scale that much.

Imagine that you have a web application with 10 concurrent accesses to the database. That means you eventually end up with 10 frozen threads at the same time, doing nothing but waiting for a response. A common solution is to rise the number of running threads to handle more requests. Such a waste of resources is not really a problem if your application is not heavily loaded, but what happens if you have 100 or even 1000 more requests to handle, performing each several db queries? The multiplication grows really fast...

The problem is getting more and more obvious while using the new generation of web frameworks. What's the point of using a nifty, powerful, fully asynchronous web framework like [Play Framework](http://www.playframework.com) if all your database accesses are blocking?

ReactiveMongo is designed to avoid any kind of blocking request. Every operation returns immediately, freeing the running thread and resuming execution when it is over. Accessing the database is not a bottleneck anymore.

## Let the stream flow!

The future of the web is in streaming data to a very large number of clients simultaneously. Twitter Stream API is a good example of this paradigm shift that is radically altering the way data is consumed all over the web.

ReactiveMongo enables you to build such a web application right now. It allows you to stream data both into and from your MongoDB servers.

One scenario could be consuming progressively your collection of documents as needed without filling memory unnecessarily.

But if what you're interested in is live feeds then you can stream a MongoDB [capped collection](http://www.mongodb.org/display/DOCS/Tailable+Cursors) through a websocket, comet or any other streaming protocol. A capped collection is a fixed-size (FIFO) collection from which you can fetch documents as they are inserted. Each time a document is stored into this collection, the webapp broadcasts it to all the interested clients, in a complete non-blocking way.

Moreover, you can now use GridFS as a non-blocking, streaming datastore. ReactiveMongo retrieves the file, chunk by chunk, and streams it until the client is done or there's no more data. Neither huge memory consumption, nor blocked thread during the process!

## Step By Step Example

Let's show a simple use case: print the documents of a capped collection.

### Prerequisites

We assume that you got a running MongoDB instance. If not, get [the latest MongoDB binaries](http://www.mongodb.org/downloads) and unzip the archive. Then you can launch the database:

{% highlight sh %}
$ mkdir data
$ ./bin/mongod --dbpath data
{% endhighlight %}

This will start a standalone MongoDB instance that stores its data in the `data` directory and listens on the TCP port 27017.

### Set up your project dependencies

ReactiveMongo is available on [Maven Central](http://search.maven.org/#browse%7C1306790).

If you use SBT, you just have to edit your build.properties and add the following:

{% highlight scala %}
libraryDependencies ++= Seq(
  "org.reactivemongo" %% "reactivemongo" % "0.8"
)
{% endhighlight %}

Or if you want to be on the bleeding edge using snapshots:
{% highlight scala %}
resolvers += "Sonatype Snapshots" at "http://oss.sonatype.org/content/repositories/snapshots/"

libraryDependencies ++= Seq(
  "org.reactivemongo" %% "reactivemongo" % "0.9-SNAPSHOT"
)
{% endhighlight %}

### Connect to the database

You can get a connection to a server (or a replica set) like this:

{% highlight scala %}
def test() {
  import reactivemongo.api._
  import scala.concurrent.ExecutionContext.Implicits.global

  val driver = new MongoDriver
  val connection = driver.connection( List( "localhost:27017" ) )
  val db = connection("plugin")
  val collection = db("acoll")
}
{% endhighlight %}

The `connection` reference manages a pool of connections. You can provide a list of one ore more servers; the driver will guess if it's a standalone server or a replica set configuration. Even with one replica node, the driver will probe for other nodes and add them automatically.

### Run a simple query

{% highlight scala %}
package foo

  import reactivemongo.api._
  import reactivemongo.bson._
  import reactivemongo.bson.handlers.DefaultBSONHandlers._
  import play.api.libs.iteratee.Iteratee

  object Samples {
    import scala.concurrent.ExecutionContext.Implicits.global

    def listDocs() = {
      // select only the documents which field 'firstName' equals 'Jack'
      val query = BSONDocument("firstName" -> BSONString("Jack"))

      // get a Cursor[DefaultBSONIterator]
      val cursor = collection.find(query)
      // let's enumerate this cursor and print a readable representation of each document in the response
      cursor.enumerate.apply(Iteratee.foreach { doc =>
        println("found document: " + BSONDocument.pretty(doc))
      })

      // or, the same with getting a list
      val cursor2 = collection.find(query)
      val futurelist = cursor2.toList
      futurelist.onSuccess {
        case list =>
          val names = list.map(_.getAs[BSONString]("lastName").get.value)
          println("got names: " + names)
      }
    }
  }
{% endhighlight %}

The above code deserves some explanations. First, let's take a look to the `collection.find` signature:

{% highlight scala %}
def find[Qry, Rst](query: Qry)(implicit writer: BSONWriter[Qry], handler: BSONReaderHandler, reader: BSONReader[Rst]) :FlattenedCursor[Rst]
{% endhighlight %}

The find method allows you to pass any query object of type `Qry`, provided that there is an implicit `BSONWriter[Qry]` in the scope. `BSONWriter[Qry]` is a typeclass which instances implement a `write(document: Qry)` method that returns a `BSONDocument`:

{% highlight scala %}
trait BSONWriter[DocumentType] {
  def write(document: DocumentType) :BSONDocument
}
{% endhighlight %}

`BSONReader[Rst]` is the opposite typeclass. It's typically a deserializer that takes a `BSONDocument` and returns an instance of `Rst`:

{% highlight scala %}
trait BSONReader[DocumentType] {
  def read(buffer: BSONDocument) :DocumentType
}
{% endhighlight %}

These two typeclasses allow you to provide different de/serializers for different types.
For this example, we don't need to write specific handlers, so we use the default ones by importing `reactivemongo.bson.handlers.DefaultBSONHandlers._`.

Among `DefaultBSONHandlers` is a `BSONWriter[BSONDocument]` that handles the shipped-in BSON library.

You may have noticed that `collection.find` returns a `FlattenedCursor[Rst]`. This cursor is actually a future cursor. In fact, _everything in ReactiveMongo is both non-blocking and asynchronous_. That means each time you make a query, the only immediate result you get is a future of result, so the current thread is not blocked waiting for its completion. You don't need to have _n_ threads to process _n_ database operations at the same time anymore.

When a query matches too much documents, Mongo sends just a part of them and creates a Cursor in order to get the next documents. The problem is, how to handle it in a non-blocking, asynchronous, yet elegant way?

Obviously ReactiveMongo's cursor provides helpful methods to build a collection (like a list) from it, so we could write:

{% highlight scala %}
val futureList :Future[List] = cursor.toList
futureList.map { list =>
  println("ok, got the list: " + list)
}
{% endhighlight %}

As always, this is perfectly non-blocking... but what if we want to process the returned documents on the fly, without creating a potentially huge list in memory?

That's where the Enumerator/Iteratee pattern (or immutable Producer/Consumer pattern) comes to the rescue!

Let's consider the following statement:

{% highlight scala %}
cursor.enumerate.apply(Iteratee.foreach { doc =>
  println("found document: " + BSONDocument.pretty(doc))
})
{% endhighlight %}

The method `cursor.enumerate` returns an `Enumerator[T]`. Enumerators can be seen as _producers_ of data: their job is to give chunks of data when data is available. In this case, we get a producer of documents, which source is a future cursor.

Now that we have the producer, we need to define how the documents are processed: that is the `Iteratee`'s job. Iteratees, as the opposite of Enumerators, are consumers: they are fed in by enumerators and do some computation with the chunks they get.

Here, we write a very simple Iteratee: each time it gets a document, it makes a readable, JSON-like description of the document and prints it on the console. Note that none of these operations are blocking: when the running thread is not processing the callback of our iteratee, it can be used to compute other things.

When this snippet is run, we get the following:

    found document: {
      _id: BSONObjectID["4f899e7eaf527324ab25c56b"],
      firstName: BSONString(Jack),
      lastName: BSONString(London)
    }
    found document: {
      _id: BSONObjectID["4f899f9baf527324ab25c56c"],
      firstName: BSONString(Jack),
      lastName: BSONString(Kerouac)
    }
    found document: {
      _id: BSONObjectID["4f899f9baf527324ab25c56d"],
      firstName: BSONString(Jack),
      lastName: BSONString(Nicholson)
    }

## Go further!

There is a pretty complete [Scaladoc](api/index.html) available. The code is accessible from the [Github repository](https://github.com/zenexity/ReactiveMongo).

ReactiveMongo makes a heavy usage of the Iteratee library provided by the [Play! Framework 2.1](http://www.playframework.com). You can dive into [Play's Iteratee documentation](http://www.playframework.org/documentation/2.0.2/Iteratees) to learn about this cool piece of software, and make your own Iteratees and Enumerators.

Used in conjonction with stream-aware frameworks, like Play!, you can easily stream the data stored in MongoDB. For Play, there is a [ReactiveMongo Plugin](https://github.com/zenexity/Play-ReactiveMongo) that brings some cool stuff, like JSON to BSON conversion and helpers for GridFS. See the examples and get convinced!

### Samples

These sample applications are kept up to date with the latest driver version. They are built upon Play 2.1 RC2.

* [ReactiveMongo Tailable Cursor, WebSocket and Play 2](https://github.com/sgodbillon/reactivemongo-tailablecursor-demo)
* [Full Web Application featuring basic CRUD operations and GridFS streaming](https://github.com/sgodbillon/reactivemongo-demo-app)

hey
