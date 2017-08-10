-module(mytest_app).
-behaviour(application).

-export([start/2]).
-export([stop/1]).

start(_Type, _Args) ->
 {ok,Pid} =  mytest_sup:start_link(),
   Dispatch = cowboy_router:compile([
        {'_',
         [
          {"/get/", test_handler,[get]},
          {"/create/", test_handler, [create]},
          {"/book/", test_handler, [book]},
          {"/help", test_handler, [ help]},
          {"/", test_handler, [help]}
         ]}
                                     ]), 
    cowboy:start_clear(mytest_http_listener,[{port,9990}],#{env => #{dispatch => Dispatch}}),
    {ok,Pid}.

stop(_State) ->
	ok.
