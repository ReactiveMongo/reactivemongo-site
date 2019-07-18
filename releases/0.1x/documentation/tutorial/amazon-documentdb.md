---
layout: default
major_version: 0.1x
title: Amazon DocumentDB
---

## Amazon DocumentDB

[Amazon DocumentDB](https://aws.amazon.com/documentdb/) is the database service available on Amazon AWS platform, with some [compatibility with MongoDB](https://www.mongodb.com/atlas-vs-amazon-documentdb).

Once DocumentDB service is enable, a [cluster can be created](https://console.aws.amazon.com/docdb/) in the AWS console, its name and authentication can be checked in the configuration.

<img src="../images/aws-docdb1.png" alt="Amazon DocumentDB configuration" class="screenshot" />

The created cluster is visible in DocumentDB Cluster list.

<img src="../images/aws-docdb2.png" alt="Amazon DocumentDB clusters" class="screenshot" />

Clicking on the cluster displays the details required to connect.

<img src="../images/aws-docdb3.png" alt="Amazon DocumentDB Cluster details" class="screenshot" />

From there, the connection URI can be copied, with placeholder `<insertYourPassword>` replace with actual password.

Note the `ssl=true` and the `ssl_ca_certs=rds-combined-ca-bundle.pem` options, as AWS DocumentDB is configured by default with SSL using the AWS RDS certificates.

As indicated in the [AWS documentation](https://docs.aws.amazon.com/fr_fr/AmazonRDS/latest/UserGuide/UsingWithRDS.SSL.html), the [`rds-combined-ca-bundle.pem`](https://s3.amazonaws.com/rds-downloads/rds-combined-ca-bundle.pem) or the [`rds-ca-2015-root.pem`](https://s3.amazonaws.com/rds-downloads/rds-ca-2015-root.pem) can be downloaded.
The later is sufficient for client connection.

As the certificates are not available in the [Java KeyStore format](https://en.wikipedia.org/wiki/Java_KeyStore) (JKS), the certificates provided in [PEM format must be converted](https://docs.oracle.com/cd/E35976_01/server.740/es_admin/src/tadm_ssl_convert_pem_to_jks.html), thereafter as `rds-ca-2015-root.jks` with password `rds-ca-2015-root`.

Finally the connection URI can be updated by replacing the option `ssl_ca_certs` with `keyStore` (URI to JKS file, there on local FS using `file://`), `keyStorePassword` (there `rds-ca-2015-root`) and `keyStoreType=JKS`.

{% highlight javascript %}
mongodb.uri = "mongodb://test:MY_PASSWORD@testdb-2019-07-17-19-05-33.cluster-czwefgzvoxnq.us-east-2.docdb.amazonaws.com:27017/testdb?ssl=true&keyStore=file:///path/on/local/fs/to/rds-ca-2015-root.jks&keyStorePassword=rds-ca-2015-root&keyStoreType=JKS"
{% endhighlight %}

*[See the documentation](./connect-database.html)*