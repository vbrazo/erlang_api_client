%%%----------------------------------------------------------------------------
%%% @author Vitor Oliveira <vbrazo@gmail.com>
%%% @doc
%%% API Erlang client - API Client
%%% @end
%%%----------------------------------------------------------------------------
-module(eac_server).

-behaviour(gen_server).

-include("eac.hrl").

%% API
-export([start_link/0, start_link/1, call_api/1, set_api_key/1, set_http_options/1,
         get_http_options/0]).

%% gen_server callbacks
-export([init/1, terminate/2, handle_call/3, handle_cast/2, handle_info/2,
         code_change/3]).

%% for testing only
-ifdef(TEST).

-export([get_algo_path/2, get_content_type/1, build_uri/2, sanitize_query_params/1]).

-endif.

-define(SERV_NAME, ?MODULE).
-define(API_URL, <<"https://api.algorithmia.com/v1/algo">>).
-define(DEFAULT_HTTP_OPTIONS, [{pool, default}]).

-record(state, {api_key = <<>> :: binary(), http_opts = ?DEFAULT_HTTP_OPTIONS :: list()}).

%%%============================================================================
%%% API
%%%============================================================================
-spec set_api_key(binary()) -> ok | no_return().
set_api_key(ApiKey) ->
    gen_server:call(?SERV_NAME, {set_api_key, ApiKey}).

-spec set_http_options(list()) -> ok | no_return().
set_http_options(Options) ->
    gen_server:call(?SERV_NAME, {set_http_options, Options}).

-spec get_http_options() -> list() | no_return().
get_http_options() ->
    gen_server:call(?SERV_NAME, get_http_options).

-spec call_api(map()) -> eac:response().
call_api(Args) ->
    gen_server:call(?SERV_NAME, {call_api, Args}).

-spec start_link() -> ignore | {error, term()} | {ok, pid()}.
start_link() ->
    gen_server:start_link({local, ?SERV_NAME}, ?MODULE, [], []).

-spec start_link(binary()) -> ignore | {error, term()} | {ok, pid()}.
start_link(ApiKey) ->
    gen_server:start_link({local, ?SERV_NAME}, ?MODULE, [ApiKey], []).

