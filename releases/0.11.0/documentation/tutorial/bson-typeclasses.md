---
layout: default
title: ReactiveMongo 0.11.0 - BSON readers & writers
---

## BSON readers and writers

In order to get and store data with MongoDB, ReactiveMongo provides an extensible API to define appropriate readers and writers.

As long as you are working with [`BSONValue`s](../../api/index.html#reactivemongo.bson.BSONValue), some default implementations of readers and writers are provided by the following import.

{% highlight scala %}
import reactivemongo.bson._
{% endhighlight %}

Of course it also possible to read values of custom types. To do so for a custom type, a custom instance of [`BSONReader`](../../api/index.html#reactivemongo.bson.BSONReader), or of [`BSONDocumentReader`](../../api/index.html#reactivemongo.bson.BSONDocumentReader), must be resolved (in the implicit scope).

{% highlight scala %}
// TODO: example
{% endhighlight %}

Similarily, in order to write a value of a custom type, a custom instance of [`BSONWriter`](../../api/index.html#reactivemongo.bson.BSONWriter), or of [`BSONDocumentWriter`](../../api/index.html#reactivemongo.bson.BSONDocumentWriter) must be available.

{% highlight scala %}
// TODO: example
{% endhighlight %}

To ease the definition or reader and writer instances for your custom types, ReactiveMongo provides some helper macros.

{% highlight scala %}
// TODO: example
{% endhighlight %}