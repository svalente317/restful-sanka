Storage Service
===============

## Overview

The restful-sanka Storage service is an object store, intended to be
used by other (higher-level) restful-sanka services.

To write an object to storage, post to `/storage`. Post a JSON object
which includes the fields `storageKey` and `generation`. Those are the
only fields that are accessed by the Storage service. In addition to
those fields, the object can contain whatever data you want to store --
any valid JSON field names, types, and values.

* `storageKey` - This is the primary key, used to index the object.
  The storage key uses a pathname-like abstraction. It's a sequence of
  short alpha-numeric names, separated by slashes. You can think of
  all of the names up to the last one as "directory" names or "folder"
  names, and you can think of the last one as the resource name. An
  example of a good storageKey is "/users/bob". In many cases, it's
  best to use a UID as the resource name, like "/users/u17017".  Then
  the person's name (which may contain non-alpha-numeric characters)
  can be stored in a field in the object.

* `generation` - For the storage service to accept a resource update
  post, the posted generation must be higher then the resource's
  current generation. This avoids race conditions. It provides a kind
  of atomicity. If two different users view the same resource at the
  same time, and they both view it as generation 2, and then they both
  try to update it by posting a new version of the resource with
  generation 3, then one of the posts will be accepted, and the other
  will be rejected.

To read an object from storage, send a query to `/storage` with the
`storageKey` query parameter.

To update an object, post the same storageKey with a higher generation.
The new generation is compared to the current generation, but no data
is inherited from the current object. The object is completely replaced
by the newly posted object as-is, even if the schema (field names and
types) is completely different.

To delete an object, send an http DELETE request, and include the
`storageKey` query parameter.

### Example

Post an object:
```
curl -s http://localhost:8888/storage -d '
{
    "storageKey": "/users/u17017",
    "generation": 1,
    "Name": "Homer Simpson",
    "Address": "123 Fake St.",
    "children": ["Bart", "Lisa", "Maggie"]
}'
```
Get the object from storage:
```
curl -s http://localhost:8888/storage?storageKey=/users/u17017
```
The Storage system replies with the posted object. The only change
is that extra whitespace removed from the JSON.

Update the object:
```
curl -s http://localhost:8888/storage -d '
{
    "storageKey": "/users/u17017",
    "generation": 2,
    "Name": "Marge Simpson"
}
```
Delete the object:
```
curl -X DELETE -s http://localhost:8888/storage?storageKey=/users/u17017
```

## Collections

Why do storage keys use a pathname-like abstraction? To support
grouped collections of objects. If you specify the query parameter
`.collection=true`, then instead of returning the single resource with
the specified storageKey, the system will return all resources with
keys that are a a single name "in" the given storageKey.

(From a filesystem perspective, it will return the files in the given
directory, but not subdirectories.)

The data is returned as a single JSON object with a field named
"items" which is a JSON array of the found objects.  This is intended
to be used with relatively small resources.  For example, it makes
sense to read a collection of resources where each resource represents
a book by title, author, etc., but without the book contents. Each
book resource could reference a large bookContents resource, so after
the books have been selected, the contents could be accessed
individually.

### Example

First, post a couple of objects:
```
{"storageKey":"/books/book01", "generation":1,
 "title":"Harry Potter", "author":"Rowling"}

{"storageKey":"/books/book02", "generation":1,
 "title":"Thrones, A Game of", "author":"Martin"}
```
Then read the collection:
```
curl -s 'http://localhost:8888/storage?storageKey=/books&.collection=true'
```
The reply is:
```
{"items":[
  {"storageKey":"/books/book01", "generation":1,
   "title":"Harry Potter", "author":"Rowling"},
  {"storageKey":"/books/book02", "generation":1,
   "title":"Thrones, A Game of", "author":"Martin"}
]}
```

### Filtering

In addition to the `storageKey` and `.collection` query parameters,
you can include any number of `key=value` query parameters. These
filter the objects included in the response. The response only
contains objects that match all of the key/value pairs. Of course, the
key must match a field name in the object (case-sensitive), and the
value must match the field's value, which must be scalar data --
string, integer, boolean, or null. (You cannot filter on arrays or
sub-objects.)

