---
layout: default
title: ReactiveMongo 0.12 - Integration with Play Framework
---

A ReactiveMongo plugin is available for [Play Framework](https://playframework.com/), providing a reactive, asynchronous and non-blocking Scala driver for MongoDB to develop your application.

This module is based on the [Play JSON serialization](../json/overview.html).

## Add Play2-ReactiveMongo to your dependencies

The latest version of this plugin is for Play 2.4+, and can be enabled by adding the following dependency in your `project/Build.scala` (or `build.sbt`).

{% highlight ocaml %}
// only for Play 2.5.x
libraryDependencies ++= Seq(
  "org.reactivemongo" %% "play2-reactivemongo" % "{{site._0_12_latest_minor}}"
)

// only for Play 2.4.x
libraryDependencies ++= Seq(
  "org.reactivemongo" %% "play2-reactivemongo" % "{{site._0_12_latest_minor}}-play23"
)
{% endhighlight %}

[![Maven Central](https://maven-badges.herokuapp.com/maven-central/org.reactivemongo/play2-reactivemongo_2.12/badge.svg)](https://maven-badges.herokuapp.com/maven-central/org.reactivemongo/play2-reactivemongo_2.12/)

> When the dependency to the Play plugin is used, no separate dependency to the ReactiveMongo driver must be declared, as it will be resolved in appropriate version by the transitive dependency mechanism.

As for Play 2.4 itself, this ReactiveMongo plugin requires a JVM 1.8+.

If you are looking for a stable version for Play 2.3.x, please consider using the 0.11.11-play23 version:

{% highlight ocaml %}
libraryDependencies ++= Seq(
  "org.reactivemongo" %% "play2-reactivemongo" % "0.11.11-play23"
)
{% endhighlight %}

The [API of this Play module](../../play-api/index.html) can be browsed online.

If you want to use the latest snapshot, add the following instead (only for play > 2.4):

{% highlight ocaml %}
resolvers += "Sonatype Snapshots" at "https://oss.sonatype.org/content/repositories/snapshots/"

libraryDependencies ++= Seq(
  "org.reactivemongo" %% "play2-reactivemongo" % "0.13.0-SNAPSHOT"
)
{% endhighlight %}

## Setup

### Play 2.4

**ReactiveMongoPlugin is deprecated, long live to ReactiveMongoModule and ReactiveMongoApi**.

Play has deprecated plugins in version 2.4. Therefore it is recommended to remove it from your project and replace it by `ReactiveMongoModule` and `ReactiveMongoApi` which is the interface to MongoDB.

{% highlight scala %}
package api

import reactivemongo.api.{ DB, MongoConnection, MongoDriver }

trait ReactiveMongoApi {
  def driver: MongoDriver
  def connection: MongoConnection
  def db: DB
}
{% endhighlight %}

Thus, the dependency injection can be configured, so that the your controllers are given the new ReactiveMongo API.
First, Add the line bellow to `application.conf`:

{% highlight ocaml %}
play.modules.enabled += "play.modules.reactivemongo.ReactiveMongoModule"
{% endhighlight %}

Then use Play's dependency injection mechanism to resolve instance of `ReactiveMongoApi` which is the interface to MongoDB. Example:

{% highlight scala %}
import javax.inject.Inject

import play.api.mvc.Controller
import play.modules.reactivemongo._

class MyController @Inject() (val reactiveMongoApi: ReactiveMongoApi)
  extends Controller with MongoController with ReactiveMongoComponents {

  // ...
}
{% endhighlight %}

The trait `ReactiveMongoComponents` can be used for [compile-time dependency injection](https://playframework.com/documentation/2.4.x/ScalaCompileTimeDependencyInjection).

{% highlight scala %}
import javax.inject.Inject

import play.api.mvc.Controller
import play.modules.reactivemongo._

class MyController @Inject() (val reactiveMongoApi: ReactiveMongoApi)
  extends Controller with MongoController with ReactiveMongoComponents {

}
{% endhighlight %}

> When using Play dependency injection for a controller, the [injected routes need to be enabled](https://www.playframework.com/documentation/2.4.0/ScalaRouting#Dependency-Injection) by adding `routesGenerator := InjectedRoutesGenerator` to your build.

It's also possible to get the injected ReactiveMongo API outside of the controllers, using the `injector` of the current Play application.

{% highlight scala %}
import scala.concurrent.Future

import play.api.Play.current
import play.api.libs.concurrent.Execution.Implicits.defaultContext

import play.modules.reactivemongo.ReactiveMongoApi
import play.modules.reactivemongo.json.collection.JSONCollection

object Foo {
  lazy val reactiveMongoApi = current.injector.instanceOf[ReactiveMongoApi]

  def collection(name: String): JSONCollection =
    reactiveMongoApi.db.collection[JSONCollection](name)
}
{% endhighlight %}

**Multiple pools**

In your Play application, you can use ReactiveMongo with multiple connection pools (possibly with different replica set).

{% highlight scala %}
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.api.{ MongoConnection, MongoDriver }

import play.api.Play.current
import play.api.inject.ApplicationLifecycle

object MongoEnv {
  val driver1 = registerDriverShutdownHook(MongoDriver()) // first pool
  val driver2 = registerDriverShutdownHook(MongoDriver()) // second pool

  // Pick a connection from the first pool
  def connection1 = driver1.connection(List("localhost:27017"))

  // Pick a connection from the second pool
  def connection2 = driver2.connection(List("remotehost:27017"))

  // ensure the given driver will be closed on app shutdown
  def registerDriverShutdownHook(mongoDriver: MongoDriver): MongoDriver = {
    current.injector.instanceOf[ApplicationLifecycle].
      addStopHook { () => Future(mongoDriver.close()) }
    mongoDriver
  }
}
{% endhighlight %}

> Such custom management also work with ReactiveMongo in a Play application, without the module.

### Play 2.3

The version `0.11.11-play23` of this plugin is available for Play 2.3.

Add to your `conf/play.plugins`:

{% highlight text %}
1100:play.modules.reactivemongo.ReactiveMongoPlugin
{% endhighlight %}

### Configure your database access

This plugin reads connection properties from the `application.conf` and gives you an easy access to the connected database.

You can use the URI syntax to point to your MongoDB:

{% highlight text %}
mongodb.uri = "mongodb://someuser:somepasswd@localhost:27017/your_db_name"
{% endhighlight %}

This is especially helpful on platforms like Heroku, where add-ons publish the connection URI in a single environment variable. The URI syntax supports the following format: `mongodb://[username:password@]host1[:port1][,hostN[:portN]]/dbName?option1=value1&option2=value2`

A more complete example:

{% highlight text %}
mongodb.uri = "mongodb://someuser:somepasswd@host1:27017,host2:27017,host3:27017/your_db_name?authSource=authdb&rm.nbChannelsPerNode=10"
{% endhighlight %}

### Configure underlying akka system

ReactiveMongo loads its configuration from the key `mongo-async-driver`.

To change the log level (prevent dead-letter logging for example)

{% highlight text %}
mongo-async-driver {
  akka {
    loglevel = WARNING
  }
}
{% endhighlight %}

## Main features

### Helpers for GridFS

Play2-ReactiveMongo makes it easy to serve and store files in a complete non-blocking manner.
It provides a body parser for handling file uploads, and a method to serve files from a GridFS store.

{% highlight scala %}
import scala.concurrent.Future

import play.api.mvc.{ Action, Controller }
import play.api.libs.concurrent.Execution.Implicits.defaultContext
import play.api.libs.json._

import reactivemongo.api.gridfs.{ // ReactiveMongo GridFS
  DefaultFileToSave, FileToSave, GridFS, ReadFile
}

import play.modules.reactivemongo.{ MongoController, ReactiveMongoComponents }
import reactivemongo.play.json._

trait MyController extends Controller
  with MongoController with ReactiveMongoComponents {

  implicit def materializer: akka.stream.Materializer

  // gridFSBodyParser from `MongoController`
  import MongoController.readFileReads

  val fsParser = gridFSBodyParser(reactiveMongoApi.gridFS)
  
  def upload = Action.async(fsParser) { request =>
    // here is the future file!
    val futureFile: Future[ReadFile[JSONSerializationPack.type, JsValue]] = 
      request.body.files.head.ref

    futureFile.map { file =>
      // do something
      Ok
    }.recover {
      case e: Throwable => InternalServerError(e.getMessage)
    }
  }
}
{% endhighlight %}

> The maximum size of upload using the GridFS provided by a `MongoController` can be configured by the Play [`DefaultMaxDiskLength`](https://www.playframework.com/documentation/2.4.0/api/scala/index.html#play.api.mvc.BodyParsers$parse$@DefaultMaxDiskLength:Long).

## Code samples

### Play2 controller sample

{% highlight scala %}
package controllers

import javax.inject.Inject

import scala.concurrent.Future

import play.api.Logger
import play.api.mvc.{ Action, Controller }
import play.api.libs.concurrent.Execution.Implicits.defaultContext
import play.api.libs.functional.syntax._
import play.api.libs.json._

// Reactive Mongo imports
import reactivemongo.api.Cursor

import play.modules.reactivemongo.{ // ReactiveMongo Play2 plugin
  MongoController,
  ReactiveMongoApi,
  ReactiveMongoComponents
}

// BSON-JSON conversions/collection
import reactivemongo.play.json._
import play.modules.reactivemongo.json.collection._

/*
 * Example using ReactiveMongo + Play JSON library.
 *
 * There are two approaches demonstrated in this controller:
 * - using JsObjects directly
 * - using case classes that can be turned into JSON using Reads and Writes.
 *
 * This controller uses JsObjects directly.
 *
 * Instead of using the default Collection implementation (which interacts with
 * BSON structures + BSONReader/BSONWriter), we use a specialized
 * implementation that works with JsObject + Reads/Writes.
 *
 * Of course, you can still use the default Collection implementation
 * (BSONCollection.) See ReactiveMongo examples to learn how to use it.
 */
class Application @Inject() (val reactiveMongoApi: ReactiveMongoApi)
    extends Controller with MongoController with ReactiveMongoComponents {

  /*
   * Get a JSONCollection (a Collection implementation that is designed to work
   * with JsObject, Reads and Writes.)
   * Note that the `collection` is not a `val`, but a `def`. We do _not_ store
   * the collection reference to avoid potential problems in development with
   * Play hot-reloading.
   */
  def collection: JSONCollection = db.collection[JSONCollection]("persons")

  def index = Action { Ok("works") }

  def create(name: String, age: Int) = Action.async {
    val json = Json.obj(
      "name" -> name,
      "age" -> age,
      "created" -> new java.util.Date().getTime())

    collection.insert(json).map(lastError =>
      Ok("Mongo LastError: %s".format(lastError)))
  }

  def createFromJson = Action.async(parse.json) { request =>
    import play.api.libs.json.Reads._
    /*
     * request.body is a JsValue.
     * There is an implicit Writes that turns this JsValue as a JsObject,
     * so you can call insert() with this JsValue.
     * (insert() takes a JsObject as parameter, or anything that can be
     * turned into a JsObject using a Writes.)
     */
    val transformer: Reads[JsObject] =
      Reads.jsPickBranch[JsString](__ \ "firstName") and
        Reads.jsPickBranch[JsString](__ \ "lastName") and
        Reads.jsPickBranch[JsNumber](__ \ "age") reduce

    request.body.transform(transformer).map { result =>
      collection.insert(result).map { lastError =>
        Logger.debug(s"Successfully inserted with LastError: $lastError")
        Created
      }
    }.getOrElse(Future.successful(BadRequest("invalid json")))
  }

  def findByName(name: String) = Action.async {
    // let's do our query
    val cursor: Cursor[JsObject] = collection.
      // find all people with name `name`
      find(Json.obj("name" -> name)).
      // sort them by creation date
      sort(Json.obj("created" -> -1)).
      // perform the query and get a cursor of JsObject
      cursor[JsObject]

    // gather all the JsObjects in a list
    val futurePersonsList: Future[List[JsObject]] = cursor.collect[List]()

    // transform the list into a JsArray
    val futurePersonsJsonArray: Future[JsArray] =
      futurePersonsList.map { persons => Json.arr(persons) }

    // everything's ok! Let's reply with the array
    futurePersonsJsonArray.map { persons =>
      Ok(persons)
    }
  }
}
{% endhighlight %}

> Please Notice:
>
> - your controller may extend `MongoController` which provides a few helpers
> - all actions are asynchronous because ReactiveMongo returns `Future[Result]`
> - we use a specialized collection called `JSONCollection` that deals naturally with `JsValue` and `JsObject`

### Play2 controller sample using JSON Writes and Reads

First, the models:

{% highlight scala %}
package models

case class User(
  age: Int,
  firstName: String,
  lastName: String,
  feeds: List[Feed])

case class Feed(
  name: String,
  url: String)

object JsonFormats {
  import play.api.libs.json.Json

  // Generates Writes and Reads for Feed and User thanks to Json Macros
  implicit val feedFormat = Json.format[Feed]
  implicit val userFormat = Json.format[User]
}
{% endhighlight %}

> The following import is recommanded to make sure JSON/BSON convertions are available.

{% highlight scala %}
import reactivemongo.play.json._
{% endhighlight %}

Then, the controller which uses the ability of the `JSONCollection` to handle JSON's `Reads` and `Writes`:

{% highlight scala %}
package controllers

import javax.inject.Inject

import scala.concurrent.Future

import play.api.Logger
import play.api.mvc.{ Action, Controller }
import play.api.libs.concurrent.Execution.Implicits.defaultContext
import play.api.libs.json._

// Reactive Mongo imports
import reactivemongo.api.Cursor

import play.modules.reactivemongo.{ // ReactiveMongo Play2 plugin
  MongoController,
  ReactiveMongoApi,
  ReactiveMongoComponents
}

// BSON-JSON conversions/collection
import reactivemongo.play.json._
import play.modules.reactivemongo.json.collection._

/*
 * Example using ReactiveMongo + Play JSON library.
 *
 * There are two approaches demonstrated in this controller:
 * - using JsObjects directly
 * - using case classes that can be turned into JSON using Reads and Writes.
 *
 * This controller uses case classes and their associated Reads/Writes
 * to read or write JSON structures.
 *
 * Instead of using the default Collection implementation (which interacts with
 * BSON structures + BSONReader/BSONWriter), we use a specialized
 * implementation that works with JsObject + Reads/Writes.
 *
 * Of course, you can still use the default Collection implementation
 * (BSONCollection.) See ReactiveMongo examples to learn how to use it.
 */
class ApplicationUsingJsonReadersWriters @Inject() (
  val reactiveMongoApi: ReactiveMongoApi) extends Controller
    with MongoController with ReactiveMongoComponents {

  /*
   * Get a JSONCollection (a Collection implementation that is designed to work
   * with JsObject, Reads and Writes.)
   * Note that the `collection` is not a `val`, but a `def`. We do _not_ store
   * the collection reference to avoid potential problems in development with
   * Play hot-reloading.
   */
  def collection: JSONCollection = db.collection[JSONCollection]("persons")

  // ------------------------------------------ //
  // Using case classes + JSON Writes and Reads //
  // ------------------------------------------ //
  import play.api.data.Form
  import models._
  import models.JsonFormats._

  def create = Action.async {
    val user = User(29, "John", "Smith", List(
      Feed("Slashdot news", "http://slashdot.org/slashdot.rdf")))
    // insert the user
    val futureResult = collection.insert(user)
    // when the insert is performed, send a OK 200 result
    futureResult.map(_ => Ok)
  }

  def createFromJson = Action.async(parse.json) { request =>
    /*
     * request.body is a JsValue.
     * There is an implicit Writes that turns this JsValue as a JsObject,
     * so you can call insert() with this JsValue.
     * (insert() takes a JsObject as parameter, or anything that can be
     * turned into a JsObject using a Writes.)
     */
    request.body.validate[User].map { user =>
      // `user` is an instance of the case class `models.User`
      collection.insert(user).map { lastError =>
        Logger.debug(s"Successfully inserted with LastError: $lastError")
        Created
      }
    }.getOrElse(Future.successful(BadRequest("invalid json")))
  }

  def findByName(lastName: String) = Action.async {
    // let's do our query
    val cursor: Cursor[User] = collection.
      // find all people with name `name`
      find(Json.obj("lastName" -> lastName)).
      // sort them by creation date
      sort(Json.obj("created" -> -1)).
      // perform the query and get a cursor of JsObject
      cursor[User]

    // gather all the JsObjects in a list
    val futureUsersList: Future[List[User]] = cursor.collect[List]()

    // everything's ok! Let's reply with the array
    futureUsersList.map { persons =>
      Ok(persons.toString)
    }
  }
}
{% endhighlight %}

## Resources

**Samples:**

{% include play-samples.md %}

**Screencasts:**

* [ReactiveMongo Play Plugin](http://yobriefca.se/screencasts/005-play-reactivemongo) (by James Hughes)

[Previous: Play JSON support](../json/overview.html)
