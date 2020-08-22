---
layout: default
major_version: 0.1x
title: GridFS
---

## GridFS

[GridFS](https://docs.mongodb.com/manual/core/gridfs/) is a way to store and retrieve files using MongoDB.

ReactiveMongo provides an [API for MongoDB GridFS](../../api/reactivemongo/gridfs/GridFS.GridFS), whose references can be resolved as bellow.

```scala
import reactivemongo.api.{ BSONSerializationPack, DefaultDB }
import reactivemongo.api.gridfs.GridFS

type BSONGridFS = GridFS[BSONSerializationPack.type]
def resolveGridFS(db: DefaultDB): BSONGridFS = GridFS(db)
```

### Save files to GridFS

Once a reference to GridFS is obtained, it can be used to push a file in a streaming way (for now using Play Iteratees).

```scala
import scala.concurrent.{ ExecutionContext, Future }

import play.api.libs.iteratee.Enumerator

import reactivemongo.api.BSONSerializationPack
import reactivemongo.api.gridfs.{ DefaultFileToSave, GridFS }
import reactivemongo.api.gridfs.Implicits._
import reactivemongo.bson.BSONValue

type BSONFile = 
  reactivemongo.api.gridfs.ReadFile[BSONSerializationPack.type, BSONValue]

def saveToGridFS(
  gridfs: GridFS[BSONSerializationPack.type],
  filename: String, 
  contentType: Option[String], 
  data: Enumerator[Array[Byte]]
)(implicit ec: ExecutionContext): Future[BSONFile] = {
  // Prepare the GridFS object to the file to be pushed
  val gridfsObj = DefaultFileToSave(Some(filename), contentType)

  gridfs.save(data, gridfsObj)
}
```

The GridFS [`save`](../../api/reactivemongo/gridfs/GridFS.GridFS#save[Id%3C:GridFS.this.pack.Value](enumerator:play.api.libs.iteratee.Enumerator[Array[Byte]],file:reactivemongo.api.gridfs.FileToSave[GridFS.this.pack.type,Id],chunkSize:Int)(implicitreadFileReader:GridFS.this.pack.Reader[GridFS.this.ReadFile[Id]],implicitctx:scala.concurrent.ExecutionContext,implicitidProducer:reactivemongo.api.gridfs.IdProducer[Id],implicitdocWriter:reactivemongo.bson.BSONDocumentWriter[file.pack.Document]):scala.concurrent.Future[GridFS.this.ReadFile[Id]]) operation will return a reference to the stored object, represented with the [`ReadFile`](../../api/reactivemongo/gridfs/GridFS.ReadFile) type.

An alternative operation [`saveWithMD5`](../../api/reactivemongo/gridfs/GridFS.GridFS#saveWithMD5[Id%3C:GridFS.this.pack.Value](enumerator:play.api.libs.iteratee.Enumerator[Array[Byte]],file:reactivemongo.api.gridfs.FileToSave[GridFS.this.pack.type,Id],chunkSize:Int)(implicitreadFileReader:GridFS.this.pack.Reader[GridFS.this.ReadFile[Id]],implicitctx:scala.concurrent.ExecutionContext,implicitidProducer:reactivemongo.api.gridfs.IdProducer[Id],implicitdocWriter:reactivemongo.bson.BSONDocumentWriter[file.pack.Document]):scala.concurrent.Future[GridFS.this.ReadFile[Id]]), which can automatically compute a MD5 checksum for the stored data.

```scala
import scala.concurrent.{ ExecutionContext, Future }

import play.api.libs.iteratee.Enumerator

import reactivemongo.api.BSONSerializationPack
import reactivemongo.api.gridfs.{ DefaultFileToSave, GridFS }
import reactivemongo.api.gridfs.Implicits._

def saveWithComputedMD5(
  gridfs: GridFS[BSONSerializationPack.type],
  filename: String, 
  contentType: Option[String], 
  data: Enumerator[Array[Byte]]
)(implicit ec: ExecutionContext): Future[BSONFile] = {
  // Prepare the GridFS object to the file to be pushed
  val gridfsObj = DefaultFileToSave(Some(filename), contentType)

  gridfs.saveWithMD5(data, gridfsObj)
}
```

The reference for a file save in this way will have `Some` [MD5 property](../../api/reactivemongo/gridfs/GridFS.ReadFile@md5:Option[String]).

The [Akka Stream module](../tutorial/streaming.html#akka-stream) is providing the [`GridFSStreams.sinkWithMD5`](https://oss.sonatype.org/service/local/repositories/releases/archive/org/reactivemongo/reactivemongo-akkastream_{{site._0_1x_scala_major}}/{{site._0_1x_latest_minor}}/reactivemongo-akkastream_{{site._0_1x_scala_major}}-{{site._0_1x_latest_minor}}-javadoc.jar/!/reactivemongo/akkastream/GridFSStreams.html#sinkWithMD5[Id%3C:GridFSStreams.this.gridfs.pack.Value](file:reactivemongo.api.gridfs.FileToSave[GridFSStreams.this.gridfs.pack.type,Id],chunkSize:Int)(implicitreadFileReader:GridFSStreams.this.gridfs.pack.Reader[GridFSStreams.this.gridfs.ReadFile[Id]],implicitec:scala.concurrent.ExecutionContext,implicitidProducer:reactivemongo.api.gridfs.IdProducer[Id],implicitdocWriter:reactivemongo.bson.BSONDocumentWriter[file.pack.Document]):akka.stream.scaladsl.Sink[akka.util.ByteString,scala.concurrent.Future[GridFSStreams.this.gridfs.ReadFile[Id]]]), which allows to stream data to a GridFS file.

```scala
import scala.concurrent.Future

import akka.NotUsed
import akka.util.ByteString

import akka.stream.Materializer
import akka.stream.scaladsl.Source

import reactivemongo.api.BSONSerializationPack
import reactivemongo.api.gridfs.{ DefaultFileToSave, GridFS }

import reactivemongo.akkastream.GridFSStreams

def saveWithComputedMD5(
  gridfs: GridFS[BSONSerializationPack.type],
  filename: String, 
  contentType: Option[String], 
  data: Source[ByteString, NotUsed]
)(implicit m: Materializer): Future[BSONFile] = {
  implicit def ec = m.executionContext

  // Prepare the GridFS object to the file to be pushed
  val gridfsObj = DefaultFileToSave(Some(filename), contentType)

  val streams = GridFSStreams(gridfs)
  val upload = streams.sinkWithMD5(gridfsObj)

  data.runWith(upload)
}
```

### Find a file from GridFS

A file previously stored in a GridFS can be retrieved as any MongoDB, using a [`find`](../../api/reactivemongo/gridfs/GridFS.GridFS#find[S,T%3C:GridFS.this.ReadFile[_]](selector:S)(implicitsWriter:GridFS.this.pack.Writer[S],implicitreadFileReader:GridFS.this.pack.Reader[T],implicitctx:scala.concurrent.ExecutionContext,implicitcp:reactivemongo.api.CursorProducer[T]):cp.ProducedCursor) operation.

```scala
import scala.concurrent.{ ExecutionContext, Future }

import reactivemongo.api.BSONSerializationPack
import reactivemongo.api.gridfs.{ GridFS, ReadFile }
import reactivemongo.api.gridfs.Implicits._
import reactivemongo.bson.{ BSONDocument, BSONValue }

def gridfsByFilename(
  gridfs: GridFS[BSONSerializationPack.type],
  filename: String
)(implicit ec: ExecutionContext): Future[ReadFile[BSONSerializationPack.type, BSONValue]] = {
  def cursor = gridfs.find(BSONDocument("filename" -> filename))
  cursor.head
}
```

The [Akka Stream module](../tutorial/streaming.html#akka-stream) is providing the [`GridFSStreams.source`](https://oss.sonatype.org/service/local/repositories/releases/archive/org/reactivemongo/reactivemongo-akkastream_{{site._0_1x_scala_major}}/{{site._0_1x_latest_minor}}/reactivemongo-akkastream_{{site._0_1x_scala_major}}-{{site._0_1x_latest_minor}}-javadoc.jar/!/reactivemongo/akkastream/GridFSStreams.html#source[Id%3C:GridFSStreams.this.gridfs.pack.Value](file:GridFSStreams.this.gridfs.ReadFile[Id],readPreference:reactivemongo.api.ReadPreference)(implicitm:akka.stream.Materializer,implicitidProducer:reactivemongo.api.gridfs.IdProducer[Id]):akka.stream.scaladsl.Source[akka.util.ByteString,scala.concurrent.Future[reactivemongo.akkastream.State]]) to stream data from GridFS file.

```scala
import scala.concurrent.Future

import akka.util.ByteString

import akka.stream.Materializer
import akka.stream.scaladsl.Source

import reactivemongo.api.BSONSerializationPack
import reactivemongo.api.gridfs.GridFS
import reactivemongo.bson.BSONDocument

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
```

### Delete a file

A file can be removed from a GridFS using the [appropriate operation](../../api/reactivemongo/gridfs/GridFS.GridFS#remove[Id%3C:GridFS.this.pack.Value](id:Id)(implicitctx:scala.concurrent.ExecutionContext,implicitidProducer:reactivemongo.api.gridfs.IdProducer[Id]):scala.concurrent.Future[reactivemongo.api.commands.WriteResult]).

```scala
import scala.concurrent.{ ExecutionContext, Future }

import reactivemongo.api.BSONSerializationPack
import reactivemongo.api.gridfs.GridFS //, ReadFile }
//import reactivemongo.api.gridfs.Implicits._
import reactivemongo.bson.BSONValue

def removeFrom(
  gridfs: GridFS[BSONSerializationPack.type],
  id: BSONValue // see ReadFile.id
)(implicit ec: ExecutionContext): Future[Unit] =
  gridfs.remove(id).map(_ => {})
```

**See also:**

- Some [GridFS tests](https://github.com/ReactiveMongo/ReactiveMongo/blob/{{site._0_1x_latest_minor}}/driver/src/test/scala/GridfsSpec.scala)
- An [example with Play](../tutorial/play.html#helpers-for-gridfs)

### Troubleshooting

For the GridFS `save` operation, the following compilation error can be raised when the required `Reader` is missing.

    could not find implicit value for parameter readFileReader: gfs.pack.Reader[gfs.ReadFile[reactivemongo.bson.BSONValue]]
    
It can be easily fixed by adding the appropriate import:

    import reactivemongo.api.gridfs.Implicits._

A similar compilation error can occur for the `find` operation:

    could not find implicit value for parameter readFileReader: gridfs.pack.Reader[T]
    
It's fixed by the same import.
