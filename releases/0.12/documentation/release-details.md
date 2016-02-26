---
layout: default
title: ReactiveMongo 0.12 - Release details
---

## ReactiveMongo {{site._0_12_latest_minor}} – Release details

**What's new?**

> **Documentation**: The documentation is available [online](index.html). You can also browse the [API](../api/index.html).

TODO:

- Compatibility from MongoDB 2.6 up to 3.2
- MongoConnection.database instead of .db (or .apply)

- collection.{ findAndModify, findAndUpdate, findAndUpdate, aggregate }
- Distinct command and collection.distinct
- $sample aggregation stage
- redact pipeline op
- geoNear pipeline op
- out pipeline op

- default read pref, write concern in conf
- update netty (will be shaded); To avoid conflict (dependency hell), the netty dependency excluded from the Play module (as provided by Play)
- Play Formatter instances
- Play PathBindable instances

- BSON handler for java.util.Date
- BSON readers & writers combinators (AbstractMethodError if using custom lib pull older BSON dependency)
- #349: BSONTimestamp improvements & tests: `.time` and `.ordinal` extracted from the raw value

- #399 In the trait [`reactivemongo.api.collections.GenericQueryBuilder`](../api/index.html#reactivemongo.api.collections.GenericQueryBuilder), the field `maxTimeMsOption` is added.
- collection.drop doesn't fail if not exist
- Explain mode on query builder
- Resync admin command

**Playframework**

- Separate Play JSON module: serialization pack without the Play module
- JSON conversions
  - BSONJavaScript
  - BSONUndefined

When using the **[support for Play JSON](json/overview.html)**, if the following error occurs, it's necessary to make sure `import reactivemongo.play.json._` is used, to import default BSON/JSON conversions.

{% highlight text %}
No Json serializer as JsObject found for type play.api.libs.json.JsObject.
Try to implement an implicit OWrites or OFormat for this type.
{% endhighlight %}

**Result Cursor**

- Cursor from aggregation result (aggregate1)
- Use `ErrorHandler` with the `Cursor` functions, instead of `stopOnError: Boolean`

- Separate Iteratee module

- For the type `reactivemongo.api.commands.LastError`, the properties `writeErrors` and `writeConcernError` have been added.
- In the case class `reactivemongo.api.commands.CollStatsResult`, the field `maxSize` has been added.