### Example

Search for books with a particular author:
```
curl -s 'http://localhost:8888/storage?storageKey=/books&.collection=true&author=Rowling'
```
The reply is:
```
{"items":[
  {"storageKey":"/books/book01", "generation":1,
   "title":"Harry Potter", "author":"Rowling"}
]}
```

## Replication and Fault Tolerance

The Storage service can be configured to run on one, two, or three nodes.

### One Node

When run on one node, obviously, there is no fault tolerance. If the
one node is down, then the service is unavailable.

### Two Nodes

When run on two nodes, the nodes run as peers (as opposed to a
master/slave relationship). Either node can be used to read and/or
write any object. Whenever an object is created, updated, or deleted
on either node, it uses a background thread to send the new object
state to its peer node.

What if one of the two nodes dies? In this case, the live node can
still be used to read and write any object. The live node keeps a list
of which objects still need to be replicated. Whenever an attempt to
replicate an object fails, the object remains in the list. The live
node will re-try as often as necessary and appropriate. Eventually,
the dead node will be repaired, and the live node will successfully
transfer all modified objects. This is known as Eventual Consistency.

What if a node dies while it has a non-empty queue of objects that
still need to be replicated? For this case, the Storage system keeps a
journal of everything that it does. When it creates, modifies, or
deletes an object locally, it adds a line to the journal. And when it
successfully replicates an object to its peer, it adds a line to the
journal.

Whem the storage system restarts, it compacts its journal. It matches
each line of "modified object X" with the corresponding "replicated
object X", and it drops those journal entries. The remaining entries
are "modified" without a corresponding "replicated". These lines form
the initial queue of objects to replicate.

**Conflict detection and resolution.** The problem with eventual
consistency is that it allows conflicts. Since each node accepts local
changes before it communicates with the other node, the state of any
object can diverge across the nodes. Given some storageKey at some
generation, node #1 can accept a post with `"color":"green"` while
node #2 can accept a post with `"color":"red"`. In this case, what is
the "correct" state of the object? They are equally valid. The object
is green and the object is red, depending on which node you use.

Since the nodes eventually tell each other everything that they have
done, the conflict will be detected. Each node will know: "At this
generation, my value is different from my node's value." The nodes can
record the conflict as appropriate. However, the conflict cannot be
automatically resolved. The system cannot decide which value is more
correct. So the object will remain in conflict until the conflict is
resolved by a higher-level service, or manually.

The easiest way to resolve the conflict is to simply post the next
generation of the object to one of the nodes. The node will send the
updated object to its peer, and the peer node will accept the update,
because the new generation number is available on the peer. This
works, but it's a bit worrisome. The data on the peer node is simply
discarded. There is no way to know whether that data was considered as
a factor in the new generation of the object.

### Three Nodes

When run on three nodes, the nodes run as peers. Any node can be used
to read and/or write any object. However, the nodes communicate among
themselves to service every single read and write request. No single
node ever acts independently.

The nodes use a "Paxos" like algorithm. It's a "two-phase voting
algorithm". Basically, to write an object, the nodes all vote on "can
we accept this object at this generation?" And to read an object, the
nodes all vote on "what is the current generation of this object?"

This provides "single-copy consistency". Conflicts are impossible.
Every object always has a single well-defined state.

The system is fault-tolerant. Any one of the three nodes can die. The
remaining two nodes can continue reading and writing objects among
themselves, since a successful vote only requires a majority -- two
out of three nodes is sufficient. So the system continues running
while the third node is repaired.

The problem with voting algorithms, of course, is that they are
slow. There is network latency added to every single read and write
request.

### Replication Conclusion

If you require speed over consistency, then run on two nodes.

If you require consistency over speed, then run on three nodes.

## Scalability

This is a microservice. It's a building block. So it is not scalable,
but it can serve as the basis for a scalable object store. One could
build a service that does sharding or consistent hashing across many
storage services, where each individual storage service is a pod of
two or three nodes.
