#!/bin/bash

erl -pa deps/*/ebin ebin \
    -boot start_sasl \
    -sname ea@$(hostname) \
    -noshell \
    -detached \
    -s ea
