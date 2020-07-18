---
layout: default
major_version: 1.0
title: Azure Cosmos DB
---

## Azure Cosmos DB

[Cosmos DB](https://docs.microsoft.com/en-us/azure/cosmos-db/introduction) is the database service available in Microsoft Azure, with some [compatibility with MongoDB](https://www.mongodb.com/cloud/atlas/compare).

Once registered, you can go to Cosmos DB quickstart.

First open the *MongoDB Shell* to check the connection using MongoShell, make sure the credentials and network access is ok from the application environment.

In case of error at this step, check the access configuration in Azure Cosmos DB.

If ok, then open the *Java* tab:

<img src="../images/azure-cosmos.png" alt="Cosmos DB quickstart - Connection string" class="screenshot" />

The connection string can be copied from there to connect using ReactiveMongo.

The username and password can be extracted from the string with the following pattern, so it can then be substituted using environment variables (e.g. `${AZURE_USERNAME}` by actual username).

{% highlight javascript %}
mongodb.uri = "mongodb://${AZURE_USERNAME}:${AZURE_PASSWORD}@${HOST}:${PORT}/${AZURE_USERNAME}?ssl=true"
{% endhighlight %}

> Note the `ssl=true` parameter is required.

For example, if `bd8f94d5-3661-4876-8eaa-d7d98c810587` is the username and password `NkMxQjAzQzMtREIyQy00MTg4LUE3NjYtNkY3MkU1NjNDRkRECg==`, then when port `10250` the connection URI would be as bellow.

{% highlight javascript %}
mongodb.uri = "mongodb://bd8f94d5-3661-4876-8eaa-d7d98c810587:NkMxQjAzQzMtREIyQy00MTg4LUE3NjYtNkY3MkU1NjNDRkRECg==@bd8f94d5-3661-4876-8eaa-d7d98c810587.documents.azure.com:10250/bd8f94d5-3661-4876-8eaa-d7d98c810587?ssl=true"
{% endhighlight %}

*[See the documentation](./connect-database.html)*
