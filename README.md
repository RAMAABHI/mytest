REST IMPLEMENTATION
=====
Movie Ticket Booking system

In building this application, I have used below list of libraries.
--------------------------------------------
1. Cowboy Framework
2. Jiffy (JSON Parser)
3. Mongodb (standard erlang mongodb driver)
--------------------------------------------

The application was build on top of erlang OTP 18.2.1 vers

Description:
------------
------------
This implemntation is to book movie tickets by consuming REST services. The below 3 implementations are.

NOTE: From Mongodb I haven't used any worker pool(Limited to only 1 connection). Currently just consuming one connection. Buy in the order of maintaining the connectivity, when ever a restful resource gets called,and interacts with database the connectivity is checked. If the connecting process is dead,we will establish connection with mongodb.

----------------------------------------------------------------------------------------------------------------

Application deployment
