---
layout: default
title: ReactiveMongo 0.11.0 - Read Preferences
---

## Use Read Preferences

> Read preference describes how MongoDB clients route read operations to members of a replica set. ([MongoDB Read Preference Documentation](http://docs.mongodb.org/manual/core/read-preference/))

The following Read Preferences are supported:

- `Primary`: read only from the primary. This is the default choice;
- `PrimaryPrefered`: read from the primary if it is available, or secondaries if it is not;
- `Secondary`: read only from any secondary;
- `SecondaryPrefered`: read from any secondary, or from the primary if they are not available;
- `Nearest`: read from the faster node (ie the node which replies faster than all others), regardless its status (primary or secondary.)

Read preference are given to `GenericQueryBuilder.cursor()` and `GenericQueryBuilder.one()`:

{% highlight scala %}
collection.
  find(BSONDocument("city" -> "San Francisco")).
  // read from any secondary whenever possible
  cursor(ReadPreferences.secondaryPrefered).
  collect[List]()
{% endhighlight %}

## Tag support

> Tag sets allow you to specify custom read preferences and write concerns so that your application can target operations to specific members.
>
> Custom read preferences and write concerns evaluate tags sets in different ways. Read preferences consider the value of a tag when selecting a member to read from. Write concerns ignore the value of a tag to when selecting a member, except to consider whether or not the value is unique.
>
> [MongoDB Read Preference Documentation ](http://docs.mongodb.org/manual/core/read-preference/#tag-sets)

If you properly tagged the servers of your replica set, then you can use Tag-aware Read Preferences.

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

Then we can tell ReactiveMongo to query only from the nodes that are tagged with `dc: "NYC"`:

{% highlight scala %}
collection.
  find(BSONDocument("city" -> "San Francisco")).
  // read from any secondary tagged with `dc: "NYC"`
  one(ReadPreference.secondaryPrefered(BSONDocument("dc" -> "NYC")))
{% endhighlight %}
