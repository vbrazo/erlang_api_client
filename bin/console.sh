#!/bin/bash

erl -remsh ea@$(hostname) -sname ea_$RANDOM@$(hostname)
