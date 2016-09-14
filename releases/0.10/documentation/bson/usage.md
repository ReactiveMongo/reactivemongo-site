---
layout: default
major_version: "0.10"
title: The ReactiveMongo BSON Library
---

## The ReactiveMongo BSON Library

Every BSON type has its matching class or object in the BSON library of ReactiveMongo.
 
For example:

- `BSONString` for strings
- `BSONDouble` for double values
- `BSONInteger` for integer 
- `BSONLong` for long values
- `BSONObjectID` for MongoDB ObjectIds
- `BSONDocument` for MongoDB documents
- `BSONArray` for MongoDB Arrays
- `BSONBinary` for binary values (raw binary arrays stored in the document)
- etc.

All this classes or objects extend the trait `BSONValue`.

You can build documents with the BSONDocument class. It accepts tuples of `String` and `BSONValue`.

Let's build a very simple document representing an album.


{% highlight scala %}
import reactivemongo.bson._

val album = BSONDocument(
  "title" -> BSONString("Everybody Knows this is Nowhere"),
  "releaseYear" -> BSONInteger(1969))
{% endhighlight %}

You can read a `BSONDocument` using the `get` method, which will return an `Option[BSONValue]` whether the requested field is present or not.

{% highlight scala %}
val albumTitle = album.get("title")
albumTitle match {
  case Some(BSONString(title)) => println(s"The title of this album is $title")
  case _                       => println("this document does not contain a title (or title is not a BSONString)")
}
{% endhighlight %}

### Write values with `BSONWriter`

Writing a complex `BSONDocument` can be slightly verbose if you have to use `BSONValue` instances directly. Luckily ReactiveMongo provides `BSONHandler`, which is both `BSONReader` and `BSONWriter`. A `BSONWriter[T, B <: BSONValue]` is an instance that transforms some `T` instance into a `BSONValue`. A `BSONReader[B <: BSONValue, T]` is an instance that transforms a `BSONValue` into a `T` instance.

There are some predefined (implicit) handlers that are available when you import `reactivemongo.bson._`, including:

- `String` <-> `BSONString`
- `Int` <-> `BSONInteger`
- `Long` <-> `BSONLong`
- `Double` <-> `BSONDouble`
- `Boolean` <-> `BSONBoolean`

Each value that can be written using a `BSONWriter` can be used directly when calling a `BSONDocument` constructor.

{% highlight scala %}
val album2 = BSONDocument(
  "title" -> "Everybody Knows this is Nowhere",
  "releaseYear" -> 1969)
{% endhighlight %}

Easier, right? Note that this does _not_ use implicit conversions, but rather implicit type classes.

### Read values with `BSONReader`

Getting values follow the same principle using `getAs(String)` method. This method is parametrized with a type that can be transformed into a `BSONValue` using a `BSONReader` instance that is implicitly available in the scope (again, the default readers are already imported if you imported `reactivemongo.bson._`.) If the value could not be found, or if the reader could not deserialize it (often because the type did not match), `None` will be returned.

{% highlight scala %}
  val albumTitle2 = album2.getAs[String]("title") // Some("Everybody Knows this is Nowhere")
  val albumTitle3 = album2.getAs[BSONString]("title") // Some(BSONString("Everybody Knows this is Nowhere"))
{% endhighlight %}

Another cool feature of `BSONDocument` constructors is to give `Option[BSONValue]` (or `Option`s of instances that can be written into `BSONValue`s). The resulting `BSONDocument` will contain only defined options.

{% highlight scala %}
val album3 = BSONDocument(
  "title" -> "Everybody Knows this is Nowhere",
  "releaseYear" -> 1969,
  "hiddenTrack" -> None,
  "allMusicRating" -> Some(5.0))

val album3PrettyBSONRepresentation = BSONDocument.pretty(album3)
/* gives:
 * {
 *   title: BSONString(Everybody Knows this is Nowhere),
 *   releaseYear: BSONInteger(1969),
 *   allMusicRating: BSONDouble(5.0)
 * }
 */
{% endhighlight %}

### Read/Write complex documents with `BSONDocumentReader` and `BSONDocumentWriter`

You can write your own Writers and Readers for your models. Let's define a model for `Album`, and its `BSONWriter` and `BSONReader`.

{% highlight scala %}
case class SimpleAlbum(
  title: String,
  releaseYear: Int,
  hiddenTrack: Option[String],
  allMusicRating: Option[Double])

