-module(test_handler).
-compile([export_all]).

-record(state, {op}).

init(Req,Opts) ->
  [Op | _] = Opts,
  State = #state{op=Op},
  application:set_env(cowboy,request,Req),
  {cowboy_rest,Req,State}.

allowed_methods(Req,State) -> %% 405 method not allowed
 {[<<"GET">>,<<"POST">>],Req,State}.

allow_missing_post(Req,State) ->
  {true,Req,State}.

content_types_provided(Req,State) ->
  Content = [
      {<<"application/json">>, db_to_json}
      ], 
  {Content,Req,State}.

content_types_accepted(Req, State) ->
   Value = [{<<"application/json">>, json_to_db}], 
   {Value, Req, State}.

db_to_json(Req,#state{op = Op}=State) ->
 {Body, Req1, State1} =
   case Op of
        get ->
            get_one_record(Req, State);
        help ->
            get_help(Req, State);
        _ -> {stop,Req,State}
  end,
  {Body, Req1, State1}. 

json_to_db(Req, #state{op=Op} = State) ->
    {Body, Req1, State1} = 
    case Op of
        create ->
            create_record_to_json(Req, State);
        book ->
            update_record_to_json(Req, State)
    end,
{Body, Req1, State1}. 


delete_completed(Req,State) -> {true,Req,State} .

delete_resource(Req,State) -> 
 ImdbId = cowboy_req:binding(imdbid, Req),
 Response = 
 case test_db:delete_movie(ImdbId) of 
     success ->
         true;
     _ ->
         false
 end,
 {Response, Req, State}. 

malformed_request(Req,State) -> %% if true return 400 bad request
{false,Req,State}.

resource_exist(Req,State) ->
  case cowboy_req:method(Req) of
      <<"DELETE">> ->
         ImdbID = cowboy_req:binding(imdbid, Req),
         case test_db:get_movies(ImdbID) of 
             success ->
                {true, Req, State};
             failure ->
                {stop, Req, State};
              database_down ->
                 {halt(), Req, State}
         end;           
       _ ->
            {false, Req, State}
end.

previosuly_exist(Req,State) ->
 {true,Req,State}.

uri_too_long(Req,State) -> {false,Req,State}.  %%414 request uri too long


is_conflit(Req,State) -> {false,Req,State}.


get_help(Req, State) ->
    Body = "{
    \"/get\" : \"retrieve a record by its ID\",
    \"/create\": \"create a new record; return its ID\",
    \"/book\": \"update an existing record\",
}",
   {Body, Req, State}.



get_one_record(Req, State) ->
    QueryString = cowboy_req:qs(Req),
    PropList = httpd:parse_query(binary_to_list(QueryString)),
    case lists:keysearch("imdbid",1,PropList) of
         false ->  {stop, Req, State};
         {value,{_,""}} -> {stop, Req, State};
         {value,{_,ImdbId}} ->
              case lists:keysearch("screenid",1,PropList) of
                   false -> {stop, Req, State};
                    {value,{_,""}} -> {stop, Req, State};
                   {value,{_,ScreenId}} ->
                      case test_db:get_movie(list_to_binary(ImdbId),list_to_binary(ScreenId)) of
                         Data when is_map(Data) ->
                             Data1 = maps:remove(<<"_id">>,Data),
                             Header  = maps:get(headers,Req),
                             Value = maps:merge(Header,#{<<"content-type">> => <<"application/json">>}),

                             Req1 = maps:update(headers,Value,Req),
                             ResponseValue = jiffy:encode(Data1),
                             ResponseValue1= io_lib:format("~p",[ResponseValue]),
                             cowboy_req:set_resp_body(ResponseValue1, Req1),
                             { ResponseValue1, Req1, State};
                         Error ->
                             cowboy_req:reply(404,Req),
                             { erlang:atom_to_list(Error),Req,State}
                     end
              end
    end.

    
         
         

create_record_to_json(Req, State) ->
    {ok, [{Content,_}],Req1} = cowboy_req:read_urlencoded_body(Req),
    case catch jiffy:decode(Content,[return_maps]) of
         {'EXIT',_} -> 
              {stop,Req1,State};
         MapData ->
             Response  = test_db:create_tickets(MapData),
             case Response of
                 success ->
                      ImdbIDValue= erlang:binary_to_list(maps:get(<<"imdbid">>,MapData)),
                      case cowboy_req:method(Req1) of
                           <<"POST">> ->
                                 Value = maps:update(<<"content-type">>,<<"text/plain">>,maps:get(headers,Req1)),
                                 Req2 = maps:update(headers,Value,Req1),
                                 Req3 = cowboy_req:set_resp_body(<<"Succesfully updated the record into db\n">>, Req2),
                                
                                 {true, Req3, State};
                            _ ->
                                {true,Req1,State}
                      end;
                 _ ->
                      {true,Req1,State}
             end
   end.

update_record_to_json(Req, State) ->
    case cowboy_req:method(Req) of
        <<"POST">> ->
            {ok, [{NewContent,_}],Req1} = cowboy_req:read_urlencoded_body(Req),
            case catch jiffy:decode(NewContent,[return_maps]) of
                 {'EXIT',_} -> 
                        {stop,Req1,State};
                 MapData ->
                      Response = test_db:update_booking_tickets(MapData),
                      ImdbIDValue= erlang:binary_to_list(maps:get(<<"imdbid">>,MapData)),
                      case cowboy_req:method(Req1) of
                           <<"POST">> ->
                                 ImdbID = binary_to_list(maps:get(<<"imdbid">>,MapData)),
                                 ScreenID = binary_to_list(maps:get(<<"screenid">>,MapData)),
                                 Value = maps:update(<<"content-type">>,<<"text/plain">>,maps:get(headers,Req1)),
                                 Req2 = maps:update(headers,Value,Req1),
                                 ResponseMsg=io_lib:format("Succesfully booked the ticket for imdbid:~p screen_id:~p",[ImdbID,ScreenID]),
                                 Req3 = cowboy_req:set_resp_body(list_to_binary(ResponseMsg), Req2),
                                 {true, Req3, State};
                            _ ->
                                {true,Req1,State}
                      end
            end;
                 _ ->
                       {false, Req, State}
    end.

post_is_create(RD, Ctx) ->
	{true, RD, Ctx}.


create_path(RD, Ctx) ->
	Path = "/get/",
	{Path, RD, Ctx}.


db_to_text(Req,#state{op=Op} = State) ->
   {Body, Req1, State1} =
   case Op of
        book ->
            get_one_record(Req, State);
        help ->
            get_help(Req, State)
  end,
  {Body, Req1, State1}. 
