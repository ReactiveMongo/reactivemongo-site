---
layout: default
major_version: 0.1x
title: MongoDB Atlas
---

## MongoDB Atlas

[Atlas](https://www.mongodb.com/cloud/atlas) is the official cloud MongoDB service (feature complete and up-to-date).

Once the Atlas account is set up (with a Cluster and Security/users), then the  Command Line tab is accessible.

<img src="../images/mongodb-atlas1.png" alt="MongoDB Atlas Cluster" class="screenshot" />

In the shown dialog, the "Connect Your Application" can be selected as method.

<img src="../images/mongodb-atlas2.png" alt="MongoDB Atlas Connection method" class="screenshot" />

Then the connection URI is displayed, and can be copied with user/password placeholders.

<img src="../images/mongodb-atlas3.png" alt="MongoDB Atlas Connection URI" class="screenshot" />

{% highlight javascript %}
mongodb.uri = "mongodb+srv://${ATLAS_USERNAME}:${ATLAS_PASSWORD}@cluster0-p8ccg.mongodb.net/test?retryWrites=true&w=majority"
{% endhighlight %}

> *Note:* The URI is [DNS seedlist](https://docs.mongodb.com/manual/reference/connection-string/#dns-seedlist-connection-format) format, supported by ReactiveMongo. The options are resolved from there.

In order to substitute the placeholders `ATLAS_USERNAME` and `ATLAS_PASSWORD`, actual users can be check in the Security settings.

<img src="../images/mongodb-atlas4.png" alt="MongoDB Atlas Security" class="screenshot" />

It necessary to make sure that the user is granted the appropriate permissions.

<img src="../images/mongodb-atlas5.png" alt="MongoDB Atlas User" class="screenshot" />

*[See the documentation](./connect-database.html)*