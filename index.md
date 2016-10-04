---
layout: home
title: Home
---

[ReactiveMongo](https://github.com/ReactiveMongo/ReactiveMongo/) is a Scala driver that provides fully non-blocking and asynchronous I/O operations.

## Scale better, use less threads

With a classic synchronous database driver, each operation blocks the current thread until a response is received. This model is simple but has a major flaw - it can't scale that much.

Imagine that you have a web application with 10 concurrent accesses to the database. That means you eventually end up with 10 frozen threads at the same time, doing nothing but waiting for a response. A common solution is to rise the number of running threads to handle more requests. Such a waste of resources is not really a problem if your application is not heavily loaded, but what happens if you have 100 or even 1000 more requests to handle, performing each several DB queries? The multiplication grows really fast...

The problem is getting more and more obvious while using the new generation of web frameworks. What's the point of using a nifty, powerful, fully asynchronous web framework if all your database accesses are blocking?

ReactiveMongo is designed to avoid any kind of blocking request. Every operation returns immediately, freeing the running thread and resuming execution when it is over. Accessing the database is not a bottleneck any more.

## Let the stream flow!

The future of the web is in streaming data to a very large number of clients simultaneously. Twitter Stream API is a good example of this paradigm shift that is radically altering the way data is consumed all over the web.

ReactiveMongo enables you to build such a web application right now. It allows you to stream data both into and from your MongoDB servers.

One scenario could be consuming progressively your collection of documents as needed without filling memory unnecessarily.

But if what you're interested in is live feeds then you can stream a MongoDB [capped collection](http://www.mongodb.org/display/DOCS/Tailable+Cursors) through a WebSocket, comet or any other streaming protocol. A capped collection is a fixed-size (FIFO) collection from which you can fetch documents as they are inserted. Each time a document is stored into this collection, the Web application broadcasts it to all the interested clients, in a complete non-blocking way.

Moreover, you can now use GridFS as a non-blocking, streaming data store. ReactiveMongo retrieves the file, chunk by chunk, and streams it until the client is done or there's no more data. Neither huge memory consumption, nor blocked thread during the process!

[More: **Get Started**](/releases/{{site.latest_major_release}}/documentation/tutorial/getstarted.html)

### Samples

{% include samples.md %}
