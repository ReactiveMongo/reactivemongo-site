---
layout: default
major_version: 0.1x
title: Get started
---

## Get started

For the impatient, bellow is a complete example.

First the ReactiveMongo dependencies must be configured. {% include sbt-dependency.md %}

Then the following code, from connection to operations on a collection, can be used in your project.

{% highlight scala %}
import scala.concurrent.{ ExecutionContext, Future }

import reactivemongo.api.{ Cursor, DefaultDB, MongoConnection, MongoDriver }
import reactivemongo.bson.{
  BSONDocumentWriter, BSONDocumentReader, Macros, document
}

object GetStarted {
  // My settings (see available connection options)
  val mongoUri = "mongodb://localhost:27017/mydb?authMode=scram-sha1"

  import ExecutionContext.Implicits.global // use any appropriate context

  // Connect to the database: Must be done only once per application
  val driver = MongoDriver()
  val parsedUri = MongoConnection.parseURI(mongoUri)
  val connection = parsedUri.map(driver.connection(_))

  // Database and collections: Get references
  val futureConnection = Future.fromTry(connection)
  def db1: Future[DefaultDB] = futureConnection.flatMap(_.database("firstdb"))
  def db2: Future[DefaultDB] = futureConnection.flatMap(_.database("anotherdb"))
  def personCollection = db1.map(_.collection("person"))

  // Write Documents: insert or update
  
  implicit def personWriter: BSONDocumentWriter[Person] = Macros.writer[Person]
  // or provide a custom one

  // use personWriter
  def createPerson(person: Person): Future[Unit] =
    personCollection.flatMap(_.insert.one(person).map(_ => {})) 

  def updatePerson(person: Person): Future[Int] = {
    val selector = document(
      "firstName" -> person.firstName,
      "lastName" -> person.lastName
    )

    // Update the matching person
    personCollection.flatMap(_.update.one(selector, person).map(_.n))
  }

  implicit def personReader: BSONDocumentReader[Person] = Macros.reader[Person]
  // or provide a custom one

  def findPersonByAge(age: Int): Future[List[Person]] =
    personCollection.flatMap(_.find(document("age" -> age)). // query builder
      cursor[Person](). // using the result cursor
      collect[List](-1, Cursor.FailOnError[List[Person]]()))
      // ... deserializes the document using personReader

  // Custom persistent types
  case class Person(firstName: String, lastName: String, age: Int)
}
{% endhighlight %}

**Prerequisites:**

{% include assume-setup.md %}

[More: **Setup your project**](./setup.html)

**Go further:**

2. [Connect to the database](./connect-database.html)
3. [Open database and collections](./database-and-collection.html)
4. [Write documents](./write-documents.html) (`insert`, `update`, `remove`)
5. [Find documents](./find-documents.html)
6. [Streaming](./streaming.html)

[Next: Connect to the database](./connect-database.html)
