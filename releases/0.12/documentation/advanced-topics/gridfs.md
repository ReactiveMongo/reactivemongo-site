---
layout: default
major_version: 0.12
title: GridFS
---

## GridFS

[GridFS](https://docs.mongodb.com/manual/core/gridfs/) is a way to store and retrieve files using MongoDB.

ReactiveMongo provides an [API for MongoDB GridFS](../../api/index.html#reactivemongo.api.gridfs.GridFS), whose references can be resolved as bellow.

{% highlight scala %}
import reactivemongo.api.{ BSONSerializationPack, DefaultDB }
import reactivemongo.api.gridfs.GridFS

type BSONGridFS = GridFS[BSONSerializationPack.type]
def resolveGridFS(db: DefaultDB): BSONGridFS = GridFS(db)
{% endhighlight %}

### Save files to GridFS

Once a reference to GridFS is obtained, it can be used to push a file in a streaming way (for now using Play Iteratees).

{% highlight scala %}
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
{% endhighlight %}

The GridFS [`save`](../../api/index.html#reactivemongo.api.gridfs.GridFS@save[Id%3C:GridFS.this.pack.Value](enumerator:play.api.libs.iteratee.Enumerator[Array[Byte]],file:reactivemongo.api.gridfs.FileToSave[GridFS.this.pack.type,Id],chunkSize:Int)(implicitreadFileReader:GridFS.this.pack.Reader[GridFS.this.ReadFile[Id]],implicitctx:scala.concurrent.ExecutionContext,implicitidProducer:reactivemongo.api.gridfs.IdProducer[Id],implicitdocWriter:reactivemongo.bson.BSONDocumentWriter[file.pack.Document]):scala.concurrent.Future[GridFS.this.ReadFile[Id]]) operation will return a reference to the stored object, represented with the [`ReadFile`](../../api/index.html#reactivemongo.api.gridfs.ReadFile) type.

An alternative operation [`saveWithMD5`](../../api/index.html#reactivemongo.api.gridfs.GridFS@saveWithMD5[Id%3C:GridFS.this.pack.Value](enumerator:play.api.libs.iteratee.Enumerator[Array[Byte]],file:reactivemongo.api.gridfs.FileToSave[GridFS.this.pack.type,Id],chunkSize:Int)(implicitreadFileReader:GridFS.this.pack.Reader[GridFS.this.ReadFile[Id]],implicitctx:scala.concurrent.ExecutionContext,implicitidProducer:reactivemongo.api.gridfs.IdProducer[Id],implicitdocWriter:reactivemongo.bson.BSONDocumentWriter[file.pack.Document]):scala.concurrent.Future[GridFS.this.ReadFile[Id]]), which can automatically compute a MD5 checksum for the stored data.

{% highlight scala %}
import scala.concurrent.{ ExecutionContext, Future }

import play.api.libs.iteratee.Enumerator

import reactivemongo.api.BSONSerializationPack
import reactivemongo.api.gridfs.{ DefaultFileToSave, GridFS }
import reactivemongo.api.gridfs.Implicits._
import reactivemongo.bson.BSONValue

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
{% endhighlight %}

The reference for a file save in this way will have `Some` [MD5 property](../../api/index.html#reactivemongo.api.gridfs.ReadFile@md5:Option[String]).

### Find a file from GridFS

A file previously stored in a GridFS can be retrieved as any MongoDB, using a [`find`](../../api/index.html#reactivemongo.api.gridfs.GridFS@find[S,T%3C:GridFS.this.ReadFile[_]](selector:S)(implicitsWriter:GridFS.this.pack.Writer[S],implicitreadFileReader:GridFS.this.pack.Reader[T],implicitctx:scala.concurrent.ExecutionContext,implicitcp:reactivemongo.api.CursorProducer[T]):cp.ProducedCursor) operation.

{% highlight scala %}
import scala.concurrent.{ ExecutionContext, Future }

import play.api.libs.iteratee.Enumerator

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
{% endhighlight %}

### Delete a file

A file can be removed from a GridFS using the [appropriate operation](../../api/index.html#reactivemongo.api.gridfs.GridFS@remove[Id%3C:GridFS.this.pack.Value](id:Id)(implicitctx:scala.concurrent.ExecutionContext,implicitidProducer:reactivemongo.api.gridfs.IdProducer[Id]):scala.concurrent.Future[reactivemongo.api.commands.WriteResult]).

{% highlight scala %}
import scala.concurrent.{ ExecutionContext, Future }

import play.api.libs.iteratee.Enumerator

import reactivemongo.api.BSONSerializationPack
import reactivemongo.api.gridfs.GridFS //, ReadFile }
//import reactivemongo.api.gridfs.Implicits._
import reactivemongo.bson.{ BSONDocument, BSONValue }

def removeFrom(
  gridfs: GridFS[BSONSerializationPack.type],
  id: BSONValue // see ReadFile.id
)(implicit ec: ExecutionContext): Future[Unit] =
  gridfs.remove(id).map(_ => {})
{% endhighlight %}

**See also:**

- Some [GridFS tests](https://github.com/ReactiveMongo/ReactiveMongo/blob/{{site._0_12_latest_minor}}/driver/src/test/scala/GridfsSpec.scala)
- An [example with Play](../tutorial/play.html#helpers-for-gridfs)

### Troubleshooting

For the GridFS `save` operation, the following compilation error can be raised when the required `Reader` is missing.

    could not find implicit value for parameter readFileReader: gfs.pack.Reader[gfs.ReadFile[reactivemongo.bson.BSONValue]]
    
It can be easily fixed by adding the appropriate import:

    import reactivemongo.api.gridfs.Implicits._

A similar compilation error can occur for the `find` operation:

    could not find implicit value for parameter readFileReader: gridfs.pack.Reader[T]
    
It's fixed by the same import.
