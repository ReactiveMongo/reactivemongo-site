---
layout: default
major_version: 0.12
title: Integration with Play Framework
---

A ReactiveMongo plugin is available for [Play Framework](https://playframework.com/), providing a reactive, asynchronous and non-blocking Scala driver for MongoDB to develop your application.

This module is based on the [Play JSON serialization](../json/overview.html).

## Add Play2-ReactiveMongo to your dependencies

The latest version of this plugin is for Play 2.4+, and can be enabled by adding the following dependency in your `project/Build.scala` (or `build.sbt`).

{% highlight ocaml %}
// only for Play 2.6.x
libraryDependencies ++= Seq(
  "org.reactivemongo" %% "play2-reactivemongo" % "{{site._0_12_latest_minor}}-play26"
)

// only for Play 2.5.x
libraryDependencies ++= Seq(
  "org.reactivemongo" %% "play2-reactivemongo" % "{{site._0_12_latest_minor}}-play25"
)

// only for Play 2.4.x
libraryDependencies ++= Seq(
  "org.reactivemongo" %% "play2-reactivemongo" % "{{site._0_12_latest_minor}}-play24"
)
{% endhighlight %}

[![Maven Central](https://maven-badges.herokuapp.com/maven-central/org.reactivemongo/play2-reactivemongo_2.12/badge.svg)](https://maven-badges.herokuapp.com/maven-central/org.reactivemongo/play2-reactivemongo_2.12/)

> When the dependency to the Play plugin is used, no separate dependency to the ReactiveMongo driver must be declared, as it will be resolved in the appropriate version by the transitive dependency mechanism.

As for Play 2.4+ itself, this ReactiveMongo plugin requires a JVM 1.8+.

The [API of this Play module](https://oss.sonatype.org/service/local/repositories/releases/archive/org/reactivemongo/play2-reactivemongo_2.11/{{site._0_12_latest_minor}}/play2-reactivemongo_2.11-{{site._0_12_latest_minor}}-javadoc.jar/!/index.html) can be browsed online.

The API for the standalone JSON serialization is [also available](https://oss.sonatype.org/service/local/repositories/releases/archive/org/reactivemongo/reactivemongo-play-json_2.11/{{site._0_12_latest_minor}}/reactivemongo-play-json_2.11-{{site._0_12_latest_minor}}-javadoc.jar/!/index.html).

If you want to use the latest snapshot, add the following instead (only for play > 2.4):

{% highlight ocaml %}
resolvers += "Sonatype Snapshots" at "https://oss.sonatype.org/content/repositories/snapshots/"

libraryDependencies ++= Seq(
  "org.reactivemongo" %% "play2-reactivemongo" % "1.0.0-SNAPSHOT"
)
{% endhighlight %}

## Setup

### Play 2.4+

**`ReactiveMongoPlugin` is deprecated, long live to `ReactiveMongoModule` and `ReactiveMongoApi`**.

Play has deprecated the plugins in version 2.4, therefore it is recommended to remove the former `ReactiveMongoPlugin` from your project. It must be replaced it by `ReactiveMongoModule` and [`ReactiveMongoApi`](https://oss.sonatype.org/service/local/repositories/releases/archive/org/reactivemongo/play2-reactivemongo_2.11/{{site._0_12_latest_minor}}/play2-reactivemongo_2.11-{{site._0_12_latest_minor}}-javadoc.jar/!/index.html#play.modules.reactivemongo.ReactiveMongoApi) which is the interface to MongoDB.

Thus, the dependency injection can be configured, so that the your controllers are given the new ReactiveMongo API.
First, Add the line bellow to `application.conf`:

{% highlight ocaml %}
play.modules.enabled += "play.modules.reactivemongo.ReactiveMongoModule"
{% endhighlight %}

Then use the Play's dependency injection mechanism to resolve instance of `ReactiveMongoApi` which as an interface to MongoDB.

{% highlight scala %}
import javax.inject.Inject

import play.api.mvc.Controller
import play.modules.reactivemongo._

class MyController @Inject() (val reactiveMongoApi: ReactiveMongoApi)
  extends Controller with MongoController with ReactiveMongoComponents {

  // ...
}
{% endhighlight %}

The traits [`ReactiveMongoComponents`](https://oss.sonatype.org/service/local/repositories/releases/archive/org/reactivemongo/play2-reactivemongo_2.11/{{site._0_12_latest_minor}}/play2-reactivemongo_2.11-{{site._0_12_latest_minor}}-javadoc.jar/!/index.html#play.modules.reactivemongo.ReactiveMongoComponents) and [`ReactiveMongoApiComponents`](https://oss.sonatype.org/service/local/repositories/releases/archive/org/reactivemongo/play2-reactivemongo_2.11/{{site._0_12_latest_minor}}/play2-reactivemongo_2.11-{{site._0_12_latest_minor}}-javadoc.jar/!/index.html#play.modules.reactivemongo.ReactiveMongoApiComponents) can be used for [compile-time dependency injection](https://playframework.com/documentation/latest/ScalaCompileTimeDependencyInjection).

{% highlight scala %}
import javax.inject.Inject

import play.api.mvc.Controller
import play.modules.reactivemongo._

class MyController @Inject() (val reactiveMongoApi: ReactiveMongoApi)
  extends Controller with MongoController with ReactiveMongoComponents {

}
{% endhighlight %}

> When using Play dependency injection for a controller, the [injected routes need to be enabled](https://www.playframework.com/documentation/2.4.0/ScalaRouting#Dependency-Injection) by adding `routesGenerator := InjectedRoutesGenerator` to your build.

**Multiple pools**

In your Play application, you can use ReactiveMongo with multiple connection pools (possibly with different replica sets and/or different options), using the `@NamedDatabase` annotation.

Consider the following configuration, with several connection URIs.

{% highlight text %}
# The default URI
mongodb.uri = "mongodb://someuser:somepasswd@localhost:27017/foo"

# Another one, named with 'bar'
mongodb.bar.uri = "mongodb://someuser:somepasswd@localhost:27017/lorem"
{% endhighlight %}

Then the dependency injection can select the API instances using the names.

{% highlight scala %}
import javax.inject.Inject

import play.modules.reactivemongo._

class MyComponent @Inject() (
  val defaultApi: ReactiveMongoApi, // corresponds to 'mongodb.uri'
  @NamedDatabase("bar") val barApi: ReactiveMongoApi // 'mongodb.bar'
) {

}
{% endhighlight %}

### Configure your database access

This module reads the connection properties from the `application.conf` and gives you an easy access to the connected database.

You can use the URI syntax to point to your MongoDB:

{% highlight text %}
mongodb.uri = "mongodb://someuser:somepasswd@localhost:27017/your_db_name"
{% endhighlight %}

This is especially helpful on platforms like Heroku, where the add-ons publish the connection URI in a single environment variable. The URI syntax supports the following format: `mongodb://[username:password@]host1[:port1][,hostN[:portN]]/dbName?option1=value1&option2=value2`

A more complete example:

{% highlight text %}
mongodb.uri = "mongodb://someuser:somepasswd@host1:27017,host2:27017,host3:27017/your_db_name?authSource=authdb&rm.nbChannelsPerNode=10"
{% endhighlight %}

To configure a connection pool different from the default one (for the `@NamedDatabase` annotation), the key must be `mongodb.ANY_NAME.uri`.

{% highlight text %}
mongodb.ANY_NAME.uri = "mongodb://localhost:27017/another_pool"
{% endhighlight %}

The setting `mongodb.connection.strictUri` (`true` or `false`) can be added to the Play configuration (or `mongodb.ANY_NAME.connection.strictUri` for a connection pool other than the default one), to enforce the ReactiveMongo only accepts strict URI: to make the connection pool throws an exception if given an URI with unsupported options.
By default (`false`), unsupported options (e.g. `?foo=bar`) are just ignored.

### Configure underlying Akka system

ReactiveMongo loads its Akka configuration from the key `mongo-async-driver`.

To change the corresponding log level (prevent dead-letter logging for example):

{% highlight text %}
mongo-async-driver {
  akka {
    loglevel = WARNING
  }
}
{% endhighlight %}

## Main features

### Routing

The [BSON types](../bson/overview.html) can be used in the bindings of the Play routing.

For example, consider an action as follows.

{% highlight scala %}
import play.api.mvc.{ Action, Controller }
import reactivemongo.bson.BSONObjectID

class Application extends Controller {
  def foo(id: BSONObjectID) = Action {
    Ok(s"Foo: ${id.stringify}")
  }
}
{% endhighlight %}

This action can be configured with a [`BSONObjectID`](../../api/reactivemongo/bson/BSONObjectID.html) binding, in the `conf/routes` file.

    GET /foo/:id controllers.Application.foo(id: reactivemongo.bson.BSONObjectID)

When using BSON types in the route bindings, the Play plugin for SBT must also be set up (in your `build.sbt` or `project/Build.scala`), to be able to install the appropriate import in the generated routes.

{% highlight ocaml %}
import play.sbt.routes.RoutesKeys

RoutesKeys.routesImport += "play.modules.reactivemongo.PathBindables._"
{% endhighlight %}

If this routes import is not configured, errors as following will occur.

    [error] /path/to/conf/routes:19: No URL path binder found for type reactivemongo.bson.BSONObjectID. Try to implement an implicit PathBindable for this type.

Once this is properly set up, any BSON types can be used in your routes, and the appropriate validations are used.

In the current example with `BSONObjectID`, if calling `/foo/bar` (with `bar` bound as `:id`), then the error thereafter will be raised.

    For request 'GET /foo/bar' [wrong ObjectId: 'bar']

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

### Play controller sample

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
import reactivemongo.api.ReadPreference

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
   * Resolves a JSONCollection
   * (a Collection implementation that is designed to work with JsObject,
   * Reads and Writes).
   *
   * The deprecated `.db` function should be replaced as there by `.database`.
   *
   * Note that the `collection` is not a `val`, but a `def`. We do _not_ store
   * the collection reference to avoid potential problems in development with
   * Play hot-reloading.
   */
  def collection: Future[JSONCollection] =
    database.map(_.collection[JSONCollection]("persons"))

  def index = Action { Ok("works") }

  def create(name: String, age: Int) = Action.async {
    val json = Json.obj(
      "name" -> name,
      "age" -> age,
      "created" -> new java.util.Date().getTime())

    collection.flatMap(_.insert(json)).map(lastError =>
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
      collection.flatMap(_.insert(result)).map { lastError =>
        Logger.debug(s"Successfully inserted with LastError: $lastError")
        Created
      }
    }.getOrElse(Future.successful(BadRequest("invalid json")))
  }

  def findByName(name: String) = Action.async {
    // let's do our query
    val cursor: Future[Cursor[JsObject]] = collection.map {
      // find all people with name `name`
      _.find(Json.obj("name" -> name)).
        // sort them by creation date
        sort(Json.obj("created" -> -1)).
        // perform the query and get a cursor of JsObject
        cursor[JsObject](ReadPreference.primary)
    }

    // gather all the JsObjects in a list
    val futurePersonsList: Future[List[JsObject]] =
      cursor.flatMap(_.collect[List]())

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

**Please note:**

- Your controller may extend `MongoController` which provides a few helpers.
- All actions are asynchronous, which means ReactiveMongo returns `Future[Result]`.
- We use a specialized collection called `JSONCollection` that deals naturally with `JsValue` and `JsObject`.

### Play controller sample using JSON Writes and Reads

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

> The following import is recommended to make sure JSON/BSON conversions are available.

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
import reactivemongo.play.json._, collection._

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
  def collection: Future[JSONCollection] = database.map(
    _.collection[JSONCollection]("persons"))

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
    val futureResult = collection.flatMap(_.insert(user))

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
      collection.flatMap(_.insert(user)).map { lastError =>
        Logger.debug(s"Successfully inserted with LastError: $lastError")
        Created
      }
    }.getOrElse(Future.successful(BadRequest("invalid json")))
  }

  def findByName(lastName: String) = Action.async {
    // let's do our query
    val cursor: Future[Cursor[User]] = collection.map {
      // find all people with name `name`
      _.find(Json.obj("lastName" -> lastName)).
        // sort them by creation date
        sort(Json.obj("created" -> -1)).
        // perform the query and get a cursor of JsObject
        cursor[User]
    }

    // gather all the JsObjects in a list
    val futureUsersList: Future[List[User]] = cursor.flatMap(_.collect[List]())

    // everything's ok! Let's reply with the array
    futureUsersList.map { persons =>
      Ok(persons.toString)
    }
  }
}
{% endhighlight %}

## Troubleshooting

For Play > 2.4, if you still have a file `conf/play.plugins`, it's important to make sure this file no longer mentions `ReactiveMongoPlugin`, which is replaced by `ReactiveMongoModule`. With such deprecated configuration, the following error can be raised.

    ConfigurationException: Guice configuration errors: 
    1) Could not find a suitable constructor in 
    play.modules.reactivemongo.ReactiveMongoPlugin.

As in the code driver, the database resolution has been updated in the Play module. If using the deprecated resolution, the following warning is raised by the compiler.

    method db in trait MongoController is deprecated: Use [[database]]

A related warning can also be displayed about GridFS usage.

    method gridFSBodyParser in trait MongoController is deprecated: Use gridFSBodyParser with Future[GridFS]

## Resources

**Samples:**

{% include play-samples.md %}

[Previous: Play JSON support](../json/overview.html)
