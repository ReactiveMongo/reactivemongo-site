---
layout: default
major_version: 1.0
title: Azure Cosmos DB
---

## Azure Cosmos DB

[Cosmos DB](https://docs.microsoft.com/en-us/azure/cosmos-db/introduction) is the database service available in Microsoft Azure, with some [compatibility with MongoDB](https://www.mongodb.com/cloud/atlas/compare).

Once registered, the MongoDB credentials are shown.

<img src="../images/azure-cosmos.png" alt="Cosmos DB credentials" class="screenshot" />

Then ReactiveMongo can be used to connect with the following pattern for the connection URI, with variables replaced appropriately (e.g. `${AZURE_USERNAME}` by actual username).

{% highlight javascript %}
mongodb.uri = "mongodb://${AZURE_USERNAME}:${AZURE_PASSWORD}@${HOST}:${PORT}/${AZURE_USERNAME}?ssl=true"
{% endhighlight %}

> Note the `ssl=true` parameter is required.

For example, if `bd8f94d5-3661-4876-8eaa-d7d98c810587` is the username and password `NkMxQjAzQzMtREIyQy00MTg4LUE3NjYtNkY3MkU1NjNDRkRECg==`, then when port `10250` the connection URI would be as bellow.

{% highlight javascript %}
mongodb.uri = "mongodb://bd8f94d5-3661-4876-8eaa-d7d98c810587:NkMxQjAzQzMtREIyQy00MTg4LUE3NjYtNkY3MkU1NjNDRkRECg==@bd8f94d5-3661-4876-8eaa-d7d98c810587.documents.azure.com:10250/bd8f94d5-3661-4876-8eaa-d7d98c810587?ssl=true"
{% endhighlight %}

*[See the documentation](./connect-database.html)*
