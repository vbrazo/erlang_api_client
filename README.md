# Erlang API Client

Erlang API Client using [Hackney](https://github.com/benoitc/hackney/) HTTP Client

## Dependencies

* Erlang (>= R18)
* [rebar3](https://github.com/erlang/rebar3)

## Running application

```erlang
1> application:start(api_client)
```

## Run locally

```bash
$ ./bin/start.sh
```

## Usage

First you have to set the `API KEY` for your API.

```erlang
1> eac:set_api_key(<<"YOUR API KEY">>).

=INFO REPORT==== 13-May-2016::20:14:34 ===
set_api_key - <<"YOUR API KEY">>
ok

2> eac:algo(<<"demo/Hello/0.1.1">>, <<"HAL 9000">>, text).

=INFO REPORT==== 13-May-2016::20:14:40 ===
[API] URI=https://api.datafit.com/v1/demo/Hello/0.1.1
{ok,#{<<"metadata">> => #{<<"content_type">> => <<"text">>,
        <<"duration">> => 0.001761989},
      <<"result">> => <<"Hello HAL 9000">>}}
```

You can pass additional [Hackney HTTP Client options](https://github.com/benoitc/hackney/blob/master/doc/hackney.md#request-4). By default `pool` option is used.

## Testing

- To run all tests use `rebar3 eunit`.
- To see test coverage `rebar3 cover`.
