REST IMPLEMENTATION
=====
Movie Ticket Booking system

In building this application, I have used below list of libraries.
--------------------------------------------
1. Cowboy Framework
2. Jiffy (JSON Parser)
3. Mongodb (standard erlang mongodb driver)
4. rebar3 build tool
--------------------------------------------

The application was build on top of erlang OTP 18.2.1 vers

Description:
------------
------------
This implemntation is to book movie tickets by consuming REST services. The below 3 implementations are.

NOTE: From Mongodb I haven't used any worker pool(Limited to only 1 connection). Currently just consuming one connection. Buy in the order of maintaining the connectivity, when ever a restful resource gets called,and interacts with database the connectivity is checked. If the connecting process is dead,we will establish connection with mongodb.

----------------------------------------------------------------------------------------------------------------

Application deployment & testing:

Unit-testing is performed to cover and check that necessary out puts are coming.

To deploy the node clone the repositoty to your machine using below
git clone https://github.com/RAMAABHI/mytest.git

run rebar3 executiable. NOTE:Incase if this executiable doesn't support please generate a new rebar3 from

steps of installation
 rebar3 compile
 rebar3 release
 
to login to shell 

_build/default/rel/<node_name>/bin/<node_name> console

alternativily do

rebar3 shell

-----------------------------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------------------------------------
1. To Insert movie details into db below command is used

sudo curl -v --data "{\"imdbid\": \"323344hhf4\", \"screen\": \"lx3456766\", \"seats\": \"100\", \"movieTitle\": \"Nethrlands\"}" \ --header "Content-Type: application/json" \ http://127.0.0.1:9990/create

If the movie already exits this will through an error and wont add the information:
------------------------------------------------------------------------------------------------------------------------
Success
$ curl     -v     --data "{\"imdbid\": \"xsbg3444\", \"screenid\": \"555kkcmcm1\", \"availableSeats\" : 100 , \"movieTitle\": \"movies details\"}"\     --header "Content-Type: application/json"     http://127.0.0.1:9990/create
* About to connect() to 127.0.0.1 port 9990 (#0)
*   Trying 127.0.0.1...
* Connected to 127.0.0.1 (127.0.0.1) port 9990 (#0)
> POST /create HTTP/1.1
> User-Agent: curl/7.29.0
> Host: 127.0.0.1:9990
> Accept: */*
> Content-Type: application/json
> Content-Length: 106
> 
* upload completely sent off: 106 out of 106 bytes
< HTTP/1.1 200 OK
< content-length: 39
< content-type: application/json
< date: Thu, 10 Aug 2017 21:20:23 GMT
< server: Cowboy
< 
Succesfully updated the record into db
---------------------------------------------
$ curl \
     -v \
     --data "{\"imdbid\": \"xsbg3444\", \"screenid\": \"555kkcmcm1\"}" \
     --header "Content-Type: application/json" \
     http://127.0.0.1:9990/create
* About to connect() to 127.0.0.1 port 9990 (#0)
*   Trying 127.0.0.1...
* Connected to 127.0.0.1 (127.0.0.1) port 9990 (#0)
> POST /create HTTP/1.1
> User-Agent: curl/7.29.0
> Host: 127.0.0.1:9990
> Accept: */*
> Content-Type: application/json
> Content-Length: 48
> 
* upload completely sent off: 48 out of 48 bytes
< HTTP/1.1 204 No Content
< content-length: 0
< content-type: application/json
< date: Thu, 10 Aug 2017 21:13:08 GMT
< server: Cowboy
< 
* Connection #0 to host 127.0.0.1 left intact
[abhilash@localhost ~]$ 
This basically comes both of when the content is not available. This is being thrown by cowboy web server. If we wanted to through a specifc error, we can use 
   cowboy_req:reply(Number,RequestData).
This above command will through an requested http code to shell.
------------------------------------------------------------------------------------------------



2. MOVIE Seat Booking
-------------------
-------------------
Success Scenarios
curl     -v     --data "{\"imdbid\": \"xsbg3444\", \"screenid\": \"555kkcmcm1\", \"availableSeats\" : 100 }"\     --header "Content-Type: application/json"     http://127.0.0.1:9990/book
* About to connect() to 127.0.0.1 port 9990 (#0)
*   Trying 127.0.0.1...
* Connected to 127.0.0.1 (127.0.0.1) port 9990 (#0)
> POST /book HTTP/1.1
> User-Agent: curl/7.29.0
> Host: 127.0.0.1:9990
> Accept: */*
> Content-Type: application/json
> Content-Length: 74
> 
* upload completely sent off: 74 out of 74 bytes
< HTTP/1.1 200 OK
< content-length: 74
< content-type: application/json
< date: Thu, 10 Aug 2017 21:24:23 GMT
< server: Cowboy
< 
* Connection #0 to host 127.0.0.1 left intact
Succesfully booked the ticket for imdbid:"xsbg3444" screen_id:"555kkcmcm1" 

> db.getCollection("movies").find()
{ "_id" : ObjectId("598cce17421aa9157a000001"), "availableSeats" : 99, "imdbid" : "xsbg3444", "movieTitle" : "movies details", "reservedSeats" : 1, "screenid" : "555kkcmcm1" }
> 

> db.getCollection("movies").find()
{ "_id" : ObjectId("598cce17421aa9157a000001"), "availableSeats" : 98, "imdbid" : "xsbg3444", "movieTitle" : "movies details", "reservedSeats" : 2, "screenid" : "555kkcmcm1" }

----------------------------------------------------------------------------------------------------------------------------------------------

3. Viewing the Status of the tickets (GET operations) ->


Failure case

* About to connect() to 127.0.0.1 port 9990 (#0)
*   Trying 127.0.0.1...
* Connected to 127.0.0.1 (127.0.0.1) port 9990 (#0)
> GET /get/?imdbid=3233d344rr4r HTTP/1.1
> User-Agent: curl/7.29.0
> Host: 127.0.0.1:9990
> Accept: */*
> 
< HTTP/1.1 204 No Content
< 
* Connection #0 to host 127.0.0.1 left intact


------------------------------------------------------------------------
curl -v http://127.0.0.1:9990/get/?"imdbid=xsbg3444&screenid=555kkcmcm1"
--------------------------------------------------------------------------
* About to connect() to 127.0.0.1 port 9990 (#0)
*   Trying 127.0.0.1...
* Connected to 127.0.0.1 (127.0.0.1) port 9990 (#0)
> GET /get/?imdbid=xsbg3444&screenid=555kkcmcm1 HTTP/1.1
> User-Agent: curl/7.29.0
> Host: 127.0.0.1:9990
> Accept: */*
> 
< HTTP/1.1 200 OK
< content-length: 135
< content-type: application/json
< date: Thu, 10 Aug 2017 21:36:05 GMT
< server: Cowboy
< 
* Connection #0 to host 127.0.0.1 left intact
<<"{\"screenid\":\"555kkcmcm1\",\"reservedSeats\":2,\"movieTitle\":\"movies details\",\"imdbid\":\"xsbg3444\",\"availableSeats\":98}">> 

__________________________________________________________________________________________________________________________________________












