# id_factory

A MySQL shared id_factory implemented as a stored function with Percona XtraDB
Cluster support.

This project implements a unique ID generator for MySQL that is independent
from the creation of a table row.  There are several advantages to this method
of unique key generation.  These ID's operate similar to 'sequences' available
in other databases.

# Features

* Identifiers can remain unique across several tables within a database.
* Identifiers can allocated before or during record creation.
* Namespaces can be defined on the fly allowing different sets of identifiers
to be created.
* In most multi-master cluster configurations, id_factory generation will
provide better ID coverage (fewer un-used number gaps) then AUTO_INCREMENT
* id_factory can be configured to handle unique ID's single server systems
that can be scaled up to multi-node environments.

# Dependencies

1.  A MySQL stand-alone server or cluster supporting InnoDB

2.  optional: make and cpp (The C Preprocessor) is used to process the script
    for a given cluster size.

3.  optional: bash, perl and the dbpercona/pmdl (a submodule) are used for
    testing.

4.  optional: The R language is used to graph the testing results for
    performance info.

# Quick Start

1. Load the id_factory.sql script into the your database

      mysql -uroot -ppassword {database} < id_factory.sql

2.  Assign unique identifiers using the id_factory_next() function.

      INSERT INTO mytable VALUES (id_factory_next(''),'ABC Company',...);

# Configure id_factory for your environment

The default id_factory.sql is configured for a maximum 4 node (2-bit) cluster.
This can be verified by examining the INSERT instruction in the
id_factory_next() stored function.  The last value inserted (node_bits) is the
bit-size of the cluster.  A value of 0

The id_factory.cpp.sql script can be configured for various environments by
adjusting the #define statements at the top of this file.

    #define TABLE_NAME

TABLE_NAME defines the name of the table used to store the id factory
information.  The default table name is id_factory.  This can be changed to
another table name if needed.

    #define NODE_BITS

NODE_BITS defines the maximum size of the cluster in which unique id's can be
generated.  A value of 0 will generate id's that will only be unique in
a single server environment.  A value of 1 will support a maximum of 2 nodes.
A value of 2 will support 4 nodes,  3=8, 4=16 and so on.

After these values are set the new id_factory.sql script can be re-built by
using the command:

    make

The Makefile contains rules for installing and running a basic test of the
id_factory_next() function in the 'test' database.

    make test_install

    make test_basic

The MYSQLOPTS value in Makefile can be adjusted to install and test the script
if necessary.

# MySQL Multi-Master AUTO_INCREMENT 

In a multi-master cluster environment, different nodes must be able to create
unique key identifiers independent from one another.  Traditionally,  in
a MySQL environment this is handled by two variables that are assigned to each
node.  In a Percona XtraDB Cluster or other MySQL multi-master cluster
environment this is handled by assigning two global variables to each node.

1. @@auto_increment_offset is the starting offset of the next identifier to be
   assigned to a table row  In order for identifier's to be unique in
   a multi-master environment, this number must be different for each node in
   the cluster.  
   
2. @@auto_increment_increment defines the number of integers left between
   consecutive identifier generation on a node.  This number must be equal to
   or greater than the number of nodes that are active in the cluster at the
   time the id is created.

When using Percona XtraDB Cluster, these values are dynamically assigned as
the cluster grows to insure that there will never be any conflict in the
numeric identifiers assigned to AUTO_INCREMENT columns within a table.

While this method of unique id generation works well and has proven to be
reliable, it has a few disadvantages:

* In a cluster environment, the increment and offset computation leave
a larger number of gaps is the series allowing fewer unique id's to be used by
table rows.
* An AUTO_INCREMENT series is bound to a table column making it difficult for
the identifier series to be used across multiple tables.
* Static SQL scripts that create parent-child 'priming' records using
AUTO_INCREMENT can be harder to write and read than scripts using discretely
generated ids.

# How id_factory works

The id_factory maintains a separate id for each namespace and node
combination.  This id contains two parts,  the most significant bits of the
identifier represent an integer that is incremented by 1 each time an id is
generated on a node for a given namespace.  The least significant bits
represent the node on which the cluster is created.  Since it is guaranteed
that the @@auto_increment_offset value must be unique for each node in the
cluster, we use this value converted from base-1 to base-0 as our value for
the LSB when creating our identifier.

id_factory will work fine with any number of cluster nodes.  The NODE_BITS
value must be large enough to handle unique ids for all of the nodes.
However, for optimal id assignment, the number of nodes in a cluster should be
a power of 2.

*Warning: Long sentence*  

It should also be noted that running a quantity of cluster nodes that are
a power of 2 also means that the garbd arbitrator should be used to avoid
a potential split-brain problem where cluster quorum consensus cannot be
achieved with an equal number of cluster nodes on either side of a broken
connection. 
