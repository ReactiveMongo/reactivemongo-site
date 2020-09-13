---
layout: default
major_version: 1.0
title: Raw Aggregation Stage
---

## Raw Aggregation Stage

You can also implement aggregate stage using raw BSON (e.g. when there is no convenient stage yet provided), using the [`PipelineOperator`](https://javadoc.io/doc/org.reactivemongo/reactivemongo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/collections/GenericCollection.html#PipelineOperator=AggregationOps.this.AggregationFramework.PipelineOperator) factory.

```scala
import scala.concurrent.ExecutionContext

import reactivemongo.api.bson._
import reactivemongo.api.bson.collection.BSONCollection

def customAgg(coll: BSONCollection)(implicit ec: ExecutionContext) =
  coll.aggregateWith[BSONDocument]() { framework =>
    import framework.PipelineOperator

    val customStage = // { $sample: { size: 2 } }
      PipelineOperator(BSONDocument("$sample" -> BSONDocument("size" -> 2)))

    List(customStage)
  }
```

[Previous: Aggregation Framework](./aggregation.html)
