---
layout: default
title: ReactiveMongo 0.12 - Release details
---

## ReactiveMongo {{site._0_12_latest_minor}} – Release details

**What's new?**

- New APIs, for the [commands](advanced-topics/commands.html) and [streaming](tutorial/consume-streams.html)
- Compatibility with MongoDB 3.2
- [SSL support](tutorial/connect-database.html)
- Builtin micro-DSL for BSON
- Convenient operations on a collection (`.count`, `.runCommand`)

There is also a new version of the [Play Framework plugin](tutorial/play2.html).

> MongoDB versions older than 2.6 are not longer supported by ReactiveMongo.

**Documentation**

The documentation is available [online](index.html). You can also browse the [Scaladoc](../api/index.html).

### Migration notes

The package `reactivemongo.api.collections.default` has been refactored as the package [`reactivemongo.api.collections.bson`](http://reactivemongo.org/releases/0.11/api/index.html#reactivemongo.api.collections.bson.package).
If you get a compilation error like the following one, you need to update the corresponding imports.

    object default is not a member of package reactivemongo.api.collections
    [error] import reactivemongo.api.collections.default.BSONCollection

{% highlight text %}
No Json serializer as JsObject found for type play.api.libs.json.JsObject.
Try to implement an implicit OWrites or OFormat for this type.
{% endhighlight %}

When using the **[support for Play JSON](json/overview.html)**, if the previous error occurs, it necessary to make sure `import reactivemongo.play.json._` is used, to import default BSON/JSON conversions.

### Breaking changes

- In class `reactivemongo.api.commands.Upserted`;
  * constructor has changed; was `(Int, java.lang.Object)`, is now: `(Int, reactivemongo.bson.BSONValue)`
  * method `_id()`  has now a different result type; was: `java.lang.Object`, is now: `reactivemongo.bson.BSONValue`
- In class `reactivemongo.api.commands.AggregationFramework#Limit`;
  * method `n()` is removed
  * method `name()` is removed
- In class `reactivemongo.api.commands.AggregationFramework#Limit`;
  * method `n()` is removed
  * method `name()` is removed
- In class `reactivemongo.api.commands.AggregationFramework#Skip`;
  * method `n()` is removed
  * method `name()` is removed
- method `length()` in interface `reactivemongo.api.gridfs.ComputedMetadata` has now a different result type; was: `Int`, is now: `Long`
- Class `reactivemongo.core.actors.MongoDBSystem` has changed to trait.
- The type hierarchy of class `reactivemongo.api.commands.DefaultWriteResult` has changed in new version; no longer inherits from `java.lang.Exception`.
  * method `fillInStackTrace()` is removed
  * method `isUnauthorized()` is removed
  * method `getMessage()` is removed
  * method `isNotAPrimaryError()` is removed
- The type hierarchy of class `reactivemongo.api.commands.UpdateWriteResult` has changed in new version. No longer inherits from `java.lang.Exception`;
  * method `fillInStackTrace()` is removed
  * method `isUnauthorized()` is removed
  * method `getMessage()` is removed
- method `filename()` in class `reactivemongo.api.gridfs.DefaultFileToSave` has now a different result type; was: `String`, is now: `Option[String]`.
- In class `reactivemongo.api.gridfs.DefaultReadFile`;
  * field `length` in  has now a different result type; was: `Int`, is now: `Long`;
  * field `filename` has now a different result type; was: `String`, is now: `Option[String]`.
- The method `filename()` in interface `reactivemongo.api.gridfs.BasicMetadata` has now a different result type; was: `String`, is now: `Option[String]`
- In the case class `reactivemongo.api.MongoConnectionOptions`, the constructor has 2 extra properties `writeConcern` and `readPreference`.
- The case class `reactivemongo.api.gridfs.DefaultFileToSave` has changed to class.
- In `reactivemongo.api.commands.AggregationFramework`;
  * the type `PipelineStage` is removed
  * the type `DocumentStage` is removed
  * the type `DocumentStageCompanion` is removed
  * the type `PipelineStageDocumentProducer` is removed
  * the types of the parameter for the constructor of `Aggregate` have changed
  * the type `AggregateCursorOptions` is removed
- In the class `reactivemongo.api.commands.AggregationFramework#Aggregate`;
  * method `needsCursor()` is removed
  * method `cursorOptions()` is removed
- The type hierarchy of trait `reactivemongo.api.commands.WriteResult` has changed in new version. No longer inherits from `reactivemongo.core.errors.DatabaseException`, `scala.util.control.NoStackTrace`, `reactivemongo.core.errors.ReactiveMongoException`
- For the object `reactivemongo.core.commands.Authenticate`;
  * The type hierarchy of has changed in new version. No longer inherits from `reactivemongo.core.commands.BSONCommandResultMaker` and `reactivemongo.core.commands.CommandResultMaker`.
  * method `apply(reactivemongo.bson.BSONDocument)` is removed
  * method `apply(reactivemongo.core.protocol.Response)` is removed
- For the type `reactivemongo.api.commands.LastError`, the properties `writeErrors` and `writeConcernError` have been added.
- In the case class `reactivemongo.api.commands.CollStatsResult`, the field `maxSize` has been added.
- The field `s` in class `reactivemongo.api.commands.GetLastError#TagSet` is renamed to `tag`
- In the object `reactivemongo.api.commands.FindAndModifyCommand#FindAndModify`, the parameter types of the method `apply` have changed.
- In the class `reactivemongo.api.commands.FindAndModifyCommand#Update`, the type of the parameter `update` is now `Document`; was `java.lang.Object`.
- In the class `reactivemongo.api.MongoConnection`;
  * method `ask(reactivemongo.core.protocol.CheckedWriteRequest)` is removed
  * method `ask(reactivemongo.core.protocol.RequestMaker,Boolean)` is removed
  * method `waitForPrimary(scala.concurrent.duration.FiniteDuration)` is removed
- In trait `reactivemongo.api.collections.GenericQueryBuilder`, the field `maxTimeMsOption` is added.
- The field `prefixedField` is removed from class `reactivemongo.api.commands.AggregationFramework#Unwind`.
- The field `name` is removed from the pipeline stages for `reactivemongo.api.commands.AggregationFramework`.
- The interface `reactivemongo.api.commands.CursorCommand` does not have a correspondent in new version.
- The field `maxTimeMsOption` is added to the type `reactivemongo.api.collections.bson.BSONQueryBuilder`.
- The declaration of class `reactivemongo.core.nodeset.Authenticating` has changed to interface.

### Stats

Here is the list of the commits included in this release (since 0.11, the top commit is the most recent one):

~~~
$ git shortlog -s -n refs/tags/0.11.0..0.12.0
   129  Cédric Chantepie
     2  Maris Ruskulis
     2  Claudio Bley
     1  Alois Cochard
     1  Sam Rottenberg
     1  Thibault Duplessis
     1  Viktor Taranenko
     1  Francisco José Canedo Dominguez
~~~
