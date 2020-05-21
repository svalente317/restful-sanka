Restful Sanka
=============

svalente@mit.edu

## Overview

Restful Sanka is a server and infrastructure for implementing
microservices in the [Sanka](https://github.com/svalente317/sanka)
programming language.

The infrastructure uses HTTP. It encourages the use of RESTful named
resources, and it encourages the use of JSON message bodies, although
ultimately you have full control over the naming scheme and API.

Each microservice is implemented in a "RestWorker". A RestWorker is
a Sanka class that implements methods for the HTTP verbs: `onGet()`,
`onPost()`, etc.

When the server starts, it creates instances of all of the RestWorker
classes, and it registers them in the REST namespace. Then, the server
accepts HTTP requests, and it routes the requests to the workers.

### Simple Example

The most simple RestWorker is "EchoWorker". Notice that the Restful
Sanka `main` function creates and registers an instance of EchoWorker:
```
    processor.register(EchoWorker.WORKER_PATH, new EchoWorker());
```

EchoWorker implements a stateful microservice. It maintains its state
as an instance variable. This works because there is one single
instance of EchoWorker in memory. It was created and registered by the
`main` function, and it handles _all_ requests to `/echo`, even when
multiple GET and POST requests are running in multiple threads in
parallel.

EchoWorker's state is simply the "content" field of the JSON message
that was most recently posted to it. Effectively, it echoes "content"
back to you. It also maintains a "generation" field which indicates
how many times it has been updated.

Here is an example using the `curl` command to send requests to
EchoWorker. (Of course, you can use your favorite REST client. This
example assumes that the service is listening on port 8888, which is
the default.)

First, POST content:
```
curl -s http://localhost:8888/echo -d '{"content": "Hello, World"}'
```
Then, GET the content:
```
curl -s http://localhost:8888/echo | json_reformat
{
    "content": "Hello, World",
    "generation": 1
}
```
Then, POST new content:
```
curl -s http://localhost:8888/echo -d '{"content": "Goodbye, Cruel World"}'
```
Finally, GET the updated content:
```
curl -s http://localhost:8888/echo | json_reformat
{
    "content": "Goodbye, Cruel World",
    "generation": 2
}
```
The simple source code for this simple microservice is in
[src/examples/EchoWorker.san](src/examples/EchoWorker.san).

### Complex Example

Restful Sanka makes it easy to build microservices on top of other
microservices. The most simple example is
[ReverseWorker](src/examples/ReverseWorker.san).
ReverseWorker gets the current state of the EchoWorker, and it reverses
the "content" field. For example:
```
curl -s http://localhost:8888/reverse | json_reformat 
{
    "content": "dlroW ,olleH",
    "generation": 1
}
```
ReverseWorker is a client of EchoWorker's public API. It does not
break abstraction barriers. It does not examine variables or memory
that are owned by EchoWorker. It does not know if EchoWorker stores
the content in memory or on disk or in a database. In a sense,
ReverseWorker does not even know if EchoWorker is running in-process,
or in a separate process, or across the network.

Look at `ReverseWorker.onGet()`. It uses the two pieces of the public
API defined by EchoWorker:

1. Send the request to EchoWorker.WORKER_PATH.
2. Interprets the body of the response as `EchoWorkerState`.

That's it. A RestWorker simply defines (1) a WORKER_PATH and (2) a
"WorkerState" serializable class for POST requests and GET
responses. That fully defines the worker's API, so that the
microservice can be used by other microservices.

ReverseWorker uses the RestWorker method `send()` to send the request
and get the response. `send()` is intelligent: It knows that "/echo"
is registered in-process, so it "sends" the request by making an
efficient function call to `EchoWorker.onGet()`.

In theory, if "/echo" had been registered out-of-process, then send()
would make the appropriate http call to the registered host and
port. (Note that this is not implemented yet.)

## Resource Collections

Restful Sanka provides infrastructure to create collections of
resources. To create a collection, define the resource as a Plain Old
Digital Object (PODO) -- a list of serializable fields. For example,
here is a resource definition for a collection of users:
```
serializable class UserState {
    String username;
    String password;
    String fullName;
}
```
Define one of the fields as the primary key. For example, for our
collection of users, we define "username" as the primary key.

Then, create a RestWorker that extends `CollectionWorker`. For example,
see [src/examples/UsersWorker.san](src/examples/UsersWorker.san).

CollectionWorker supports these operations:
* Add a resource: POST to the collection
* Update a resource: POST to a resource in the collection by its primary key
* Delete a resource: DELETE to a resource in the collection by its primary key
* Get the whole collection: GET to the collection
* Get a resource: GET to a resource in the collection by its primary key

For example, create a new user:
```
curl -s http://localhost:8888/users -d '{"username":"bob", "fullName":"Bob Hacker"}'
```
Then, GET the collection:
```
curl -s http://localhost:8888/users | json_reformat
{
    "items": [
        {
            "username": "bob",
            "fullName": "Bob Hacker",
            "generation": 1
        }
    ]
}
```
Or get just the resource with the primary key "bob":
```
curl -s http://localhost:8888/users/bob | json_reformat
{
    "username": "bob",
    "fullName": "Bob Hacker",
    "generation": 1
}
```
Then update the existing resource:
```
curl -s http://localhost:8888/users/bob -d '{"fullName":"Bob Q. Hacker"}'
```
And get the updated resource:
```
curl -s http://localhost:8888/users/bob | json_reformat
{
    "username": "bob",
    "fullName": "Bob Q. Hacker",
    "generation": 2
}
```
Finally, delete the resource:
```
curl -s -X DELETE http://localhost:8888/users/bob
```
Of course, Restful Sanka is not intended to be used as a simple data
store. There are infinitely better options for data storage. Restful
Sanka is intended to be used for _services_. The power of using a
RestWorker to manage a collection of resources is that you can
implement services: Your worker can execute custom code whenever a
resource is added, updated, and deleted.

Here are some notes about CollectionWorker, in no particular order.

* It stores the resources in the filesystem, one file per resource.
  While restful-sanka is in development, the default resource storage
  location is in /tmp.

* The field names "storageKey" and "generation" are reserved for use by
  the system. Other then those names, you can define your resource with any
  fields that are serializable -- scalar data, serializable sub-objects, and
  arrays -- and you can use any valid Sanka field names.

* Your primary key field should be a String or an int or long.

* When you post a new resource, if the message body is not valid JSON, or
  if the primary key is empty or missing, or if the primary key is in use,
  then the operation fails.

* When you update a resource, you do not need to include the primary
  key in the message body. A resource's primary key can never change.

* Race conditions: Say that a resource is currently at generation 1,
  and two clients simultaneously send updates to this
  resource. CollectionWorker serializes these updates. One of them is
  saved as generation 2, and the other is saved as generation 3. In
  many cases, this is not ideal. The latter of these clients
  accidentally overwrites data that it never saw. If it had seen
  generation 2, then maybe it would have done something different. So
  CollectionWorker provides a way to request an atomic update: Specify
  the "generation" field in the message body. For example, say that two
  clients have both seen generation 1, and they simultaneously send
  updates, and they both specify "generation 2". One of these updates
  is saved as generation 2. The other fails: "Generation not available."

## Services

In addition to a basic infrastructure, Restful Sanka comes with two
packages of services:

* [Storage](src/storage). This is the service that reads and writes
  resources to disk. The Collection Worker infrastructure uses this
  service.

* [Notebook](src/notebook). This is a small set of workers that can be
  used to manage a collection of "notebooks", where a notebook is an
  ordered series of individual documents. It's a very simple service,
  but it's an example of the kind of things that Restful Sanka can do.
