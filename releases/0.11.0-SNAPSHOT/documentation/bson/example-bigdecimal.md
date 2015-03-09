---
layout: default
title: ReactiveMongo 0.11.0-SNAPSHOT - Handle BigDecimal and BigInteger with the BSON Library
---

## Concrete example: BigDecimal

### BigDecimal

#### Naive implementation using doubles

{% highlight scala %}
// BigDecimal to BSONDouble Example
// naive implementation, does not support values > Double.MAX_VALUE
object BigDecimalBSONNaive {
  implicit object BigDecimalHandler extends BSONHandler[BSONDouble, BigDecimal] {
    def read(double: BSONDouble) = BigDecimal(double.value)
    def write(bd: BigDecimal) = BSONDouble(bd.toDouble)
  }
}

{% endhighlight %}

##### Example of Usage

{% highlight scala %}
case class SomeClass(bigd: BigDecimal)

// USING HAND WRITTEN HANDLER
implicit object SomeClassHandler extends BSONDocumentReader[SomeClass] with BSONDocumentWriter[SomeClass] {
  def read(doc: BSONDocument) = {
    SomeClass(doc.getAs[BigDecimal]("bigd").get)
  }
  def write(sc: SomeClass) = {
    BSONDocument("bigd" -> sc.bigd)
  }
}
// OR, USING MACROS
// implicit val someClassHandler = Macros.handler[SomeClass]

val sc1 = SomeClass(BigDecimal(1786381))
val bsonSc1 = BSON.write(sc1)
val sc1FromBSON = BSON.readDocument[SomeClass](bsonSc1)
{% endhighlight %}

#### Exact BigDecimal de/serialization

{% highlight scala %}
object BSONBigDecimalBigInteger {
  implicit object BigDecimalHandler extends BSONDocumentReader[BigDecimal] with BSONDocumentWriter[BigDecimal] {
    def write(bigDecimal: BigDecimal) = BSONDocument(
      "scale" -> bigDecimal.scale,
      "precision" -> bigDecimal.precision,
      "value" -> BigInt(bigDecimal.underlying.unscaledValue()))
    def read(doc: BSONDocument) = BigDecimal.apply(
      doc.getAs[BigInt]("value").get,
      doc.getAs[Int]("scale").get,
      new java.math.MathContext(doc.getAs[Int]("precision").get))
  }
}
{% endhighlight %}

##### Example of usage

{% highlight scala %}
val bigDecimal = BigDecimal(1908713, 12)

case class SomeClass(bd: BigDecimal)

implicit val someClassHandler = Macros.handler[SomeClass]

val someClassValue = SomeClass(BigDecimal(1908713, 12))
val bsonBigDecimal = BSON.writeDocument(someClassValue)
val someClassValueFromBSON = BSON.readDocument[SomeClass](bsonBigDecimal)
println(s"someClassValue == someClassValueFromBSON ? ${someClassValue equals someClassValueFromBSON}")
{% endhighlight %}

### BigInt

{% highlight scala %}
implicit object BigIntHandler extends BSONDocumentReader[BigInt] with BSONDocumentWriter[BigInt] {
  def write(bigInt: BigInt): BSONDocument = BSONDocument(
    "signum" -> bigInt.signum,
    "value" -> BSONBinary(bigInt.toByteArray, Subtype.UserDefinedSubtype))
  def read(doc: BSONDocument): BigInt = BigInt(
    doc.getAs[Int]("signum").get,
    {
      val buf = doc.getAs[BSONBinary]("value").get.value
      buf.readArray(buf.readable)
    })
}
{% endhighlight %}
