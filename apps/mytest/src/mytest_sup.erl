-module(mytest_sup).
-behaviour(supervisor).

-export([start_link/0]).
-export([init/1]).

start_link() ->
	supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init([]) ->
	Procs = [],
	{ok, {{one_for_one, 1, 5}, Procs}}.


mongodb() ->
 erlang:spawn_link(test_db,mongo_connect,[]),
 receive
   {'EXIT',_,_} ->
          mongodb();
    stopped ->
          mongodb
 end.

