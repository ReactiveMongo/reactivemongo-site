We assume that you got a running MongoDB instance. If not, get [the latest MongoDB binaries](http://www.mongodb.org/downloads) and unzip the archive. Then you can launch the database:

```sh
$ mkdir /path/to/data
$ /path/to/bin/mongod --dbpath /path/to/data
```

This will start a standalone MongoDB instance that stores its data in the ```data``` directory and listens on the TCP port 27017.