- Log4J is replaced by [SLF4J](http://www.slf4j.org/) (see the [documentation](./index.html#logging))

> MongoDB versions older than 2.6 are not longer supported by ReactiveMongo.

### Breaking changes

The [Typesafe Migration Manager](https://github.com/typesafehub/migration-manager#migration-manager-for-scala) has been setup on the ReactiveMongo repository.
It will validate all the future contributions, and help to make the API more stable.

For the current 0.12 release, it has detected the following breaking changes.

**Connection**

- In the case class [`reactivemongo.api.MongoConnectionOptions`](../api/index.html#reactivemongo.api.MongoConnectionOptions), the constructor has 2 extra properties [`writeConcern`](../api/index.html#reactivemongo.api.commands.package@WriteConcern=reactivemongo.api.commands.GetLastError) and [`readPreference`](../api/index.html#reactivemongo.api.ReadPreference).
- In the class [`reactivemongo.api.MongoConnection`](../api/index.html#reactivemongo.api.MongoConnection);
  * method `ask(reactivemongo.core.protocol.CheckedWriteRequest)` is removed
  * method `ask(reactivemongo.core.protocol.RequestMaker,Boolean)` is removed
  * method `waitForPrimary(scala.concurrent.duration.FiniteDuration)` is removed

Since [release 0.11](../../0.11/documentation/release-details.html), the package [`reactivemongo.api.collections.default`](http://reactivemongo.org/releases/0.10/api/index.html#reactivemongo.api.collections.default.package) has been refactored as the package [`reactivemongo.api.collections.bson`](http://reactivemongo.org/releases/0.11/api/index.html#reactivemongo.api.collections.bson.package).
If you get a compilation error like the following one, you need to update the corresponding imports.

{% highlight text %}
object default is not a member of package reactivemongo.api.collections
[error] import reactivemongo.api.collections.default.BSONCollection
{% endhighlight %}


**Operation results**

- The type hierarchy of the trait [`reactivemongo.api.commands.WriteResult`](../api/index.html#reactivemongo.api.commands.WriteResult) has changed in new version. It's no longer an `Exception`, and no longer inherits from [`reactivemongo.core.errors.DatabaseException`](../api/index.html#reactivemongo.core.errors.DatabaseException), `scala.util.control.NoStackTrace`, `reactivemongo.core.errors.ReactiveMongoException`
- The type hierarchy of the classes [`reactivemongo.api.commands.DefaultWriteResult`](../api/index.html#reactivemongo.api.commands.DefaultWriteResult) and [`reactivemongo.api.commands.UpdateWriteResult`](../api/index.html#reactivemongo.api.commands.UpdateWriteResult) have changed in new version; no longer inherits from `java.lang.Exception`.
  * method `fillInStackTrace()` is removed
  * method `isUnauthorized()` is removed
  * method `getMessage()` is removed
  * method `isNotAPrimaryError()` is removed
- In class [`reactivemongo.api.commands.Upserted`](../api/index.html#reactivemongo.api.commands.Upserted);
  * The constructor has changed; was `(Int, java.lang.Object)`, is now: `(Int, reactivemongo.bson.BSONValue)`.
  * The field `_id`  has now a different result type; was: `java.lang.Object`, is now: `reactivemongo.bson.BSONValue`.
- In the case class [`reactivemongo.api.commands.GetLastError.TagSet`](reactivemongo.api.commands.GetLastError$$TagSet), the field `s`  is renamed to `tag`.

**Aggregation framework**

- In the trait [`reactivemongo.api.commands.AggregationFramework`](../api/index.html#reactivemongo.api.commands.AggregationFramework);
  * the type `PipelineStage` is removed
  * the type `DocumentStage` is removed
  * the type `DocumentStageCompanion` is removed
  * the type `PipelineStageDocumentProducer` is removed
  * the type `AggregateCursorOptions` is removed
  * the field `name` is removed from all the pipeline stages
- In the case class [`reactivemongo.api.commands.AggregationFramework#Aggregate`](../api/index.html#reactivemongo.api.commands.AggregationFramework$Aggregate);
  * field `needsCursor` is removed
  * field `cursorOptions` is removed
- In case classes [`reactivemongo.api.commands.AggregationFramework.Limit`](../api/index.html#reactivemongo.api.commands.AggregationFramework@LimitextendsAggregationFramework.this.PipelineOperatorwithProductwithSerializable) and [`reactivemongo.api.commands.AggregationFramework.Skip`](../api/index.html#reactivemongo.api.commands.AggregationFramework@SkipextendsAggregationFramework.this.PipelineOperatorwithProductwithSerializable);
  * field `n` is removed
- In the case class [`reactivemongo.api.commands.AggregationFramework#Unwind`](../api/index.html#reactivemongo.api.commands.AggregationFramework$Unwind), the field `prefixedField` is removed.

**Operations and commands**

- The enumerated type `reactivemongo.api.SortOrder` is removed, as not used in the API.
- The trait `reactivemongo.api.commands.CursorCommand` is removed
- In the case class [`reactivemongo.api.commands.FindAndModifyCommand.FindAndModify`](../api/index.html#reactivemongo.api.commands.FindAndModifyCommand$Update);
  * the field `upsert` (and the corresponding constructor parameter) has been added
  * the type of the field `update` is now `Document`; was `java.lang.Object`.

**GridFS**

- In the trait [`reactivemongo.api.gridfs.ComputedMetadata`](../api/index.html#reactivemongo.api.gridfs.ComputedMetadata), the field `length` has now a different result type; was: `Int`, is now: `Long`
- In the case class [`reactivemongo.api.gridfs.DefaultFileToSave`](../api/index.html#reactivemongo.api.gridfs.DefaultFileToSave) has changed to a plain class, and its method `filename()`  has now a different result type; was: `String`, is now: `Option[String]`.
- In class [`reactivemongo.api.gridfs.DefaultReadFile`](../api/index.html#reactivemongo.api.gridfs.DefaultReadFile);
  * field `length` in  has now a different result type; was: `Int`, is now: `Long`;
  * field `filename` has now a different result type; was: `String`, is now: `Option[String]`.
- In the trait [`reactivemongo.api.gridfs.BasicMetadata`](../api/index.html#reactivemongo.api.gridfs.BasicMetadata), the field `filename` has now a different result type; was: `String`, is now: `Option[String]`.

**Core/internal**

- The class [`reactivemongo.core.commands.Authenticate`](../api/index.html#reactivemongo.core.commands.Authenticate) is now deprecated;
  * The type hierarchy of has changed in new version. No longer inherits from `reactivemongo.core.commands.BSONCommandResultMaker` and `reactivemongo.core.commands.CommandResultMaker`.
  * method `apply(reactivemongo.bson.BSONDocument)` is removed
  * method `apply(reactivemongo.core.protocol.Response)` is removed
  * see [`reactivemongo.core.commands.CrAuthenticate`](../api/index.html#reactivemongo.core.commands.CrAuthenticate) (only for the legacy MongoDB CR authentication)
- The class [`reactivemongo.core.actors.MongoDBSystem`](../api/index.html#reactivemongo.core.actors.MongoDBSystem) has changed to a trait.
- The declaration of class [`reactivemongo.core.nodeset.Authenticating`](../api/index.html#reactivemongo.core.nodeset.Authenticating) has changed to a sealed trait.