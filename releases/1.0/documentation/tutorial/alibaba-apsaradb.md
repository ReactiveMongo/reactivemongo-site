---
layout: default
major_version: 1.0
title: Alibaba ApsaraDB
---

## Alibaba ApsaraDB

[ApsaraDB](https://www.alibabacloud.com/product/apsaradb-for-mongodb) is the database service available on Alibaba Cloud platform, with some compatibility with MongoDB.

> A [free trial](https://www.alibabacloud.com/campaign/free-trial) is available.

Once the ApsaraDB service is enabled, it can be configured, first with the subscription (Region/Zone, Database Version, ...).

<img src="../images/ali-db1.png" alt="Alibaba ApsaraDB Basic configuration" class="screenshot" />

The Network Type is another important section of the configuration.
For DB connectivity, Alibaba Cloud offers either [Virtual Private Cloud](https://www.alibabacloud.com/product/vpc) (VPC) or Classic Network.

<img src="../images/ali-db2.png" alt="Alibaba ApsaraDB Network Type" class="screenshot" />

If choosing VPC, the DB cannot be accessible from outside the Cloud Platform, and the a VPC need to be created before configuring Apsara.

<img src="../images/ali-db3.png" alt="Alibaba Cloud Create VPC" class="screenshot" />

Once the network is configured, the password must be set on ApsaraDB.

<img src="../images/ali-db4.png" alt="Alibaba ApsaraDB Password" class="screenshot" />

When the ApsaraDB is created, Connection Info is visible in the service details.

<img src="../images/ali-db5.png" alt="Alibaba ApsaraDB Connection Info" class="screenshot" />

> Using VPC, it must require to set a network whitelist.

The connection details can be displayed from there.
At this point, it's still possible to update the Network Type associated with the DB service.

<img src="../images/ali-db6.png" alt="Alibaba ApsaraDB Network update" class="screenshot" />

After the service is fully configured, the Connection String URI is visible.

<img src="../images/ali-db7.png" alt="Alibaba ApsaraDB Network update" class="screenshot" />

Finally for ReactiveMongo connection, the `replicaSet` option can be removed from the URI, and the password placeholder must be replaced with the actual value.
                                    
{% highlight javascript %}
# Must be updated according the service configuration

mongodb.uri = "mongodb://root:${APSARADB_PASSWORD}@dds-4e6322c0290348c49176-pub.mongodb.germany.rds.aliyuncs.com:3717,dds-5e2a468b7a9a46b1ab06-pub.mongodb.germany.rds.aliyuncs.com:3717/${APSARADB_DBNAME}"
{% endhighlight %}

*[See the documentation](./connect-database.html)*
