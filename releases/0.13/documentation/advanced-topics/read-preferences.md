---
layout: default
major_version: 0.13
title: Read Preferences
---

## Use Read Preferences

> Read preference describes how MongoDB clients route read operations to members of a replica set. ([MongoDB Read Preference Documentation](http://docs.mongodb.org/manual/core/read-preference/))

The following [read preferences](../../api/index.html#reactivemongo.api.ReadPreference) are supported:

- primary, 
- primary preferred, 
- secondary, 
- secondary preferred,
- nearest.

The Read preference can be chosen globally using the [`MongoConnectionOptions`](../../api/index.html#reactivemongo.api.MongoConnectionOptions), or for each [cursor](../../api/index.html#reactivemongo.api.collections.GenericQueryBuilder@cursor[T](readPreference:reactivemongo.api.ReadPreference,isMongo26WriteOp:Boolean)(implicitreader:GenericQueryBuilder.this.pack.Reader[T],implicitec:scala.concurrent.ExecutionContext,implicitcp:reactivemongo.api.CursorProducer[T]):cp.ProducedCursor).

{% highlight scala %}
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.bson.BSONDocument
import reactivemongo.api.ReadPreference
import reactivemongo.api.collections.bson.BSONCollection

def readFromSecondary1(collection: BSONCollection) = 
  collection.find(BSONDocument("city" -> "San Francisco")).
    // read from any secondary whenever possible
    cursor[BSONDocument](ReadPreference.secondaryPreferred).
    collect[List]()
{% endhighlight %}

> The default read preference can be set in the [connection options](../tutorial/connect-database.html).

## Tag support

Tag sets allow you to specify custom read preferences and write concerns so that your application can dispatch the operations to specific members.

With tagged servers in your replica set, then you can use a tag-aware Read Preferences.

Let's suppose that the replica set is configured that way:

{% highlight javascript %}
{
    "_id" : "rs0",
    "version" : 2,
    "members" : [
             {
                     "_id" : 0,
                     "host" : "mongodb0.example.net:27017",
                     "tags" : {
                             "dc": "NYC",
                             "disk": "ssd"
                     }
             },
             {
                     "_id" : 1,
                     "host" : "mongodb1.example.net:27017",
                     "tags" : {
                             "dc": "NYC"
                     }
             },
             {
                     "_id" : 2,
                     "host" : "mongodb2.example.net:27017",
                     "tags" : {
                             "dc": "Paris"
                     }
             }
     ]
}
{% endhighlight %}

Then we can tell ReactiveMongo to query only from the nodes which are tagged with `dc: "NYC"`:

{% highlight scala %}
import scala.concurrent.ExecutionContext.Implicits.global

import reactivemongo.bson.BSONDocument
import reactivemongo.api.ReadPreference
import reactivemongo.api.collections.bson.BSONCollection

def readFromSecondary2(collection: BSONCollection) = 
  collection.find(BSONDocument("city" -> "San Francisco")).
    // read from any secondary tagged with `dc: "NYC"`
    one[BSONDocument](ReadPreference.secondaryPreferred(
      tag = BSONDocument("dc" -> "NYC")))
{% endhighlight %}

The custom read preferences and write concerns evaluate the tag sets in different ways. Read preferences consider the value of a tag when selecting a member to read from. Write concerns ignore the value of a tag to when selecting a member, except to consider whether or not the value is unique; See [MongoDB Read Preference Documentation](http://docs.mongodb.org/manual/core/read-preference/#tag-sets))
