---
layout: default
major_version: 1.0
title: Connect to the database
---

## Connect to the database

The first thing you need, is to create a new [`AsyncDriver`](https://javadoc.io/static/org.reactivemongo/reactivemongo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/AsyncDriver.html) instance.

{% highlight scala %}
val driver1 = new reactivemongo.api.AsyncDriver
{% endhighlight %}

Then you can [connect](https://javadoc.io/static/org.reactivemongo/reactivemongo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/AsyncDriver.html#connect(uriStrict:String):scala.concurrent.Future[reactivemongo.api.MongoConnection]) to a MongoDB server.

{% highlight scala %}
import scala.concurrent.Future
import reactivemongo.api.MongoConnection

val connection3: Future[MongoConnection] = driver1.connect(List("localhost"))
{% endhighlight %}

A `AsyncDriver` instance manages the shared resources (e.g. the [actor system](http://akka.io) for the asynchronous processing); A connection manages a pool of network channels.
In general, a `AsyncDriver` or a [`MongoConnection`](https://javadoc.io/static/org.reactivemongo/reactivemongo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/MongoConnection.html) should not be instantiated more than once.

You can provide a list of one or more servers, the driver will guess if it's a standalone server or a replica set configuration. Even with one replica node, the driver will probe for other nodes and add them automatically.

### Connection options

Some options can be provided while creating a connection.

{% highlight scala %}
import reactivemongo.api.MongoConnectionOptions

val conOpts = MongoConnectionOptions(/* connection options */)
val connection4 = driver1.connect(List("localhost"), options = conOpts)
{% endhighlight %}

The following options can be used with `MongoConnectionOptions` to configure the connection behaviour.

*Authentication:*

- **`authSource`**: DEPRECATED since 0.13, see `authenticationDatabase`
- **`authMode`**: DEPRECATED since 0.14, see `authenticationMechanism`
- **`authenticationDatabase`**: (optional) The database source for authentication credentials.
- **`authenticationMechanism`**: (optional) The authentication mechanism, by default set to `scram-sha1` for [SCRAM-SHA-1](http://docs.mongodb.org/manual/core/authentication/#scram-sha-1-authentication). Can be configured with:
  - `scram-sha1` (the default since MongoDB 3.x),
  - `scram-sha256` (since MongoDB 4.0),
  - `mongocr` for the backward compatible [MONGODB-CR](http://docs.mongodb.org/manual/core/authentication/#mongodb-cr-authentication),
  - `x509` for [x.509 certificate authentication](https://docs.mongodb.com/manual/core/security-x.509/#security-auth-x509).

*SSL & certificates:*

- **`sslEnabled`**: DEPRECATED, see `ssl`
- **`ssl`**: (optional) It enables the SSL support for the connection (`true|false`, default is `false`).
- **`sslAllowsInvalidCert`**: (optional) If `sslEnabled` is true, this one indicates whether to accept invalid certificates (e.g. self-signed) (`true|false`, default is `false`).
- **`keyStore`**: (optional) An URI to a key store (e.g. `file:///path/to/keystore.p12`).
- **`keyStorePassword`**: (optional) If `keyStore` is set, then provides the password to load it (if required).
- **`keyStoreType`**: (optional) If `keyStore` is set, indicates the [type of the store](https://docs.oracle.com/javase/7/docs/technotes/guides/security/StandardNames.html#KeyStore).

The option `ssl` is needed if the MongoDB server is requiring SSL (`mongod --sslMode requireSSL`). The related option `sslAllowsInvalidCert` is required if the server allows invalid certificate (`mongod --sslAllowInvalidCertificates`).

> [SNI](https://en.wikipedia.org/wiki/Server_Name_Indication) is supported for the SSL connection.

*Network, timeouts & failover:*

- **`connectTimeoutMS`**: The [number of milliseconds](https://docs.mongodb.org/manual/reference/connection-string/#urioption.connectTimeoutMS) to wait for a connection to be established before giving up.
- [**`maxIdleTimeMS`**](https://docs.mongodb.com/manual/reference/connection-string/#urioption.maxIdleTimeMS): The maximum number of milliseconds that a connection can remain idle in the pool before being removed and closed.
- **`rm.tcpNoDelay`**: TCPNoDelay boolean flag (`true|false`).
- **`rm.keepAlive`**: TCP KeepAlive boolean flag (`true|false`).
- **`rm.nbChannelsPerNode`**: The number of user channels (connections) per node (default: 10). Note that an extra signaling channel is always created, to manage the pool state.
- **`rm.maxInFlightRequestsPerChannel`** (EXPERIMENTAL): The maximum number of in flight/concurrent requests per user channel (default: 200).
- [**`heartbeatFrequencyMS`**](https://github.com/mongodb/specifications/blob/master/source/server-discovery-and-monitoring/server-discovery-and-monitoring.rst#heartbeatfrequencyms) (formerly `rm.monitorRefreshMS`): The interval (in milliseconds) used by the ReactiveMongo monitor to refresh the node set (default: 10s); The minimal value is 100ms.
- **`rm.failover`**: The default [failover strategy](https://javadoc.io/static/org.reactivemongo/reactivemongo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/FailoverStrategy.html).
  - `default`: The default/minimal strategy, with 10 retries with an initial delay of 100ms and a delay factor of `retry count * 1.25` (100ms .. 125ms, 250ms, 375ms, 500ms, 625ms, 750ms, 875ms, 1s, 1125ms, 1250ms).
  - `remote`: The strategy for remote MongoDB node(s); Same as default but with 16 retries.
  - `strict`: A more strict strategy; Same as default but with only 5 retries.
  - `<delay>:<retries>x<factor>`: The definition of a custom strategy;
      - *delay*: The [initial delay](https://javadoc.io/static/org.reactivemongo/reactivemongo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/FailoverStrategy.html#initialDelay:scala.concurrent.duration.FiniteDuration) as a finite duration string accepted by the [`Duration` factory](http://www.scala-lang.org/api/current/index.html#scala.concurrent.duration.Duration$@apply(s:String):scala.concurrent.duration.Duration).
      - *retries*: The number of retry (`Int`).
      - *factor*: The `Double` value to multiply the retry counter with, to define the delay factor (`retryCount * factor`).

*Read isolation & consistency:*

- **`writeConcern`**: The default [write concern](http://docs.mongodb.org/manual/reference/write-concern/) (default: `acknowledged`).
  - **`unacknowledged`**: Option `w` set to 0, journaling off (`j`), `fsync` off, no timeout.
  - **`acknowledged`**: Option `w` set to 1, journaling off, `fsync` off, no timeout.
  - **`journaled`**: Option `w` set to 1, journaling on, `fsync` off, no timeout.
- **`w`**: The [option `w`](https://docs.mongodb.com/manual/reference/connection-string/#urioption.w) for the default write concern. If `writeConcern` is specified, its `w` will be replaced by this `w`.
  - `majority`: The write operations have to be propagated to the majority of voting nodes.
  - `0`: Disable the acknowledgement.
  - `1`: Acknowledgement from the standalone server or primary one.
  - *positive integer*: Acknowledgement by at least the specified number of replica set members.
  - [tag](http://docs.mongodb.org/manual/tutorial/configure-replica-set-tag-sets/#replica-set-configuration-tag-sets): Acknowledgement by the member of the replica set matching the given tag.
- **`journal`**: Toggle [journaling](https://docs.mongodb.com/manual/reference/connection-string/#urioption.journal) on the default write concern. Of `writeConcern` is specified, its `j` will be replaced by this `writeConcernJ` boolean flag (`true|false`).
- **`wtimeoutMS`**: The [time limit](https://docs.mongodb.com/manual/reference/connection-string/#urioption.wtimeoutMS) (in milliseconds) for the default write concern. If `writeConcern` is specified, its timeout is replaced by this one.
- **`readPreference`**: The default [read preference](../advanced-topics/read-preferences.html) (`primary|primaryPreferred|secondary|secondaryPreferred|nearest`) (default is `primary`).
  - [`nearest`](https://docs.mongodb.com/manual/reference/read-preference/#nearest): Do not consider whether nodes are primary or secondary, but select one according how fast it is to answer an `isMaster` request (ping time).
- **`readConcernLevel`**: The level for the default [read concern](https://docs.mongodb.com/manual/reference/read-concern/#read-concern-levels).

- **`appName`**: The optional application name

If the connection pool is defined by an URI, then the options can be given after the `?` separator:

{% highlight javascript %}
mongodb.uri = "mongodb://user:pass@host1:27017,host2:27018,host3:27019/mydatabase?authenticationMechanism=scram-sha1&rm.tcpNoDelay=true"
{% endhighlight %}

[See: Connect using MongoDB URI](#connect-using-mongodb-uri)

### Connecting to a Replica Set

ReactiveMongo provides support for replica sets as follows.

- The driver will detect if it is connected to a replica set.
- It will probe for the other nodes in the set and connect to them.
- It will detect when the primary has changed and guess which is the new one.
- It will allow running queries on secondaries, if allowed by the read preference (See the [MongoDB documentation](http://docs.mongodb.org/manual/applications/replication/#replica-set-read-preference) for more details about querying secondary nodes).

Connecting to a replica set is pretty much the same as connecting to a unique server. You may have notice that the connection argument is a `List[String]`, so more than one node can be specified.

{% highlight scala %}
val servers6 = List("server1:27017", "server2:27017", "server3:27017")
val connection6 = driver1.connect(servers6)
{% endhighlight %}

There is no obligation to give all the nodes in the replica set. Actually, just one of them is required.
ReactiveMongo will ask the nodes it can reach for the addresses of the other nodes in the replica set. Obviously it is better to give at least 2 or more nodes, in case of unavailability of one node at the start of the application.

### Using many connection instances

In some (rare) cases it is perfectly viable to create as many [`MongoConnection`](https://javadoc.io/static/org.reactivemongo/reactivemongo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/MongoConnection.html) instances you need, from a single [`AsyncDriver`](https://javadoc.io/static/org.reactivemongo/reactivemongo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/AsyncDriver.html) instance.

In that case, you will get different connection pools. This is useful when your application has to connect to two or more independent MongoDB nodes (i.e. that do not belong to the same replica set), or different replica sets.

{% highlight scala %}
val serversReplicaSet1 = List("rs11", "rs12", "rs13")
val connectionReplicaSet1 = driver1.connect(serversReplicaSet1)

val serversReplicaSet2 = List("rs21", "rs22", "rs23")
val connectionReplicaSet2 = driver1.connect(serversReplicaSet2)
{% endhighlight %}

### Handling Authentication

There are two ways to give ReactiveMongo your credentials.

It can be done using [`driver.connect`](https://javadoc.io/static/org.reactivemongo/reactivemongo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/AsyncDriver.html#connect(nodes:Seq[String],options:reactivemongo.api.MongoConnectionOptions):scala.concurrent.Future[reactivemongo.api.MongoConnection]).

{% highlight scala %}
import reactivemongo.api.MongoConnectionOptions

def servers7: List[String] = List("server1", "server2")

val dbName = "somedatabase"
val userName = "username"
val password = "password"
val connection7 = driver1.connect(
  nodes = servers7,
  options = MongoConnectionOptions(
    credentials = Map(dbName -> MongoConnectionOptions.
      Credential(userName, Some(password)))))
{% endhighlight %}

Using this `connection` function [with an URI](#connect-using-mongodb-uri) allows to indicates the credentials in this URI.

There is also a [`authenticate`](https://javadoc.io/static/org.reactivemongo/reactivemongo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/DB.html#authenticate(user:String,password:String)(implicitec:scala.concurrent.ExecutionContext):scala.concurrent.Future[reactivemongo.api.commands.SuccessfulAuthentication]) function for the database references.

{% highlight scala %}
import scala.concurrent.{ ExecutionContext, Future },
  ExecutionContext.Implicits.global

import reactivemongo.api.MongoConnection

def authenticateDB(con: MongoConnection): Future[Unit] = {
  def username = "anyUser"
  def password = "correspondingPass"

  val futureAuthenticated = con.authenticate("mydb", username, password)

  futureAuthenticated.map { _ =>
    // doSomething
  }
}
{% endhighlight %}

Like any other operation in ReactiveMongo, authentication is done asynchronously.

### Connect Using MongoDB URI

You can also give the connection information as a [URI](http://docs.mongodb.org/manual/reference/connection-string/):

    mongodb://[username:password@]host1[:port1][,host2[:port2],...[,hostN[:portN]]][/[database][?[option1=value1][&option2=value2][...&optionN=valueN]]

If credentials and the database name are included in the URI, ReactiveMongo will authenticate the connections on that database.

{% highlight scala %}
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global
import reactivemongo.api.{ AsyncDriver, MongoConnection }

// connect to the replica set composed of `host1:27018`, `host2:27019` and `host3:27020`
// and authenticate on the database `somedb` with user `user123` and password `passwd123`
val uri = "mongodb://user123:passwd123@host1:27018,host2:27019,host3:27020/somedb"

def connection7(driver: AsyncDriver): Future[MongoConnection] = for {
  parsedUri <- MongoConnection.fromString(uri)
  con <- driver.connect(parsedUri)
} yield con
{% endhighlight %}

The following example is using a connection to asynchronously resolve a database.

{% highlight scala %}
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global
import reactivemongo.api.{ AsyncDriver, MongoConnection }

val mongoUri = "mongodb://host:port/db"

val driver = new AsyncDriver

val database = for {
  uri <- MongoConnection.fromString(mongoUri)
  con <- driver.connect(uri)
  dn <- Future(uri.db.get)
  db <- con.database(dn)
} yield db

database.onComplete {
  case resolution =>
    println(s"DB resolution: $resolution")
    driver.close()
}
{% endhighlight %}

Note that [DNS seedlist](https://docs.mongodb.com/manual/reference/connection-string/#dns-seedlist-connection-format) is supported, using `mongodb+srv://` scheme in the connection URI.

{% highlight scala %}
import reactivemongo.api._

def seedListCon(driver: AsyncDriver) =
  driver.connect("mongodb+srv://usr:pass@mymongo.mydomain.tld/mydb")
{% endhighlight %}

*See:*

- How to [connect to MongoDB Atlas](./mongodb-atlas.html)
- How to [connect to Azure CosmosDB](./azure-cosmos.html)
- How to [connect to Amazon DocumentDB](./amazon-documentdb.html)
- How to [connect to Alibaba ApsaraDB](./alibaba-apsaradb.html)

### Netty native

ReactiveMongo is internally using (as a shaded dependency) [Netty 4.1.x](http://netty.io/wiki/new-and-noteworthy-in-4.1.html).

It makes possible to use the native optimization of Netty. To do so, the `reactivemongo-shaded-native` must be added as runtime dependency, with the appropriate version.

{% highlight ocaml %}
// For Mac OS X (x86-64), kqueue native support
libraryDependencies += "org.reactivemongo" % "reactivemongo-shaded-native" % "{{page.major_version}}-osx-x86-64" % "runtime"

// For Linux (x86-64), kqueue native support
libraryDependencies += "org.reactivemongo" % "reactivemongo-shaded-native" % "{{page.major_version}}-linux-x86-64" % "runtime"
{% endhighlight %}

In order to make sure such optimization is loaded, you can enable the `INFO` level for the logger `reactivemongo.core.netty.Pack` (e.g. in your logback configuration), then check for a log entry containing "NettyPack".

```
16:03:43.098 ReactiveMongo INFO  [r.c.n.Pack] :: Instantiated NettyPack(class reactivemongo.io.netty.channel.kqueue.KQueueSocketChannel)
```

### Additional Notes

**[`MongoConnection`](https://javadoc.io/static/org.reactivemongo/reactivemongo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/MongoConnection.html) stands for a pool of connections.**

Do not get confused here: a `MongoConnection` is a _logical_ connection, not a physical one (not a network channel); It's actually a _connection pool_. By default, a `MongoConnection` creates 10 _physical_ network channels to each node; It can be tuned this by setting the `rm.nbChannelsPerNode` options (see the [connection options](#connection-options]).

**Why are `AsyncDriver` and `MongoConnection` distinct?**

They manage two different things. `AsyncDriver` holds the actor system, and `MongoConnection` the references to the actors. This is useful because it enables to work with many different single nodes or replica sets. Thus, your application can communicate with different replica sets or single nodes, with only one `AsyncDriver` instance.

**Creation Costs:**

`AsyncDriver` and `MongoConnection` involve creation costs:

- the driver creates a new [`actor system`](http://akka.io/),
- and the connection, will connect to the servers (creating network channels).

It is also a good idea to store the driver and connection instances to reuse them.

On the contrary, [`DB`](https://javadoc.io/static/org.reactivemongo/reactivemongo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/DB.html) and [`Collection`](../../api/reactivemongo/api/Collection) are just plain objects that store references and nothing else.
Getting such references is lightweight, and calling [`connection.database(..)`](https://javadoc.io/static/org.reactivemongo/reactivemongo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/MongoConnection.html#database(name:String,failoverStrategy:reactivemongo.api.FailoverStrategy)(implicitec:scala.concurrent.ExecutionContext):scala.concurrent.Future[reactivemongo.api.DB]) or [`db.collection(..)`](https://javadoc.io/static/org.reactivemongo/reactivemongo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/DB.html#collection[C%3C:reactivemongo.api.Collection](name:String,failoverStrategy:reactivemongo.api.FailoverStrategy)(implicitproducer:reactivemongo.api.CollectionProducer[C]):C) may be done many times without any performance hit.

> It's generally a good practice not to assign the database and collection references to `val` (even to `lazy val`), as it's better to get a fresh reference each time, to automatically recover from any previous issues (e.g. network failure).

**Virtual Private Network ([VPN](https://en.wikipedia.org/wiki/Virtual_private_network)):**

When connecting to a MongoDB replica set over a VPN, if using IP addresses instead of host names to configure the connection nodes, then it's possible that the nodes are discovered with host names that are only known within the remote network, and so not usable from the driver/client side.

### Troubleshooting

The bellow errors may indicate there is a connectivity and/or network issue.

*Primary not available*

- Error: `reactivemongo.core.actors.Exceptions$PrimaryUnavailableException: MongoError['No primary node is available! ...']`
- In logging: "The primary is unavailable, is there a network problem?" (not critical if no application error occurs)

*Node set not reachable*

- Error: `reactivemongo.core.actors.Exceptions$NodeSetNotReachable: MongoError['The node set can not be reached! Please check your network connectivity ...']`
- In logging: "The entire node set is unreachable, is there a network problem?" (not critical if no application error occurs)

**Diagnostic:**

If one of the error is seen, first retry/refresh to check it wasn't a temporary system/network issue. If the issue is then reproduced, the following can be checked.

*Are the DB nodes accessible from the node running the application?*

- Using the [MongoDB Shell](https://docs.mongodb.com/manual/reference/mongo-shell/): `mongo primary-host:primary-port/name-of-database` (replace the primary host & port and the database name with the same used in the ReactiveMongo connection URI).
- With the [SBT Playground](https://github.com/cchantep/RM-SBT-Playground), using the same connection URI.
- **Possible causes:** Broken network, authentication issue (before 0.13, MONGODB-CR is the default mode; See the [`authenticationMechanism` option](#connection-options)), SSL issue (check the `sslEnabled` and `sslAllowsInvalidCert` options).

*Is the connection URI used with ReactiveMongo valid?*

If using the [Play module](./play.html), the `strictUri` setting can be enabled (e.g. `mongodb.connection.strictUri=true`).

Connect without any non mandatory options (e.g. `connectTimeoutMS`), using the [SBT Playground](https://github.com/cchantep/RM-SBT-Playground) to try the alternative URI.

Using the following code, make sure there is no authentication issue.

{% highlight scala %}
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.api._

def troubleshootAuth() = {
  val strictUri = "mongodb://..."
  val dbname = "db-name"
  val user = "your-user"
  val pass = "your-password"
  val driver = AsyncDriver()
  
  driver.connect(strictUri).flatMap {
    _.authenticate(dbname, user, pass)
  }.onComplete {
    case res => println(s"Auth: $res")
  }
}

troubleshootAuth()

// Would display something like `Auth: Failure(...)` in case of failure
{% endhighlight %}

*Connecting to a [MongoDB ReplicaSet](https://docs.mongodb.com/manual/replication/), is status ok?*

- Using the [MongoDB Shell](https://docs.mongodb.com/manual/reference/mongo-shell/) to connect to the primary node, execute `rs.status()`.

**Additional actions:**

With the [ReactiveMongo logging](./setup.html#logging) enabled, more details can be found (see a trace example thereafter).

{% highlight text %}{% raw %}
reactivemongo.core.actors.Exceptions$InternalState: null (<time:1469208071685>:-1)
reactivemongo.ChannelClosed(-2079537712, {{NodeSet None Node[localhost:27017: Primary (0/0 available connections), latency=5], auth=Set() }})(<time:1469208071685>)
reactivemongo.Shutdown(<time:1469208071673>)
reactivemongo.ChannelDisconnected(-2079537712, {{NodeSet None Node[localhost:27017: Primary (1/1 available connections), latency=5], auth=Set() }})(<time:1469208071663>)
reactivemongo.ChannelClosed(967102512, {{NodeSet None Node[localhost:27017: Primary (1/2 available connections), latency=5], auth=Set() }})(<time:1469208071663>)
reactivemongo.ChannelDisconnected(967102512, {{NodeSet None Node[localhost:27017: Primary (2/2 available connections), latency=5], auth=Set() }})(<time:1469208071663>)
reactivemongo.ChannelClosed(651496230, {{NodeSet None Node[localhost:27017: Primary (2/3 available connections), latency=5], auth=Set() }})(<time:1469208071663>)
reactivemongo.ChannelDisconnected(651496230, {{NodeSet None Node[localhost:27017: Primary (3/3 available connections), latency=5], auth=Set() }})(<time:1469208071663>)
reactivemongo.ChannelClosed(1503989210, {{NodeSet None Node[localhost:27017: Primary (3/4 available connections), latency=5], auth=Set() }})(<time:1469208071662>)
reactivemongo.ChannelDisconnected(1503989210, {{NodeSet None Node[localhost:27017: Primary (4/4 available connections), latency=5], auth=Set() }})(<time:1469208071662>)
reactivemongo.ChannelClosed(-228911231, {{NodeSet None Node[localhost:27017: Primary (4/5 available connections), latency=5], auth=Set() }})(<time:1469208071662>)
reactivemongo.ChannelDisconnected(-228911231, {{NodeSet None Node[localhost:27017: Primary (5/5 available connections), latency=5], auth=Set() }})(<time:1469208071662>)
reactivemongo.ChannelClosed(-562085577, {{NodeSet None Node[localhost:27017: Primary (5/6 available connections), latency=5], auth=Set() }})(<time:1469208071662>)
reactivemongo.ChannelDisconnected(-562085577, {{NodeSet None Node[localhost:27017: Primary (6/6 available connections), latency=5], auth=Set() }})(<time:1469208071662>)
reactivemongo.ChannelClosed(-857553810, {{NodeSet None Node[localhost:27017: Primary (6/7 available connections), latency=5], auth=Set() }})(<time:1469208071662>)
{% endraw %}{% endhighlight %}

The [JMX module](../release-details.html#monitoring) can be used to check how the node set is seen by the driver.

[Previous: Get started](./getstarted.html) / [Next: Database and collections](./database-and-collection.html)
