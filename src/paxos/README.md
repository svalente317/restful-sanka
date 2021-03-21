Paxos-Based Storage Design
==========================

## Goal

Create a service that allows a user to save a piece of data, and then
allows a user to retrieve the saved data.

## Design #1

Run a single server that supports read and write requests.

**Problem:** Low availability. If the server dies, then users can neither
read nor write data until the server has been repaired.

## Design #2

Run two servers and save the data on each of them, so that if one
server dies, then users can read data from the other one.

**Problem:** Low write availability. This solution requires both servers
to be up in order to save data. If either server is down, then users
can only read data.

## Design #3

Voting. Run an odd number of servers, at least three. To save a piece
of data, send write requests to all servers in parallel. If a majority
of the servers accept the write request, then the data is saved.
Otherwise, we have failed to save the data. To read a piece of data,
send read requests to all servers in parallel. If a majority of
servers reply with the same piece of data, then that is the data.
Otherwise, we have failed to read the data.

This design has high availability. Say that we have three servers. In
this case, any one server can die, and users can continue both reading
and writing data. This gives an administrator time to repair the dead
server. (If we have five servers, then any two servers can die. And so
on.)

**Problem:** Concurrency. Say that there are three servers and multiple
clients. Say that three clients all try to save different data at the
same time. One client writes "A" to all three servers, one writes "B",
and one writes "C". Each client receives three successful responses,
so each client believes that the data has been saved. But what is the
final state of the system? It's possible that one server's final state
is "A", and one is "B", and one is "C". The problem is that clients
may overwrite data that they never knew existed, and that the system
may end up in an unreadable state.

## Design #4

Two-phase voting (Paxos). A client saves data in two phases. In phase
1, the client chooses a unique id N, and sends a Prepare request to
each server. This request asks the server to reject all Write requests
with ids less than N. If a majority of the requests are accepted, then
the client proceeds to phase 2. In phase 2, the client sends a Write
request to each server. This request contains N and the data to
save. If a majority of the requests are accepted, then the data is
saved.

This design does not suffer from concurrency problems. For example,
say that there are three servers. Say that some client tries to save
the value "A" with a low uid, while some othe client tries to save the
value "B" with a high uid. There are two possibilities:

1. On a majority of the servers, the high Prepare request is processed
before the low Write request. On these servers, the low Write request
is rejected. So only the value "B" is saved.

2. On a majority of the servers, the low Write request is processed
before the high Prepare request. On these servers, the low Write
request is accepted, so the value "A" is saved. Then, the high Prepare
request is also accepted. From these servers, the client receives a
reply which indicates that the request was accepted, and that the
value "A" has already been saved. The client counts the instances of
"A", and it sees that "A" is a majority. So, to avoid illegally
overwriting saved data, the client skips phase 2.

Paxos meets our original goal. It allows data to be saved and
retrieved. It provides high availability and concurrency with
single-copy consistency. So let's expand the goal.

## Goal #2

Create an application that allows a user to save *and update* a piece
of data. The system must be able to process a request of the form: "If
the value is currently X then update the value to Y, else reject this
request." If two clients simultaneously update the same piece of data,
then one client will win the race and his update will be accepted, and
the other client will lose the race and be told that the value is no
longer X.

## Design #5

Paxos with generations. Make a simple change to the server-side of the
algorithm: In each Prepare and Write request, include a generation
number G. This integer is treated as the high bits of the N. In other
words, a Prepare request asks the server to reject all Write requests
where the generation number is less than G, or where the generation
number is equal to G and the id is less than N.  When a client wants
to save new data (as opposed to updating existing data), it runs the
Paxos write algorithm with a generation of 1.

When a client wants to update existing data, it runs the Paxos read
algorithm to get the current data and generation G. Then it runs the
write algorithm with a generation of G+1.

Say that a client sends a set of Prepare requests with generation G
and id N. Say that a majority of those requests are accepted with
replies that indicate that the current data is generation G and some
id smaller than N. In this case, the client aborts, as if the Prepare
requests had been rejected. This is to ensure that we do not commit
two different values with the same generation. So we do not overwrite
committed data that we did not intend to overwrite.

**Problem:** Lower availability then basic Paxos. There are some
circumstances where the failure of a single server can prevent clients
from reading or writing data.

Reading: Say that there are three servers, and one of them dies. In
this case, clients can continue to update data by writing to the two
remaining servers. However, whenever a value is updated, there is a
brief time period where one of the servers is at generation N and one
of them is at generation N+1. During this period, if a client tries to
read the data, then it will not find a majority. So on each update,
the data will seem to disappear at generation N, and then eventually,
it wiill reappear at generation N+1. Because of this problem, if a
client does not find a majority, then it should sleep a bit and then
try again.

Writing: Say that there are three servers, and one of them dies. Then,
to write data, a client sends Prepare requests with generation G. One
of the clients accepts the Prepare request and says that its current
generation is G-1. The other client also accepts the Prepare request,
and says that its current generation is G (with a low id). In this
case, the writing client does not know whether or not generation G has
already been committed. It depends on what had been written on the
third server before it died. So the rule is: If there's a chance that
generation G might have already been committed, then do not commit a
new generation G.
