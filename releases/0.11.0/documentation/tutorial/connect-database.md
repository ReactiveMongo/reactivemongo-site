---
layout: default
title: ReactiveMongo 0.11.0 - Setup
---

## Starting ReactiveMongo

The first thing you need to do is to create a new `Driver` instance.

{% highlight scala %}
import reactivemongo.api.MongoDriver

val driver = new MongoDriver
{% endhighlight %}

Without any parameter, `MongoDriver` uses the default configuration. Obviously, you may want to indicate a specific configuration.

{% highlight scala %}
val driver = new MongoDriver(Some(typesafeConfig))
{% endhighlight %}

Then you can connect to a MongoDB server.

{% highlight scala %}
val connection = driver.connection(List("localhost"))
{% endhighlight %}

A `MongoDriver` instance manages an actor system; A connection manages a pool of connections. In general, a `MongoDriver` or a `MongoConnection` is never instantiated more than once. You can provide a list of one ore more servers; the driver will guess if it's a standalone server or a replica set configuration. Even with one replica node, the driver will probe for other nodes and add them automatically.

Some options can be provided while creating a connection.

{% highlight scala %}
import reactivemongo.api.MongoConnectionOptions

val conOpts = MongoConnectionOptions(/* connection options */)
val connection = driver.connection(List("localhost"), options = conOpts)
{% endhighlight %}

The following options can be used with `MongoConnectionOptions` to configure the connection behaviour.

- `authSource`: The database source for authentication credentials.
- `connectTimeoutMS`: The number of milliseconds to wait for a connection to be established before giving up.
- `sslEnabled`: It enables the SSL support for the connection.
- `sslAllowsInvalidCert`: If `sslEnabled` is true, this one indicates whether to accept invalid certificates (e.g. self-signed).
- `rm.tcpNoDelay`: TCPNoDelay flag.
- `rm.keepAlive`: TCP KeepAlive flag.
- `rm.nbChannelsPerNode`: Number of channels (connections) per node.

> The option `sslEnabled` is needed if the MongoDB server is requiring SSL (`mongod --sslMode requireSSL`). The related option `sslAllowsInvalidCert` is required is the server allows invalid certificate (`mongod --sslAllowInvalidCertificates`).

Getting a database and a collection is pretty easy:

{% highlight scala %}
val db = connection.db("somedatabase")
val collection = db.collection("somecollection")
{% endhighlight %}

## Connecting to a replica set

ReactiveMongo provides support for Replica Sets. That means the following:
* the driver will detect if it is connected to a Replica Set;
* it will probe for the other nodes in the set and connect to them;
* it will detect when the primary has changed and guess which is the new one;
* it will allow running queries on secondaries if they are explicitely set to SlaveOk (See the [MongoDB documentation](http://docs.mongodb.org/manual/applications/replication/#replica-set-read-preference) for more details about querying secondary nodes).

Connecting to a Replica Set is pretty much the same as connecting to a unique server. You may have notice that the argument to `driver.connection()` method is a `List[String]`; you can also give more than one node in the replica set.

{% highlight scala %}
val servers = List("server1:27017", "server2:27017", "server3:27017")
val connection = driver.connection(servers)
{% endhighlight %}

There is no obligation to give all the nodes in the replica set – actually, just one of them is required. ReactiveMongo will ask the nodes it can reach for the addresses of the other nodes in the replica set. Obviously it is better to give at least 2 or more nodes, in case of unavailablity of one node at the start of the application.

### Using many `MongoConnection` instances

In some (rare) cases it is perfectly viable to create as many `MongoConnection` instances you need with one `MongoDriver` instance – in that case, you will get different connection pools. This is useful when your application has to connect to two or more independent MongoDB nodes (i.e. that do not belong to the same ReplicaSet), or different Replica Sets.

{% highlight scala %}
val serversReplicaSet1 = List("rs11", "rs12", "rs13")
val connectionReplicaSet1 = driver.connection(serversReplicaSet1)

val serversReplicaSet2 = List("rs21", "rs22", "rs23")
val connectionReplicaSet2 = driver.connection(serversReplicaSet2)
{% endhighlight %}

### Handling Authentication

There are two ways to give ReactiveMongo your credentials.

- Using `driver.connection()` (or the `MongoConnection` constructor)

{% highlight scala %}
import reactivemongo.core.nodeset.Authenticate

val dbName = "somedatabase"
val userName = "username"
val password = "password"
val credentials = List(Authenticate(dbName, userName, password))
val connection = driver.connection(servers, nbChannelsPerNode = 5, authentications = credentials))
{% endhighlight %}

- Using the `db.authenticate()` method

{% highlight scala %}
val futureAuthenticated = db.authenticate(username, password)

futureAuthenticated.map { _ =>
  // doSomething
}
{% endhighlight %}

Like any other operation in ReactiveMongo, authentication is done asynchronously. Anyway, it is not mandatory to wait for the authentication result; thanks to the [Failover Strategy](../advanced-topics/failoverstrategy.html), a request can be retried many times until the authentication process is done.

### Connect Using MongoDB URI

You can also give the connection information as a [URI](http://docs.mongodb.org/manual/reference/connection-string/):

`mongodb://[username:password@]host1[:port1][,host2[:port2],...[,hostN[:portN]]][/[database][?[option1=value1][&option2=value2][...&optionN=valueN]]`

If credentials and the database name are included in the URI, ReactiveMongo will authenticate the connections on that database.

{% highlight scala %}
// connect to the replica set composed of `host1:27018`, `host2:27019` and `host3:27020`
// and authenticate on the database `somedb` with user `user123` and password `passwd123`
val uri = "mongodb://user123:passwd123@host1:27018,host2:27019,host3:27020/somedb"

val connection: Try[MongoConnection] =
  MongoConnection.parseURI(uri).map { parsedUri =>
    driver.connection(parsedUri)
  }
{% endhighlight %}

### Notes

#### A `MongoConnection` stands for a pool of connections

Do not get confused here. A `MongoConnection` is a _logical_ connection, not a physical one; it is actually a _connection pool_. By default, a `MongoConnection` creates 10 _physical_ connections to each node in the replica set (or to the single node if it is not a replica set.) You can tune this by setting the `nbChannelsPerNode` parameter.

{% highlight scala %}
val connection = driver.connection(servers, nbChannelsPerNode = 5)
{% endhighlight %}

#### Why are `MongoDriver` and `MongoConnection` distinct?

They manage two different things. `MongoDriver` holds the actor system, and `MongoConnection` the references to the actors. This is useful because it enables to work with many different single nodes or replica sets. Thus, your application can communicate is many different replica sets or single nodes, with only one `MongoDriver` instance.

#### Creation Costs

`MongoDriver` and `MongoConnection` involve creation costs –  the driver may create a new `ActorSystem`, and the connection, well, will connect to the servers. It is also a good idea to store the driver and the connection to reuse them.

On the contrary, `db` and `collection` are just plain objects that store references and nothing else. It is virtually free to create new instances; calling `connection.db()` or `db.collection()` may be done many times without any performance hit.
