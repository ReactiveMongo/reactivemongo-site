---
layout: default
title: ReactiveMongo 0.11 - Connect to the database
---

## Connect to the database

The first thing you need to do is to create a new `Driver` instance.

{% highlight scala %}
val driver1 = new reactivemongo.api.MongoDriver
{% endhighlight %}

Without any parameter, `MongoDriver` uses the default configuration. Obviously, you may want to indicate a specific configuration.

{% highlight scala %}
def typesafeConfig: com.typesafe.config.Config = ???

val driver2 = new reactivemongo.api.MongoDriver(Some(typesafeConfig))
{% endhighlight %}

Then you can connect to a MongoDB server.

{% highlight scala %}
def driver3: reactivemongo.api.MongoDriver = ???

val connection3 = driver3.connection(List("localhost"))
{% endhighlight %}

A `MongoDriver` instance manages an actor system; A connection manages a pool of connections. In general, a `MongoDriver` or a `MongoConnection` should never be instantiated more than once.

You can provide a list of one or more servers; the driver will guess if it's a standalone server or a replica set configuration. Even with one replica node, the driver will probe for other nodes and add them automatically.

Some options can be provided while creating a connection.

{% highlight scala %}
import reactivemongo.api.MongoConnectionOptions

def driver4: reactivemongo.api.MongoDriver = ???

val conOpts = MongoConnectionOptions(/* connection options */)
val connection4 = driver4.connection(List("localhost"), options = conOpts)
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

Getting a database and a collection is pretty easy:

{% highlight scala %}
import scala.concurrent.ExecutionContext.Implicits.global

def connection5: reactivemongo.api.MongoConnection = ???

val db5 = connection5.database("somedatabase")
val collection5 = db5.map(_.collection("somecollection"))
{% endhighlight %}

## Connecting to a replica set

ReactiveMongo provides support for Replica Sets. That means the following:

- The driver will detect if it is connected to a Replica Set;
- It will probe for the other nodes in the set and connect to them;
- It will detect when the primary has changed and guess which is the new one;
- It will allow running queries on secondaries if they are explicitely set to SlaveOk (See the [MongoDB documentation](http://docs.mongodb.org/manual/applications/replication/#replica-set-read-preference) for more details about querying secondary nodes).

Connecting to a Replica Set is pretty much the same as connecting to a unique server. You may have notice that the argument to `driver.connection()` method is a `List[String]`; you can also give more than one node in the replica set.

{% highlight scala %}
def driver6: reactivemongo.api.MongoDriver = ???

val servers6 = List("server1:27017", "server2:27017", "server3:27017")
val connection6 = driver6.connection(servers6)
{% endhighlight %}

There is no obligation to give all the nodes in the replica set – actually, just one of them is required. ReactiveMongo will ask the nodes it can reach for the addresses of the other nodes in the replica set. Obviously it is better to give at least 2 or more nodes, in case of unavailablity of one node at the start of the application.

### Using many `MongoConnection` instances

In some (rare) cases it is perfectly viable to create as many `MongoConnection` instances you need with one `MongoDriver` instance – in that case, you will get different connection pools. This is useful when your application has to connect to two or more independent MongoDB nodes (i.e. that do not belong to the same ReplicaSet), or different Replica Sets.

{% highlight scala %}
object WithReplicaSet {
  def driver: reactivemongo.api.MongoDriver = ???

  val serversReplicaSet1 = List("rs11", "rs12", "rs13")
  val connectionReplicaSet1 = driver.connection(serversReplicaSet1)

  val serversReplicaSet2 = List("rs21", "rs22", "rs23")
  val connectionReplicaSet2 = driver.connection(serversReplicaSet2)
}
{% endhighlight %}

### Handling Authentication

There are two ways to give ReactiveMongo your credentials.

- Using `driver.connection()` (or the `MongoConnection` constructor)

{% highlight scala %}
import reactivemongo.core.nodeset.Authenticate

object WithAuth1 {
  def driver: reactivemongo.api.MongoDriver = ???
  def servers: List[String] = List("server1", "server2")

  val dbName = "somedatabase"
  val userName = "username"
  val password = "password"
  val credentials = List(Authenticate(dbName, userName, password))
  val connection = driver.connection(servers, authentications = credentials)
}
{% endhighlight %}

- Using the `db.authenticate()` method

{% highlight scala %}
import scala.concurrent.ExecutionContext.Implicits.global

object WithAuth2 {
  def db: reactivemongo.api.DefaultDB = ???
  def username: String = ???
  def password: String = ???
  implicit def authTimeout: scala.concurrent.duration.FiniteDuration = ???

  val futureAuthenticated = db.authenticate(username, password)

  futureAuthenticated.map { _ =>
    // doSomething
  }
}
{% endhighlight %}

Like any other operation in ReactiveMongo, authentication is done asynchronously. Anyway, it is not mandatory to wait for the authentication result; thanks to the [Failover Strategy](../advanced-topics/failoverstrategy.html), a request can be retried many times until the authentication process is done.

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

### Notes

#### A `MongoConnection` stands for a pool of connections

Do not get confused here. A `MongoConnection` is a _logical_ connection, not a physical one; it is actually a _connection pool_. By default, a `MongoConnection` creates 10 _physical_ connections to each node in the replica set (or to the single node if it is not a replica set.) You can tune this by setting the `nbChannelsPerNode` parameter.

{% highlight scala %}
def driver8: reactivemongo.api.MongoDriver = ???
def servers8: List[String] = List("host1", "host2")

val connection8 = driver1.connection(servers8)
{% endhighlight %}

#### Why are `MongoDriver` and `MongoConnection` distinct?

They manage two different things. `MongoDriver` holds the actor system, and `MongoConnection` the references to the actors. This is useful because it enables to work with many different single nodes or replica sets. Thus, your application can communicate is many different replica sets or single nodes, with only one `MongoDriver` instance.

#### Creation Costs

`MongoDriver` and `MongoConnection` involve creation costs –  the driver may create a new `ActorSystem`, and the connection, well, will connect to the servers. It is also a good idea to store the driver and the connection to reuse them.

On the contrary, `db` and `collection` are just plain objects that store references and nothing else. It is virtually free to create new instances; calling `connection.database()` or `db.collection()` may be done many times without any performance hit.

#### Virtual Private Network (VPN)

When connecting to a MongoDB replica set over a VPN, if using IP addresses instead of hostnames to configure the connection nodes, then it's possible that the nodes are discovered with hostnames that are local to the remote network and not usable from the client side.

[Next: Database and collections](./database-and-collection.html)
