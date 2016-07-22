---
layout: default
title: ReactiveMongo 0.11 - Connect to the database
---

## Connect to the database

The first thing you need, is to create a new [`MongoDriver`](../../api/index.html#reactivemongo.api.MongoDriver) instance.

{% highlight scala %}
val driver1 = new reactivemongo.api.MongoDriver
{% endhighlight %}

Without any parameter, the driver uses a default configuration. Obviously, you may want to indicate a specific configuration.

{% highlight scala %}
def customConfig: com.typesafe.config.Config = ???

val driver2 = new reactivemongo.api.MongoDriver(Some(customConfig))
{% endhighlight %}

Then you can [connect](../../api/index.html#reactivemongo.api.MongoDriver@connection(parsedURI:reactivemongo.api.MongoConnection.ParsedURI):scala.util.Try[reactivemongo.api.MongoConnection]) to a MongoDB server.

{% highlight scala %}
import reactivemongo.api.MongoConnection

val connection3 = driver1.connection(List("localhost"))
{% endhighlight %}

A `MongoDriver` instance manages the shared resources (e.g. the [actor system](http://akka.io) for the asynchronous processing); A connection manages a pool of network channels.
In general, a `MongoDriver` or a [`MongoConnection`](../../api/index.html#reactivemongo.api.MongoConnection) should not be instantiated more than once.

You can provide a list of one or more servers, the driver will guess if it's a standalone server or a replica set configuration. Even with one replica node, the driver will probe for other nodes and add them automatically.

### Connection options

Some options can be provided while creating a connection.

{% highlight scala %}
import reactivemongo.api.MongoConnectionOptions

val conOpts = MongoConnectionOptions(/* connection options */)
val connection4 = driver2.connection(List("localhost"), options = conOpts)
{% endhighlight %}

The following options can be used with `MongoConnectionOptions` to configure the connection behaviour.

- **authSource**: The database source for authentication credentials.
- **authMode**: The authentication mode. By default, it's the backward compatible [MONGODB-CR](http://docs.mongodb.org/manual/core/authentication/#mongodb-cr-authentication) which is used. If this options is set to `scram-sha1`, then the [SCRAM-SHA-1](http://docs.mongodb.org/manual/core/authentication/#scram-sha-1-authentication) authentication will be selected.
- **connectTimeoutMS**: The number of milliseconds to wait for a connection to be established before giving up.
- **sslEnabled**: It enables the SSL support for the connection (`true|false`).
- **sslAllowsInvalidCert**: If `sslEnabled` is true, this one indicates whether to accept invalid certificates (e.g. self-signed).
- **rm.tcpNoDelay**: TCPNoDelay boolean flag (`true|false`).
- **rm.keepAlive**: TCP KeepAlive boolean flag (`true|false`).
- **rm.nbChannelsPerNode**: Number of channels (connections) per node.
- **writeConcern**: The default [write concern](http://docs.mongodb.org/manual/reference/write-concern/) (default: `acknowledged`).
  - **unacknowledged**: Option `w` set to 0, journaling off (`j`), `fsync` off, no timeout.
  - **acknowledged**: Option `w` set to 1, journaling off, `fsync` off, no timeout.
  - **journaled**: Option `w` set to 1, journaling on, `fsync` off, no timeout.
- **writeConcernW**: The [option `w`](http://docs.mongodb.org/manual/reference/write-concern/#w-option) for the default write concern. If `writeConcern` is specified, its `w` will be replaced by this `writeConcernW`.
  - `majority`: The write operations have to be propagated to the majority of voting nodes.
  - `0`: Disable the acknowledgment.
  - `1`: Acknowledgment from the standalone server or primary one.
  - *positive integer*: Acknowledgment by at least the specified number of replica set members.
  - [tag](http://docs.mongodb.org/manual/tutorial/configure-replica-set-tag-sets/#replica-set-configuration-tag-sets): Acknowledgment by the member of the replica set matching the given tag.
- **writeConcernJ**: Toggle [journaling](http://docs.mongodb.org/manual/reference/write-concern/#j-option) on the default write concern. Of `writeConcern` is specified, its `j` will be replaced by this `writeConcernJ` boolean flag (`true|false`).
- **writeConcernTimeout**: The [time limit](http://docs.mongodb.org/manual/reference/write-concern/#wtimeout) (in milliseconds) for the default write concern. If `writeConcern` is specified, its timeout is replaced by this one.
- **readPreference**: The default [read preference](../advanced-topics/read-preferences.html) (`primary|primaryPreferred|secondary|secondaryPreferred|nearest`) (default is `primary`).

> The option `sslEnabled` is needed if the MongoDB server is requiring SSL (`mongod --sslMode requireSSL`). The related option `sslAllowsInvalidCert` is required is the server allows invalid certificate (`mongod --sslAllowInvalidCertificates`).

If the connection pool is defined by an URI, then the options can be given after the `?` separator:

{% highlight javascript %}
mongodb.uri = "mongodb://user:pass@host1:27017,host2:27018,host3:27019/mydatabase?authMode=scram-sha1&rm.tcpNoDelay=true"
{% endhighlight %}

[See: Connect using MongoDB URI](#connect-using-mongodb-uri)

### Connecting to a Replica Set

ReactiveMongo provides support for replica sets as follows.

- The driver will detect if it is connected to a replica set.
- It will probe for the other nodes in the set and connect to them.
- It will detect when the primary has changed and guess which is the new one.
- It will allow running queries on secondaries if they are explicitely set to SlaveOk (See the [MongoDB documentation](http://docs.mongodb.org/manual/applications/replication/#replica-set-read-preference) for more details about querying secondary nodes).

Connecting to a replica set is pretty much the same as connecting to a unique server. You may have notice that the connection argument is a `List[String]`, so more than one node can be specified.

{% highlight scala %}
val servers6 = List("server1:27017", "server2:27017", "server3:27017")
val connection6 = driver1.connection(servers6)
{% endhighlight %}

There is no obligation to give all the nodes in the replica set – actually, just one of them is required.
ReactiveMongo will ask the nodes it can reach for the addresses of the other nodes in the replica set. Obviously it is better to give at least 2 or more nodes, in case of unavailablity of one node at the start of the application.

### Using many connection instances

In some (rare) cases it is perfectly viable to create as many [`MongoConnection`](../../api/index.html#reactivemongo.api.MongoConnection) instances you need, from a single [`MongoDriver`](../../api/index.html#reactivemongo.api.MongoDriver) instance.

In that case, you will get different connection pools. This is useful when your application has to connect to two or more independent MongoDB nodes (i.e. that do not belong to the same replica set), or different replica sets.

{% highlight scala %}
val serversReplicaSet1 = List("rs11", "rs12", "rs13")
val connectionReplicaSet1 = driver1.connection(serversReplicaSet1)

val serversReplicaSet2 = List("rs21", "rs22", "rs23")
val connectionReplicaSet2 = driver1.connection(serversReplicaSet2)
{% endhighlight %}

### Handling Authentication

There are two ways to give ReactiveMongo your credentials.

It can be done using [`driver.connection`](../../api/index.html#reactivemongo.api.MongoDriver@connection(nodes:Seq[String],options:reactivemongo.api.MongoConnectionOptions,authentications:Seq[reactivemongo.core.nodeset.Authenticate],name:Option[String]):reactivemongo.api.MongoConnection).

{% highlight scala %}
import reactivemongo.core.nodeset.Authenticate

def servers7: List[String] = List("server1", "server2")

val dbName = "somedatabase"
val userName = "username"
val password = "password"
val credentials7 = List(Authenticate(dbName, userName, password))
val connection7 = driver1.connection(servers7, authentications = credentials7)
{% endhighlight %}

Using this `connection` function [with an URI](#connect-using-mongodb-uri) allows to indicates the credentials in this URI.

There is also a [`authenticate`](../../api/index.html#reactivemongo.api.DefaultDB@authenticate(user:String,password:String)(implicittimeout:scala.concurrent.duration.FiniteDuration):scala.concurrent.Future[reactivemongo.core.commands.SuccessfulAuthentication]) function for the database references.

{% highlight scala %}
import scala.concurrent.{ ExecutionContext, Future },
  ExecutionContext.Implicits.global
import scala.concurrent.duration.FiniteDuration

import reactivemongo.api.DefaultDB


def authenticateDB(db: DefaultDB): Future[Unit] = {
  def username = "anyUser"
  def password = "correspondingPass"
  implicit def authTimeout = FiniteDuration(5, "seconds")

  val futureAuthenticated = db.authenticate(username, password)

  futureAuthenticated.map { _ =>
    // doSomething
  }
}
{% endhighlight %}

Like any other operation in ReactiveMongo, authentication is done asynchronously.

### Connect Using MongoDB URI

You can also give the connection information as a [URI](http://docs.mongodb.org/manual/reference/connection-string/):

`mongodb://[username:password@]host1[:port1][,host2[:port2],...[,hostN[:portN]]][/[database][?[option1=value1][&option2=value2][...&optionN=valueN]]`

If credentials and the database name are included in the URI, ReactiveMongo will authenticate the connections on that database.

{% highlight scala %}
import scala.util.Try
import reactivemongo.api.MongoConnection

// connect to the replica set composed of `host1:27018`, `host2:27019` and `host3:27020`
// and authenticate on the database `somedb` with user `user123` and password `passwd123`
val uri = "mongodb://user123:passwd123@host1:27018,host2:27019,host3:27020/somedb"

def connection7(driver: reactivemongo.api.MongoDriver): Try[MongoConnection] =
  MongoConnection.parseURI(uri).map { parsedUri =>
    driver.connection(parsedUri)
  }
{% endhighlight %}

The following example is using a connection to asynchronously resolve a database.

{% highlight scala %}
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global
import reactivemongo.api.{ MongoDriver, MongoConnection }

val mongoUri = "mongodb://host:port/db"

val driver = new MongoDriver

val database = for {
  uri <- Future.fromTry(MongoConnection.parseURI(mongoUri))
  con = driver.connection(uri)
  dn <- Future(uri.db.get)
  db <- con.database(dn)
} yield db

database.onComplete {
  case resolution =>
    println(s"DB resolution: $resolution")
    driver.close()
}
{% endhighlight %}

### Additional Notes

**[`MongoConnection`](../../api/index.html#reactivemongo.api.MongoConnection) stands for a pool of connections.**

Do not get confused here: a `MongoConnection` is a _logical_ connection, not a physical one; it is actually a _connection pool_. By default, a `MongoConnection` creates 10 _physical_ network channels to each node; It can be tuned this by setting the `rm.nbChannelsPerNode` options (see the [connection options](#connection-options]).

**Why are `MongoDriver` and `MongoConnection` distinct?**

They manage two different things. `MongoDriver` holds the actor system, and `MongoConnection` the references to the actors. This is useful because it enables to work with many different single nodes or replica sets. Thus, your application can communicate with different replica sets or single nodes, with only one `MongoDriver` instance.

**Creation Costs:**

`MongoDriver` and `MongoConnection` involve creation costs:

- the driver creates a new [`actor system`](http://akka.io/)),
- and the connection, will connect to the servers (creating network channels).

It is also a good idea to store the driver and connection instances to reuse them.

On the contrary, [`DefaultDB`](../../api/index.html#reactivemongo.api.DefaultDB) and [`Collection`](../../api/index.html#reactivemongo.api.Collection) are just plain objects that store references and nothing else.
Gettting such references is lighweight, and calling [`connection.database(..)`](../../api/index.html#reactivemongo.api.MongoConnection@database(name:String,failoverStrategy:reactivemongo.api.FailoverStrategy)(implicitcontext:scala.concurrent.ExecutionContext):scala.concurrent.Future[reactivemongo.api.DefaultDB]) or [`db.collection(..)`](../../api/index.html#reactivemongo.api.DefaultDB@collection[C%3C:reactivemongo.api.Collection](name:String,failoverStrategy:reactivemongo.api.FailoverStrategy)(implicitproducer:reactivemongo.api.CollectionProducer[C]):C) may be done many times without any performance hit.

**Virtual Private Network ([VPN](https://en.wikipedia.org/wiki/Virtual_private_network)):**

When connecting to a MongoDB replica set over a VPN, if using IP addresses instead of hostnames to configure the connection nodes, then it's possible that the nodes are discovered with hostnames that are only known within the remote network, and so not usable from the driver/client side.

[Previous: Setup](./setup.html) / [Next: Database and collections](./database-and-collection.html)
