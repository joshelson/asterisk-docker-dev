#!/bin/bash

trap "echo 'Received SIGINT'; exit" SIGINT

exec "$@"
