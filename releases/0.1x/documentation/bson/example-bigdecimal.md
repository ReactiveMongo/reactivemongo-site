---
layout: default
major_version: 0.1x
title: Handle BigDecimal and BigInteger with the BSON Library
---

## Concrete example: BigDecimal

*See [BSON readers & writers](typeclasses.html)*.

### BigDecimal

#### Naive implementation using doubles

{% highlight scala %}
import scala.util.{ Failure, Success }
import reactivemongo.api.bson.{ BSONDouble, BSONHandler, BSONValue }

// BigDecimal to BSONDouble Example
// naive implementation, does not support values > Double.MAX_VALUE
object BigDecimalBSONNaive {
  implicit object BigDecimalHandler extends BSONHandler[BigDecimal] {
    def readTry(v: BSONValue) = v match {
      case BSONDouble(double) => Success(BigDecimal(double))
      case _ => Failure(new IllegalArgumentException())
    }

    def writeTry(bd: BigDecimal) = Success(BSONDouble(bd.toDouble))
  }
}

{% endhighlight %}

##### Example of Usage

{% highlight scala %}
import scala.util.Success

import reactivemongo.api.bson.{
  BSON, BSONDocument, BSONDocumentReader, BSONDocumentWriter
}

case class SomeClass(bigd: BigDecimal)

// USING HAND WRITTEN HANDLER
implicit object SomeClassHandler extends BSONDocumentReader[SomeClass] with BSONDocumentWriter[SomeClass] {
  def readDocument(doc: BSONDocument) =
    doc.getAsTry[BigDecimal]("bigd").map(SomeClass(_))

  def writeTry(sc: SomeClass) = Success(BSONDocument("bigd" -> sc.bigd))
}

// OR, USING MACROS
// implicit val someClassHandler = Macros.handler[SomeClass]

val sc1 = SomeClass(BigDecimal(1786381))
val bsonSc1 = BSON.writeDocument(sc1)
val sc1FromBSON = bsonSc1.flatMap { b => BSON.readDocument[SomeClass](b) }
{% endhighlight %}

#### Exact BigDecimal de/serialization

{% highlight scala %}
import scala.util.Success

import reactivemongo.api.bson.{
  BSONDocument, BSONDocumentReader, BSONDocumentWriter
}

object BSONBigDecimalBigInteger {
  implicit object BigDecimalHandler extends BSONDocumentReader[BigDecimal] with BSONDocumentWriter[BigDecimal] {
    def writeTry(bigDecimal: BigDecimal) = Success(BSONDocument(
      "scale" -> bigDecimal.scale,
      "precision" -> bigDecimal.precision,
      "value" -> BigInt(bigDecimal.underlying.unscaledValue())))

    def readDocument(doc: BSONDocument) = for {
      v <- doc.getAsTry[BigInt]("value")
      s <- doc.getAsTry[Int]("scale")
      p <- doc.getAsTry[Int]("precision").map { new java.math.MathContext(_) }
    } yield BigDecimal(v, s, p)
  }
}
{% endhighlight %}

##### Example of usage

{% highlight scala %}
import reactivemongo.api.bson.BSON

val bigDecimal = BigDecimal(1908713, 12)

val someClassValue = SomeClass(BigDecimal(1908713, 12))
val bsonBigDecimal = BSON.writeDocument(someClassValue)

val someClassValueFromBSON =
  bsonBigDecimal.flatMap { BSON.readDocument[SomeClass](_) }
{% endhighlight %}

### BigInteger

{% highlight scala %}
import scala.util.Success

import reactivemongo.api.bson.{
  BSONBinary, BSONDocument, BSONDocumentReader, BSONDocumentWriter, Subtype
}

implicit object BigIntHandler 
  extends BSONDocumentReader[BigInt] with BSONDocumentWriter[BigInt] {

  def writeTry(bigInt: BigInt) = Success(BSONDocument(
    "signum" -> bigInt.signum,
    "value" -> BSONBinary(bigInt.toByteArray, Subtype.UserDefinedSubtype)))

  def readDocument(doc: BSONDocument) = for {
    sig <- doc.getAsTry[Int]("signum")
    bin <- doc.getAsTry[BSONBinary]("value")
  } yield BigInt(sig, bin.byteArray)
}
{% endhighlight %}
