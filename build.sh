#!/bin/bash

set -e

./cards2spoiler.py > OMC.txt
./mws2nd.pl -i OMC.txt
