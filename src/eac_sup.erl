%%%----------------------------------------------------------------------------
%%% @author Vitor Oliveira <vbrazo@gmail.com>
%%% @doc
%%% API Erlang client - OTP application supervisor
%%% @end
%%%----------------------------------------------------------------------------
-module(eac_sup).

-behaviour(supervisor).

%% API
-export([start_link/0]).
%% Supervisor callbacks
-export([init/1]).

-define(CHILD(I, Type, Params),
        #{id => I,
          start => {I, start_link, Params},
          restart => permanent,
          type => Type}).

%%%============================================================================
%%% API functions
%%%============================================================================
-spec start_link() -> {ok, pid()} | ignore | {error, any()}.
start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

%%%============================================================================
%%% Supervisor callbacks
%%%============================================================================
init([]) ->
    {ok,
     {#{strategy => one_for_one,
        intensity => 5,
        period => 10},
      [?CHILD(eac_server, worker, [])]}}.