%%%============================================================================
%%% gen_server callbacks
%%%============================================================================
%% @private
-spec init([] | [binary()]) -> {ok, #state{}}.
init([]) ->
    {ok, #state{}};
init([ApiKey]) ->
    {ok, #state{api_key = ApiKey}}.

%% @private
-spec terminate(normal, #state{}) -> ok.
terminate(normal, _State) ->
    ok.

%% @private
-spec handle_call(term(), {pid(), term()}, #state{}) ->
                     {reply, ok, #state{}} |
                     {reply, {ok, term()}, #state{}} |
                     {reply, {error, term()}, #state{}} |
                     {reply, invalid_call, #state{}}.
handle_call({set_api_key, ApiKey}, _From, State) ->
    error_logger:info_msg("set_api_key - ~p~n", [ApiKey]),
    {reply, ok, State#state{api_key = ApiKey}};
handle_call({set_http_options, Options}, _From, State) ->
    error_logger:info_msg("set_http_options - ~p~n", [Options]),
    {reply, ok, State#state{http_opts = Options}};
handle_call(get_http_options, _From, #state{http_opts = Options} = State) ->
    error_logger:info_msg("get_http_options - ~p~n", [Options]),
    {reply, Options, State};
handle_call({call_api, Args},
            _From,
            #state{api_key = ApiKey, http_opts = HTTPOptions} = State) ->
    Input = maps:get(<<"input">>, Args, <<>>),
    InputType = maps:get(<<"type">>, Args, json),
    Query = maps:get(<<"options">>, Args, #{}),
    UriPath =
        get_algo_path(maps:get(<<"algo">>, Args), maps:get(<<"version">>, Args, undefined)),
    Uri = build_uri(UriPath, Query),
    {reply, run(ApiKey, InputType, Uri, Input, HTTPOptions), State};
handle_call(_Call, _From, State) ->
    {reply, invalid_call, State}.

%% @private
-spec handle_cast(term(), #state{}) -> {noreply, #state{}}.
handle_cast(_Cast, State) ->
    {noreply, State}.

%% @private
-spec handle_info(term(), #state{}) -> {noreply, #state{}}.
handle_info(_Info, State) ->
    {noreply, State}.

%% @private
-spec code_change(term(), #state{}, term()) -> {ok, #state{}}.
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%============================================================================
%%% Internal functions
%%%============================================================================
get_algo_path(AlgoName, undefined) ->
    AlgoName;
get_algo_path(AlgoName, Version) ->
    <<AlgoName/binary, $/, Version/binary>>.

run(ApiKey, InputType, Uri, Body, Options) ->
    Headers = get_request_headers(ApiKey, InputType),
    error_logger:info_msg("[API] URI=~s~n", [Uri]),
    http_request(Uri, Headers, post, Body, Options).

http_request(Uri, Headers, Method, Body, Options) ->
    case hackney:request(Method, Uri, Headers, Body, Options) of
        {ok, 200, RespHeaders, ClientRef} ->
            handle_response(ClientRef);
        {ok, 201, _RespHeaders, ClientRef} ->
            handle_response(ClientRef);
        {ok, 204, _RespHeaders, ClientRef} ->
            handle_response(ClientRef);
        {ok, 302, RespHeaders, _ClientRef} ->
            RedirectUrl = proplists:get_value(<<"Location">>, RespHeaders),
            http_request(RedirectUrl, Headers, Method, Body, Options);
        {ok, Status, RespHeaders, ClientRef} ->
            {error, Reason1} = Error = handle_response(ClientRef),
            error_logger:warning_msg("[API] Error:~nUri: ~s~nnReason: ~p~n",
                                     [Uri, {Status, RespHeaders, Reason1}]),
            Error;
        {error, Reason} ->
            error_logger:warning_msg("[API] Error:~nUri: ~s~nReason: ~p~n",
                                     [Uri, Reason]),
            {error, Reason}
    end.

get_content_type(text) ->
    <<"application/text">>;
get_content_type(json) ->
    <<"application/json">>;
get_content_type(binary) ->
    <<"application/octet-stream">>.

build_uri(Part, Options) ->
    case maps:size(Options) > 0 of
        true ->
            Options1 = sanitize_query_params(Options),
            <<?API_URL/binary, $/, ?io2b(Part)/binary, $?, (build_qs(Options1))/binary>>;
        false ->
            <<?API_URL/binary, $/, ?io2b(Part)/binary>>
    end.

get_request_headers(ApiKey, InputType) ->
    [{<<"Authorization">>, <<"Simple ", ApiKey/binary>>},
     {<<"Content-Type">>, get_content_type(InputType)}].

handle_response(ClientRef) ->
    {ok, Body} = hackney:body(ClientRef),
    Map = jiffy:decode(Body, [return_maps]),
    case maps:is_key(<<"error">>, Map) of
        true ->
            {error, maps:get(<<"message">>, maps:get(<<"error">>, Map))};
        false ->
            {ok, Map}
    end.

build_qs(Args) ->
    QS = maps:fold(fun(K, V, Acc) -> <<Acc/binary, K/binary, $=, (to_bin(V))/binary, $&>> end,
                   <<>>,
                   Args),
    binary:part(QS, {0, byte_size(QS) - 1}).

sanitize_query_params(Map) ->
    maps:fold(fun(K, V, Acc) ->
                 case sanitize_query_param(K, V) of
                     true ->
                         maps:put(K, V, Acc);
                     false ->
                         Acc
                 end
              end,
              #{},
              Map).

sanitize_query_param(<<"stdout">>, true) ->
    true;
sanitize_query_param(<<"timeout">>, V) when is_integer(V) ->
    true;
sanitize_query_param(<<"output">>, V) when V =:= raw; V =:= void ->
    true;
sanitize_query_param(K, V) ->
    error_logger:warning_msg("[API] Invalid Query Param - ~s/~p~n", [K, V]),
    false.

to_bin(L) when is_list(L) ->
    ?l2b(L);
to_bin(N) when is_integer(N) ->
    ?i2b(N);
to_bin(A) when is_atom(A) ->
    ?a2b(A);
to_bin(B) ->
    B.
