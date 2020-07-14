---
layout: default
major_version: 1.0
title: GridFS
---

## GridFS

[GridFS](https://docs.mongodb.com/manual/core/gridfs/) is a way to store and retrieve files using MongoDB.

ReactiveMongo provides an [API for MongoDB GridFS](../../api/reactivemongo/gridfs/GridFS.GridFS), whose references can be resolved as bellow.

{% highlight scala %}
import reactivemongo.api.DB
import reactivemongo.api.bson.collection.BSONSerializationPack
import reactivemongo.api.gridfs.GridFS

type BSONGridFS = GridFS[BSONSerializationPack.type]
def resolveGridFS(db: DB): BSONGridFS = db.gridfs
{% endhighlight %}

### Save files to GridFS

Once a reference to GridFS is obtained, it can be used to push a file in a streaming way (for now using Play Iteratees).

{% highlight scala %}
import scala.concurrent.{ ExecutionContext, Future }

import play.api.libs.iteratee.Enumerator

import reactivemongo.api.bson.collection.BSONSerializationPack
import reactivemongo.api.gridfs.GridFS
import reactivemongo.api.bson.BSONValue

def saveToGridFS(
  gfs: GridFS[BSONSerializationPack.type],
  filename: String, 
  contentType: Option[String], 
  data: java.io.InputStream
)(implicit ec: ExecutionContext): Future[gfs.ReadFile[BSONValue]] = {
  // Prepare the GridFS object to the file to be pushed
  val gridfsObj = gfs.fileToSave(Some(filename), contentType)

  gfs.writeFromInputStream(gridfsObj, data)
}
{% endhighlight %}

A function [`update`](https://static.javadoc.io/org.reactivemongo/reactivemongo_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo/api/gridfs/GridFS.html#update) is provided to update the file metadata.

{% highlight scala %}
import scala.concurrent.ExecutionContext

import reactivemongo.api.bson.{ BSONDocument, BSONObjectID }

import reactivemongo.api.DB
import reactivemongo.api.gridfs.GridFS

def updateFile(db: DB, fileId: BSONObjectID)(implicit ec: ExecutionContext) =
  db.gridfs.update(fileId, BSONDocument(f"$$set" ->
    BSONDocument("meta" -> "data")))
{% endhighlight %}

The GridFS [`writeFromInputStream`](../../api/reactivemongo/gridfs/GridFS.html) operation will return a reference to the stored object, represented with the [`ReadFile`](../../api/reactivemongo/gridfs/GridFS.ReadFile) type.

The reference for a file save in this way will have `Some` [MD5 property](../../api/reactivemongo/gridfs/GridFS.ReadFile@md5:Option[String]).

The [Akka Stream module](../tutorial/streaming.html#akka-stream) is providing the [`GridFSStreams.sinkWithMD5`](https://oss.sonatype.org/service/local/repositories/releases/archive/org/reactivemongo/reactivemongo-akkastream_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo-akkastream_{{site._1_0_scala_major}}-{{site._1_0_latest_minor}}-javadoc.jar/!/reactivemongo/akkastream/GridFSStreams.html#sinkWithMD5[Id%3C:GridFSStreams.this.gridfs.pack.Value](file:reactivemongo.api.gridfs.FileToSave[GridFSStreams.this.gridfs.pack.type,Id],chunkSize:Int)(implicitreadFileReader:GridFSStreams.this.gridfs.pack.Reader[GridFSStreams.this.gridfs.ReadFile[Id]],implicitec:scala.concurrent.ExecutionContext,implicitidProducer:reactivemongo.api.gridfs.IdProducer[Id],implicitdocWriter:reactivemongo.api.bson.BSONDocumentWriter[file.pack.Document]):akka.stream.scaladsl.Sink[akka.util.ByteString,scala.concurrent.Future[GridFSStreams.this.gridfs.ReadFile[Id]]]), which allows to stream data to a GridFS file.

{% highlight scala %}
import scala.concurrent.Future

import akka.NotUsed
import akka.util.ByteString

import akka.stream.Materializer
import akka.stream.scaladsl.Source

import reactivemongo.api.bson.BSONValue
import reactivemongo.api.bson.collection.BSONSerializationPack

import reactivemongo.api.gridfs.GridFS

import reactivemongo.akkastream.GridFSStreams

def saveWithComputedMD5(
  gfs: GridFS[BSONSerializationPack.type],
  filename: String, 
  contentType: Option[String], 
  data: Source[ByteString, NotUsed]
)(implicit m: Materializer): Future[gfs.ReadFile[BSONValue]] = {
  implicit def ec = m.executionContext

  // Prepare the GridFS object to the file to be pushed
  val gridfsObj = gfs.fileToSave(Some(filename), contentType)

  val streams = GridFSStreams[BSONSerializationPack.type](gfs)
  val upload = streams.sinkWithMD5(gridfsObj)

  data.runWith(upload)
}
{% endhighlight %}

### Find a file from GridFS

A file previously stored in a GridFS can be retrieved as any MongoDB, using a [`find`](../../api/reactivemongo/gridfs/GridFS.GridFS#find[S,T%3C:GridFS.this.ReadFile[_]](selector:S)(implicitsWriter:GridFS.this.pack.Writer[S],implicitreadFileReader:GridFS.this.pack.Reader[T],implicitctx:scala.concurrent.ExecutionContext,implicitcp:reactivemongo.api.CursorProducer[T]):cp.ProducedCursor) operation.

{% highlight scala %}
import scala.concurrent.{ ExecutionContext, Future }

import reactivemongo.api.bson.collection.BSONSerializationPack
import reactivemongo.api.gridfs.{ GridFS, ReadFile }
import reactivemongo.api.bson.{ BSONDocument, BSONValue }

def gridfsByFilename(
  gridfs: GridFS[BSONSerializationPack.type],
  filename: String
)(implicit ec: ExecutionContext): Future[ReadFile[BSONValue, BSONDocument]] = {
  def cursor = gridfs.find(BSONDocument("filename" -> filename))
  cursor.head
}
{% endhighlight %}

The [Akka Stream module](../tutorial/streaming.html#akka-stream) is providing the [`GridFSStreams.source`](https://oss.sonatype.org/service/local/repositories/releases/archive/org/reactivemongo/reactivemongo-akkastream_{{site._1_0_scala_major}}/{{site._1_0_latest_minor}}/reactivemongo-akkastream_{{site._1_0_scala_major}}-{{site._1_0_latest_minor}}-javadoc.jar/!/reactivemongo/akkastream/GridFSStreams.html#source[Id%3C:GridFSStreams.this.gridfs.pack.Value](file:GridFSStreams.this.gridfs.ReadFile[Id],readPreference:reactivemongo.api.ReadPreference)(implicitm:akka.stream.Materializer,implicitidProducer:reactivemongo.api.gridfs.IdProducer[Id]):akka.stream.scaladsl.Source[akka.util.ByteString,scala.concurrent.Future[reactivemongo.akkastream.State]]) to stream data from GridFS file.

{% highlight scala %}
import scala.concurrent.Future

import akka.util.ByteString

import akka.stream.Materializer
import akka.stream.scaladsl.Source

import reactivemongo.api.bson.collection.BSONSerializationPack
import reactivemongo.api.gridfs.GridFS
import reactivemongo.api.bson.BSONDocument

import reactivemongo.akkastream.{ GridFSStreams, State }

def downloadGridFSFile(
  gridfs: GridFS[BSONSerializationPack.type],
  filename: String
)(implicit m: Materializer): Source[ByteString, Future[State]] = {
  implicit def ec = m.executionContext

  val src = gridfs.find(BSONDocument("filename" -> filename)).head.map { file =>
    val streams = GridFSStreams(gridfs)

    streams.source(file)
  }

  Source.fromFutureSource(src).mapMaterializedValue(_.flatten)
}
{% endhighlight %}

### Delete a file

A file can be removed from a GridFS using the [appropriate operation](../../api/reactivemongo/gridfs/GridFS.GridFS#remove[Id%3C:GridFS.this.pack.Value](id:Id)(implicitctx:scala.concurrent.ExecutionContext,implicitidProducer:reactivemongo.api.gridfs.IdProducer[Id]):scala.concurrent.Future[reactivemongo.api.commands.WriteResult]).

{% highlight scala %}
import scala.concurrent.{ ExecutionContext, Future }

import reactivemongo.api.bson.collection.BSONSerializationPack
import reactivemongo.api.gridfs.GridFS
import reactivemongo.api.bson.BSONValue

def removeFrom(
  gridfs: GridFS[BSONSerializationPack.type],
  id: BSONValue // see ReadFile.id
)(implicit ec: ExecutionContext): Future[Unit] =
  gridfs.remove(id).map(_ => {})
{% endhighlight %}

**See also:**

- Some [GridFS tests](https://github.com/ReactiveMongo/ReactiveMongo/blob/{{site._1_0_latest_minor}}/driver/src/test/scala/GridfsSpec.scala)
- An [example with Play](../tutorial/play.html#helpers-for-gridfs)
