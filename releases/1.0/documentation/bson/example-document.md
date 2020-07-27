---
layout: default
major_version: 1.0
title: Handle documents with the BSON Library
---

## Concrete example: Documents

*See [BSON readers & writers](typeclasses.html)*.

### Documents

You can write your own writers and readers for your models. Let's define a model for `Album`, and its `BSONWriter` and `BSONReader`.

```scala
import reactivemongo.api.bson.{
  BSONDocument, BSONDocumentWriter, BSONDocumentReader
}

case class SimpleAlbum(
  title: String,
  releaseYear: Int,
  hiddenTrack: Option[String],
  allMusicRating: Option[Double])

implicit object SimpleAlbumWriter extends BSONDocumentWriter[SimpleAlbum] {
  def writeTry(album: SimpleAlbum) =
    scala.util.Success(BSONDocument(
      "title" -> album.title,
      "releaseYear" -> album.releaseYear,
      "hiddenTrack" -> album.hiddenTrack,
      "allMusicRating" -> album.allMusicRating))
}

implicit object SimpleAlbumReader extends BSONDocumentReader[SimpleAlbum] {
  def readDocument(doc: BSONDocument) = for {
    t <- doc.getAsTry[String]("title")
    y <- doc.getAsTry[Int]("releaseYear")
    h = doc.getAsOpt[String]("hiddenTrack")
    r = doc.getAsOpt[Double]("allMusicRating")
  } yield SimpleAlbum(t, y, h, r)
}
```

You should have noted that our reader and writer extend `BSONDocumentReader[T]` and `BSONDocumentWriter[T]`. These two traits are just a shorthand for `BSONReader[B <: BSONValue, T]` and `BSONWriter[T, B <: BSONValue]`.

OK, now, what if I want to store all the tracks names of the album? Or, in other words, how can we deal with collections? First of all, you can safely infer that all sequences and sets can be serialized as `BSONArray`s. Using `BSONArray` follows the same patterns as `BSONDocument`.

```scala
import reactivemongo.api.bson.{ BSONArray, BSONDocument }

val album4 = BSONDocument(
  "title" -> "Everybody Knows this is Nowhere",
  "releaseYear" -> 1969,
  "hiddenTrack" -> None,
  "allMusicRating" -> Some(5.0),
  "tracks" -> BSONArray(
    "Cinnamon Girl",
    "Everybody Knows this is Nowhere",
    "Round & Round (it Won't Be Long)",
    "Down By the River",
    "Losing End (When You're On)",
    "Running Dry (Requiem For the Rockets)",
    "Cowgirl in the Sand"))

val tracksOfAlbum4 = album4.getAsOpt[BSONArray]("tracks").map { array =>
  array.values.flatMap { track =>
    // here, I get a track as a BSONValue.
    // I can use `asOpt[T]` to safely get an Option of its value as a `T`
    track.asOpt[String]
  }
}
```

Using `BSONArray` does what we want, but this code is pretty verbose. Would it not be nice to deal directly with collections?

Here again, there is a converter for `Traversable`s of types that can be transformed into `BSONValue`s. For example, if you have a `List[Something]`, if there is an implicit `BSONWriter` of `Something` to some `BSONValue` in the scope, you can use it as is, without giving explicitly a `BSONArray`. The same logic applies for reading `BSONArray` values.

```scala
import reactivemongo.api.bson.BSONDocument

val album5 = BSONDocument(
  "title" -> "Everybody Knows this is Nowhere",
  "releaseYear" -> 1969,
  "hiddenTrack" -> None,
  "allMusicRating" -> Some(5.0),
  "tracks" -> List(
    "Cinnamon Girl",
    "Everybody Knows this is Nowhere",
    "Round & Round (it Won't Be Long)",
    "Down By the River",
    "Losing End (When You're On)",
    "Running Dry (Requiem For the Rockets)",
    "Cowgirl in the Sand"))

val tracksOfAlbum5 = album5.getAsOpt[List[String]]("tracks")
// returns an Option[List[String]] if `tracks` is a BSONArray containing BSONStrings :)
```

So, now we can rewrite our reader and writer for albums including tracks.

```scala
import reactivemongo.api.bson.{
  BSONDocument, BSONDocumentReader, BSONDocumentWriter
}

case class Album(
  title: String,
  releaseYear: Int,
  hiddenTrack: Option[String],
  allMusicRating: Option[Double],
  tracks: List[String])

implicit object AlbumWriter extends BSONDocumentWriter[Album] {
  def writeTry(album: Album) = scala.util.Success(BSONDocument(
    "title" -> album.title,
    "releaseYear" -> album.releaseYear,
    "hiddenTrack" -> album.hiddenTrack,
    "allMusicRating" -> album.allMusicRating,
    "tracks" -> album.tracks))
}

implicit object AlbumReader extends BSONDocumentReader[Album] {
  def readDocument(doc: BSONDocument) = for {
    t <- doc.getAsTry[String]("title")
    y <- doc.getAsTry[Int]("releaseYear")
    h = doc.getAsOpt[String]("hiddenTrack")
    r = doc.getAsOpt[Double]("allMusicRating")
    l = doc.getAsOpt[List[String]]("tracks").toList.flatten
  } yield Album(t, y, h, r, l)
}
```

Obviously, you can combine these readers and writers to de/serialize more complex object graphs. Let's write an Artist model, containing a list of Albums.

```scala
import reactivemongo.api.bson.{
  BSON,
  BSONDocument,
  BSONDocumentReader,
  BSONDocumentWriter
}

case class Artist(
  name: String,
  albums: List[Album])

implicit object ArtistWriter extends BSONDocumentWriter[Artist] {
  def writeTry(artist: Artist) =
    scala.util.Success(BSONDocument(
      "name" -> artist.name,
      "albums" -> artist.albums))
}

implicit object ArtistReader extends BSONDocumentReader[Artist] {
  def readDocument(doc: BSONDocument) = for {
    n <- doc.getAsTry[String]("name")
    l = doc.getAsOpt[List[Album]]("albums").toList.flatten
  } yield Artist(n, l)
}

val neilYoung = Artist(
  "Neil Young",
  List(
    Album(
      "Everybody Knows this is Nowhere",
      1969,
      None,
      Some(5),
      List(
        "Cinnamon Girl",
        "Everybody Knows this is Nowhere",
        "Round & Round (it Won't Be Long)",
        "Down By the River",
        "Losing End (When You're On)",
        "Running Dry (Requiem For the Rockets)",
        "Cowgirl in the Sand"))))

val neilYoungDoc = BSON.writeDocument(neilYoung)
```

Here, we get an "ambiguous implicit" problem, which is normal because we have more than one Reader of `BSONDocument`s available in our scope (`SimpleArtistReader`, `ArtistReader`, `AlbumReader`, etc.). So we have to explicitly give the type of the instance we want to get from the document.

```scala
import reactivemongo.api.bson.{ BSON, BSONDocumentReader }

implicit def artistReader: BSONDocumentReader[Artist] = ???

val neilYoungAgain = neilYoungDoc.flatMap { BSON.readDocument[Artist](_) }
```
