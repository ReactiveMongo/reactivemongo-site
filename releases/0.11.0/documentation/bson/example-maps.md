---
layout: default
title: ReactiveMongo 0.11.0 - Handle Map with BSON Library
---

## De/Serializing `Map` with the ReactiveMongo BSON library

{% highlight scala %}
object BSONMap {
  implicit def MapReader[V](implicit vr: BSONDocumentReader[V]): BSONDocumentReader[Map[String, V]] = new BSONDocumentReader[Map[String, V]] {
    def read(bson: BSONDocument): Map[String, V] = {
      val elements = bson.elements.map { tuple =>
        // assume that all values in the document are BSONDocuments
        tuple._1 -> vr.read(tuple._2.seeAsTry[BSONDocument].get)
      }
      elements.toMap
    }
  }

  implicit def MapWriter[V](implicit vw: BSONDocumentWriter[V]): BSONDocumentWriter[Map[String, V]] = new BSONDocumentWriter[Map[String, V]] {
    def write(map: Map[String, V]): BSONDocument = {
      val elements = map.toStream.map { tuple =>
        tuple._1 -> vw.write(tuple._2)
      }
      BSONDocument(elements)
    }
  }
}
{% endhighlight %}

### Example of usage

{% highlight scala %}
val map = Map("artist1" -> neilYoung)
val docFromMap: BSONDocument = BSON.writeDocument(map)
val mapFromDoc: Map[String, Artist] = BSON.readDocument[Map[String, Artist]](docFromMap)
{% endhighlight %}
