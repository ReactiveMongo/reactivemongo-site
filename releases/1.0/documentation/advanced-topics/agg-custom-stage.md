---
layout: default
major_version: 1.0
title: Custom Aggregation Stage
---

## Custom Aggregation Stage

You can also implement custom aggregate stage, using the [`PipelineOperator`](../../api/commands/AggregationFramework.html#PipelineOperator) factory.

{% highlight scala %}
import scala.concurrent.ExecutionContext

import reactivemongo.api.bson._
import reactivemongo.api.bson.collection.BSONCollection

def customAgg(coll: BSONCollection)(implicit ec: ExecutionContext) =
  coll.aggregateWith[BSONDocument]() { framework =>
    import framework.PipelineOperator

    val customStage = // { $sample: { size: 2 } }
      PipelineOperator(BSONDocument("$sample" -> BSONDocument("size" -> 2)))

    customStage -> List.empty
  }
{% endhighlight %}

[Previous: Aggregation Framework](./aggregation.html)
