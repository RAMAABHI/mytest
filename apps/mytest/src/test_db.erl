-module(test_db).
-compile([export_all]).

-define(COLLECTION,<<"movies">>).
-define(DATABASE,<<"test">>).

mongo_db_connection_identifier() ->
  case application:get_env(mongodb,connection) of
     {ok,Connection} ->
       case erlang:whereis(Connection) of
             Pid when erlang:is_pid(Pid) ->
                 ok;
             undefined -> 
                mongodb_connect()
         end;       
     undefined ->
            mongodb_connect()
 end.


mongodb_connect() ->
 Database = <<"test">>,
 case mc_worker_api:connect([{database,?DATABASE}]) of
    {ok,Connection} ->
        case erlang:whereis(mongodb_pid)of
            Pid when erlang:is_pid(Pid) -> 
                exit(Pid,kill),
                application:set_env(mongodb,connection,undefined)
                ;
            undefined ->
                ok
        end,
        erlang:register(mongodb_pid,Connection),
        application:set_env(mongodb,connection,mongodb_pid);
    {error,Reason} ->
        application:set_env(mongodb,connection,undefined),
        io:format("DB Down"),
        ok
 end.


create_tickets(Request) ->
   mongo_db_connection_identifier(),
   case application:get_env(mongodb,connection) of
      {ok,Connection} ->
         Connection1 = erlang:whereis(Connection),
         case maps:size(Request) of
              4 ->
                case maps:get(<<"imdbid">>,Request) of
                    Value ->
                      
                       case validate_keys(Request) of
                           true ->
                               
                                 case mc_worker_api:find_one(Connection1,?COLLECTION,#{<<"imdbid">> => Value}) of
                                      undefined ->
                                           DefaultList = #{<<"reservedSeats">> => 0},
                                           FinalMapRequest= maps:merge(Request,DefaultList),
                                           case mc_worker_api:insert(Connection1,?COLLECTION,[FinalMapRequest]) of
                                                {{true,_},_} ->
                                                        success;
                                                {{false,_},_} -> 
                                                   failed
                                           end;
                                      Data when is_map(Data) ->
                                        record_already_exist
                                 end;
                           false ->  invalid_data
                       end;        
                   {badmap,_} ->  invalid_data
                end;
              _ -> invalid_data
          end;
       undefined -> 
           database_down
     end.
       
      

update_booking_tickets(Request) ->
 mongo_db_connection_identifier(),
 case application:get_env(mongodb,connection) of
     {ok,Connection} -> 
         case maps:size(Request) of
              2 ->
                case maps:get(<<"imdbid">>,Request) of
                     Value ->
                        case maps:get(<<"screenid">>,Request) of
                            Value1 ->
                                  case validate_keys(Request) of
                                      true ->  
                                          case mc_worker_api:find_one(Connection,?COLLECTION,#{<<"imdbid">> => Value, <<"screenid">> => Value1}) of 
                                               undefined ->
                                                      invalid_data;
                                               Data ->
                                                   Id = maps:get(<<"_id">>,Data),
                                                   ReservationSeats = maps:get(<<"reservedSeats">>,Data),
                                                   AvailableSeats = maps:get(<<"availableSeats">>,Data),
                                                   case AvailableSeats of 
                                                        0 ->
                                                            bookings_closed;
                                                        _ ->
                                                            FinalAvailableSeats = AvailableSeats -1,
                                                            FinalReservedSeats = ReservationSeats + 1,
                                                            FinalMapRequest =  maps:update(<<"reservedSeats">>,FinalReservedSeats,Data),
                                                            FinalMapRequest1 = maps:update(<<"availableSeats">>,FinalAvailableSeats,
                                                                               FinalMapRequest), 
                                                            case mc_worker_api:update(Connection, ?COLLECTION, #{<<"_id">> => Id},  
                                                                #{<<"$set">> => FinalMapRequest1})  of
                                                                {true,_} ->  {success,FinalMapRequest1};
                                                                {false,_} -> failure
                                                            end
                                                   end
                                           end;
                                     false -> invalid_data
                                 end; 
                           {badmap,_} -> invalid_data
                       end;                                           
                    {badmap,_} -> invalid_data
                end;
             _ ->  invalid_data
         end;
     undefined ->
         database_down
 end.

get_movie(ImdbId,ScreenId) ->
 mongo_db_connection_identifier(),
 case application:get_env(mongodb,connection) of
     {ok,Connection} ->           
         case mc_worker_api:find_one(Connection,?COLLECTION,#{<<"imdbid">> => ImdbId,<<"screenid">> => ScreenId}) of      
             undefined ->
                  no_entry_found;
             Data ->
                  Data
         end;
     undefined ->
         database_not_ready
 end.

get_movies_list() ->
   mongo_db_connection_identifier(),
   case application:get_env(mongodb,connection) of
       {ok,Connection} ->
          case mc_worker_api:find(Connection,?COLLECTION, #{}) of
             {ok,Cursor} ->
                List = get_total_movies(Cursor,[]);
             _ -> invalid_data
         end;
     undefined ->
        database_down
   end.
           

get_total_movies(Cursor,Acc) ->
   case mc_cursor:rest(Cursor) of
       error ->
              mc_cursor:close(Cursor),
              Acc;
       Data ->
             get_total_movies(Cursor,[Data|Acc])
  end.
                 
delete_movies(Request) ->
   mongo_db_connection_identifier(),
   case application:get_env(mongodb,connection) of
       {ok,Connection} ->
           case mc_worker_api:delete(Connection,?COLLECTION,#{<<"imdbid">> => Request}) of
               {true,_} ->success ;
               {false,_} -> failure 
           end;
        undefined ->
          database_down
   end.

validate_keys(Map) ->
   case maps:keys(Map) of
       List when is_list(List)->
          lists:all(fun(X) -> 
                          case lists:member(X,[<<"availableSeats">>,<<"imdbid">>,<<"screenid">>,<<"movieTitle">>]) of
                               true -> true;
                               false -> false
                          end end,List);
       _ -> false 
   end.
