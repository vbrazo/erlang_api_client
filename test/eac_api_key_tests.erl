%%%----------------------------------------------------------------------------
%%% @author Vitor Oliveira <vbrazo@gmail.com>
%%% @doc
%%% API Erlang client - API tests with keys
%%% @end
%%%----------------------------------------------------------------------------
-module(eac_api_key_tests).

-compile(export_all).

-include_lib("eunit/include/eunit.hrl").

%%%=============================================================================
eac_server_api_key_test_() ->
    {foreach,
     fun() -> eac:start() end,
     fun(_) -> eac:stop() end,
     [{"Demo Hello Alg", {timeout, 60, fun test_hello_alg/0}}]}.

%%%=============================================================================
test_hello_alg() ->
    Creds = read_keys(),

    {error, Reason1} = eac:algo(<<"demo/Hello/0.1.1">>, <<"HAL 9000">>, text),
    ?assertEqual(<<"authorization required">>, Reason1),

    ok =
        eac:set_api_key(
            maps:get(<<"api_key">>, Creds)),

    {ok, Map1} = eac:algo(<<"demo/Hello/0.1.1">>, <<"HAL 9000">>, text),
    ?assertEqual(<<"Hello HAL 9000">>, maps:get(<<"result">>, Map1)),
    ?assertEqual(<<"text">>, maps:get(<<"content_type">>, maps:get(<<"metadata">>, Map1))),

    {ok, Map2} = eac:algo(<<"demo/Hello">>, <<"0.1.1">>, <<"HAL 9000">>, text),
    ?assertEqual(<<"Hello HAL 9000">>, maps:get(<<"result">>, Map2)),
    ?assertEqual(<<"text">>, maps:get(<<"content_type">>, maps:get(<<"metadata">>, Map2))),

    {error, Reason2} = eac:algo(<<"demo/Hello/0.1.1">>, <<"HAL 9000">>, json),
    ?assertEqual(<<"Failed to parse input, input did not parse as valid json">>, Reason2),

    ok.

%%%=============================================================================
read_keys() ->
    case file:consult("api_key.txt") of
        {ok, [Creds]} ->
            Creds;
        _Other ->
            ?debugFmt("Unable to read API KEY file - api_key.txt!", []),
            error("Missing api_key.txt file!")
    end.
