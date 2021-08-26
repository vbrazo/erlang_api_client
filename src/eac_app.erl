%%%----------------------------------------------------------------------------
%%% @author Vitor Oliveira <vbrazo@gmail.com>
%%% @doc
%%% API Erlang client - OTP application
%%% @end
%%%----------------------------------------------------------------------------
-module(eac_app).

-behaviour(application).

%% Application callbacks
-export([start/2, stop/1]).

%%%============================================================================
%%% Application callbacks
%%%============================================================================
-spec start(normal | {takeover, node()} | {failover, node()}, term()) ->
               {ok, pid()} | {ok, pid(), term()} | {error, any()}.
start(_StartType, _StartArgs) ->
    eac_sup:start_link().

-spec stop(term()) -> ok.
stop(_State) ->
    ok.
