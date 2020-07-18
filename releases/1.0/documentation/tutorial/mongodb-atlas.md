---
layout: default
major_version: 1.0
title: MongoDB Atlas
---

## MongoDB Atlas

[Atlas](https://www.mongodb.com/cloud/atlas) is the official cloud MongoDB service (feature complete and up-to-date).

Once the Atlas account is set up (with a Cluster and Security/users), then the  connection is accessible.

<img src="../images/mongodb-atlas1.png" alt="MongoDB Atlas Cluster" class="screenshot" />

In the shown dialog, the "Connect your Application" can be selected as method.

<img src="../images/mongodb-atlas2.png" alt="MongoDB Atlas Connection method" class="screenshot" />

Then the connection URI is displayed, and can be copied with user/password placeholders.

<img src="../images/mongodb-atlas3.png" alt="MongoDB Atlas Connection URI" class="screenshot" />

First check the MongoShell can connect using the URI:

{% highlight bash %}
export ATLAS_USERNAME="..."
export ATLAS_PASSWORD="..."

mongo -u "${ATLAS_USERNAME}" -p "${ATLAS_PASSWORD}" "mongodb+srv://...-cluster-ej8gu.azure.mongodb.net/<dbname>?retryWrites=true&w=majority"
{% endhighlight %}

In order to substitute the placeholders `ATLAS_USERNAME` and `ATLAS_PASSWORD`, actual users can be check in the *Database Access*.

<img src="../images/mongodb-atlas4.png" alt="MongoDB Database Access" class="screenshot" />

Check whether one of the following errors is seen while trying to connect with the MongoShell.

{% highlight text %}{% raw %}
Unable to reach primary for set ...-cluster-shard-0
Cannot reach any nodes for set ...-cluster-shard-0.
...
Please check network connectivity and the status of the set.
{% endraw %}{% endhighlight %}

If such error happens, then it's required to check the *Network Access* to make sure the source address is authorized; At least one entry must be annotated with "includes your current IP address".

<img src="../images/mongodb-atlas5.png" alt="MongoDB Network Access" class="screenshot" />

If the following error is displayed by the MongoShell, then the credentials must be checked.

{% highlight text %}{% raw %}
can't authenticate against replica set ... caused by :: Authentication failed
{% endraw %}{% endhighlight %}

When the MongoShell is successfully connected, the application configuration can be defined as below.

{% highlight javascript %}
mongodb.uri = "mongodb+srv://${ATLAS_USERNAME}:${ATLAS_PASSWORD}@...-cluster-ej8gu.azure.mongodb.net/<dbname>?retryWrites=true&w=majority"
{% endhighlight %}

> *Note:* The URI is [DNS seedlist](https://docs.mongodb.com/manual/reference/connection-string/#dns-seedlist-connection-format) format, supported by ReactiveMongo. 

It's necessary to make sure that the user is granted the appropriate permissions.

<img src="../images/mongodb-atlas6.png" alt="MongoDB Atlas User" class="screenshot" />

*[See the documentation](./connect-database.html)*
