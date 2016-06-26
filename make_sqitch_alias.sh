#!/bin/bash

alias sqitch="docker run --rm --link db:db -v ~/.sqitch:/root/.sqitch -v $(pwd)/src:/src docteurklein/sqitch:pgsql"

