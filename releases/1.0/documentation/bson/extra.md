---
layout: default
major_version: 1.0
title: BSON extra libraries
---

## BSON extra libraries

Some extra libraries are provided along to ease the BSON integration.

### GeoJSON

A new [GeoJSON](https://docs.mongodb.com/manual/reference/geojson/) library is provided, with the geometry types and the corresponding handlers to read from and write them to appropriate BSON representation.

It can be configured in the `build.sbt` as below.

{% highlight ocaml %}
libraryDependencies += "org.reactivemongo" %% "reactivemongo-bson-geo" % "{{site._1_0_latest_minor}}"
{% endhighlight %}

Then the GeoJSON types can be imported and used:

{% highlight scala %}
import reactivemongo.api.bson._

// { type: "Point", coordinates: [ 40, 5 ] }
val geoPoint = GeoPoint(40, 5)

// { type: "LineString", coordinates: [ [ 40, 5 ], [ 41, 6 ] ] }
val geoLineString = GeoLineString(
  GeoPosition(40D, 5D, None),
  GeoPosition(41D, 6D))
{% endhighlight %}

> More [GeoJSON examples](https://github.com/ReactiveMongo/ReactiveMongo-BSON/blob/master/geo/src/test/scala/GeometrySpec.scala)

| GeoJSON | ReactiveMongo | Description |
| ------- | ------------- | ----------- |
| Position | [GeoPosition](https://javadoc.io/doc/org.reactivemongo/reactivemongo-bson-geo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/GeoPosition.html) | Position coordinates
| [Point](https://docs.mongodb.com/manual/reference/geojson/#point) | [GeoPoint](https://javadoc.io/doc/org.reactivemongo/reactivemongo-bson-geo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/GeoPoint.html) | Single point with single position
| [LineString](https://docs.mongodb.com/manual/reference/geojson/#linestring) | [GeoLineString](https://javadoc.io/doc/org.reactivemongo/reactivemongo-bson-geo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/GeoLineString.html) | Simple line
| LinearRing | [GeoLinearRing](https://javadoc.io/doc/org.reactivemongo/reactivemongo-bson-geo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/GeoLinearRing.html) | Simple (closed) ring
| [Polygon](https://docs.mongodb.com/manual/reference/geojson/#polygon) | [GeoPolygon](https://javadoc.io/doc/org.reactivemongo/reactivemongo-bson-geo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/GeoPolygon.html) | Polygon with at least one ring
| [MultiPoint](https://docs.mongodb.com/manual/reference/geojson/#multipoint) | [GeoMultiPoint](https://javadoc.io/doc/org.reactivemongo/reactivemongo-bson-geo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/GeoMultiPoint.html) | Collection of points
| [MultiLineString](https://docs.mongodb.com/manual/reference/geojson/#multilinestring) | [GeoMultiLineString](https://javadoc.io/doc/org.reactivemongo/reactivemongo-bson-geo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/GeoMultiLineString.html) | Collection of `LineString`
| [MultiPolygon](https://docs.mongodb.com/manual/reference/geojson/#multipolygon) | [GeoMultiPolygon](https://javadoc.io/doc/org.reactivemongo/reactivemongo-bson-geo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/GeoMultiPolygon.html) | Collection of polygon
| [GeometryCollection](https://docs.mongodb.com/manual/reference/geojson/#geometrycollection) | [GeoGeometryCollection](https://javadoc.io/doc/org.reactivemongo/reactivemongo-bson-geo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/GeoGeometryCollection.html) | Collection of geometry objects

*See [Scaladoc](https://javadoc.io/doc/org.reactivemongo/reactivemongo-bson-geo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/index.html)*

### Monocle

*(Experimental)*

The library that provides [Monocle](http://julien-truffaut.github.io/Monocle/) based optics, for BSON values.

It can be configured in the `build.sbt` as below.

{% highlight ocaml %}
libraryDependencies += "org.reactivemongo" %% "reactivemongo-bson-monocle" % "{{site._1_0_latest_minor}}"
{% endhighlight %}

Then the utilities can be imported and used:

{% highlight scala %}
import reactivemongo.api.bson._

import reactivemongo.api.bson.monocle._ // new library

val barDoc = BSONDocument(
  "lorem" -> 2,
  "ipsum" -> BSONDocument("dolor" -> 3))

val topDoc = BSONDocument(
  "foo" -> 1,
  "bar" -> barDoc)

// Simple field
val lens1 = field[BSONInteger]("foo")
val updDoc1: BSONDocument = lens1.set(BSONInteger(2))(topDoc)
// --> { "foo": 1, ... }

// Nested field
val lens2 = field[BSONDocument]("bar").
  composeOptional(field[Double]("lorem"))

val updDoc2 = lens2.set(1.23D)(topDoc)
// --> { ..., "bar": { "lorem": 1.23, ... } }
{% endhighlight %}

> More [monocle examples](https://github.com/ReactiveMongo/ReactiveMongo-BSON/blob/master/monocle/src/test/scala/MonocleSpec.scala)

*See [Scaladoc](https://javadoc.io/doc/org.reactivemongo/reactivemongo-bson-monocle_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/bson/monocle/index.html)*

### Specs2

The Specs2 library provides utilities to write tests using [specs2](https://etorreborre.github.io/specs2/) with BSON values.

It can be configured in the `build.sbt` as below.

{% highlight ocaml %}
libraryDependencies += "org.reactivemongo" %% "reactivemongo-specs2" % "{{site._1_0_latest_minor}}"
{% endhighlight %}

{% highlight scala %}
import reactivemongo.api.bson.BSONDocument
import reactivemongo.api.bson.specs2._

final class MySpec extends org.specs2.mutable.Specification {
  "Foo" title

  "Bar" should {
    "lorem" in {
      BSONDocument("ipsum" -> 1) must_=== BSONDocument("dolor" -> 2)
      // Use provided Diffable to display difference
      // between actual and expected documents
    }
  }
}
{% endhighlight %}

> More [specs2 examples](specs2/src/test/scala/DiffableSpec.scala)

*See [Scaladoc](https://oss.sonatype.org/service/local/repositories/releases/archive/org/reactivemongo/reactivemongo-bson-geo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo-bson-geo_{{site._1_0_scala_major}}-{{site._1_0_latest_minor}}-javadoc.jar/!/reactivemongo/api/bson/geo/index.html)*