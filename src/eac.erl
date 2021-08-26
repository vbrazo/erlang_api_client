%%%----------------------------------------------------------------------------
%%% @author Vitor Oliveira <vbrazo@gmail.com>
%%% @doc
%%% API Erlang client - OTP application API
%%% @end
%%%----------------------------------------------------------------------------
-module(eac).

-include("eac.hrl").

%% API
-export([start/0, stop/0, set_api_key/1, set_http_options/1, get_http_options/0, algo/2,
         algo/3, algo/4, algo/5]).

%% Types
-type input_type() :: atom() | binary | json | text.
-type response() :: {ok, map()} | {error, term()}.

-export_type([input_type/0, response/0]).

%%%============================================================================
%%% API
%%%============================================================================
-spec set_api_key(binary()) -> ok | no_return().
set_api_key(ApiKey) ->
    eac_server:set_api_key(ApiKey).

-spec set_http_options(list()) -> ok | no_return().
set_http_options(Options) ->
    eac_server:set_http_options(Options).

-spec get_http_options() -> list() | no_return().
get_http_options() ->
    eac_server:get_http_options().

-spec algo(binary(), binary()) -> response().
algo(AlgoName, Input) ->
    Args =
        #{<<"algo">> => AlgoName,
          <<"input">> => Input,
          <<"type">> => json},
    eac_server:call_api(Args).

-spec algo(binary(), binary(), input_type()) -> response().
algo(AlgoName, Input, Type) ->
    Args =
        #{<<"algo">> => AlgoName,
          <<"input">> => Input,
          <<"type">> => Type},
    eac_server:call_api(Args).

-spec algo(binary(), binary(), binary(), input_type()) -> response().
algo(AlgoName, Version, Input, Type) ->
    Args =
        #{<<"algo">> => AlgoName,
          <<"version">> => Version,
          <<"input">> => Input,
          <<"type">> => Type},
    eac_server:call_api(Args).

-spec algo(binary(), binary(), binary(), input_type(), map()) -> response().
algo(AlgoName, Version, Input, Type, Options) ->
    Args =
        #{<<"algo">> => AlgoName,
          <<"version">> => Version,
          <<"input">> => Input,
          <<"type">> => Type,
          <<"options">> => Options},
    eac_server:call_api(Args).

%%%============================================================================
%%% Application Behavior
%%%============================================================================
-spec start() -> {ok, [atom()]}.
start() ->
    application:ensure_all_started(?APP).

-spec stop() -> ok | {error, term()}.
stop() ->
    application:stop(?APP).