implicit object SimpleAlbumWriter extends BSONDocumentWriter[SimpleAlbum] {
  def write(album: SimpleAlbum): BSONDocument = BSONDocument(
    "title" -> album.title,
    "releaseYear" -> album.releaseYear,
    "hiddenTrack" -> album.hiddenTrack,
    "allMusicRating" -> album.allMusicRating)
}

implicit object SimpleAlbumReader extends BSONDocumentReader[SimpleAlbum] {
  def read(doc: BSONDocument): SimpleAlbum = {
    SimpleAlbum(
      doc.getAs[String]("title").get,
      doc.getAs[Int]("releaseYear").get,
      doc.getAs[String]("hiddenTrack"),
      doc.getAs[Double]("allMusicRating"))
  }
}
{% endhighlight %}

You should have noted that our reader and writer extend `BSONDocumentReader[T]` and `BSONDocumentWriter[T]`. These two traits are just a shorthand for `BSONReader[B <: BSONValue, T]` and `BSONWriter[T, B <: BSONValue]`.

OK, now, what if I want to store all the tracks names of the album? Or, in other words, how can we deal with collections? First of all, you can safely infer that all seqs and sets can be serialized as `BSONArray`s. Using `BSONArray` follows the same patterns as `BSONDocument`.

{% highlight scala %}
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

val tracksOfAlbum4 = album4.getAs[BSONArray]("tracks").map { array =>
  array.values.map { track =>
    // here, I get a track as a BSONValue.
    // I can use `seeAsOpt[T]` to safely get an Option of its value as a `T`
    track.seeAsOpt[String].get
  }
}
{% endhighlight %}

Using `BSONArray` does what we want, but this code is pretty verbose. Would it not be nice to deal directly with collections?

Here again, there is a converter for `Traversable`s of types that can be transformed into `BSONValue`s. For example, if you have a `List[Something]`, if there is an implicit `BSONWriter` of `Something` to some `BSONValue` in the scope, you can use it as is, without giving explicitly a `BSONArray`. The same logic applies for reading `BSONArray` values.

{% highlight scala %}
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

val tracksOfAlbum5 = album5.getAs[List[String]]("tracks")
// returns an Option[List[String]] if `tracks` is a BSONArray containing BSONStrings :)
{% endhighlight %}

So, now we can rewrite our reader and writer for albums including tracks.

{% highlight scala %}
case class Album(
  title: String,
  releaseYear: Int,
  hiddenTrack: Option[String],
  allMusicRating: Option[Double],
  tracks: List[String])

implicit object AlbumWriter extends BSONDocumentWriter[Album] {
  def write(album: Album): BSONDocument = BSONDocument(
    "title" -> album.title,
    "releaseYear" -> album.releaseYear,
    "hiddenTrack" -> album.hiddenTrack,
    "allMusicRating" -> album.allMusicRating,
    "tracks" -> album.tracks)
}

implicit object AlbumReader extends BSONDocumentReader[Album] {
  def read(doc: BSONDocument): Album = Album(
    doc.getAs[String]("title").get,
    doc.getAs[Int]("releaseYear").get,
    doc.getAs[String]("hiddenTrack"),
    doc.getAs[Double]("allMusicRating"),
    doc.getAs[List[String]]("tracks").toList.flatten)
}
{% endhighlight %}

Obviously, you can combine these readers and writers to de/serialize more complex object graphs. Let's write an Artist model, containing a list of Albums.

{% highlight scala %}
case class Artist(
  name: String,
  albums: List[Album])

implicit object ArtistWriter extends BSONDocumentWriter[Artist] {
  def write(artist: Artist): BSONDocument = BSONDocument(
    "name" -> artist.name,
    "albums" -> artist.albums)
}

implicit object ArtistReader extends BSONDocumentReader[Artist] {
  def read(doc: BSONDocument): Artist = Artist(
    doc.getAs[String]("name").get,
    doc.getAs[List[Album]]("albums").toList.flatten)
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

val neilYoungDoc = BSON.write(neilYoung)
{% endhighlight %}

Here, we get an "ambiguous implicits" problem, which is normal because we have more than one Reader of `BSONDocument`s available in our scope (`SimpleArtistReader`, `ArtistReader`, `AlbumReader`, etc.). So we have to explicitly give the type of the instance we want to get from the document.

{% highlight scala %}
val neilYoungAgain = BSON.readDocument[Artist](neilYoungDoc)
{% endhighlight %}
