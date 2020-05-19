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

