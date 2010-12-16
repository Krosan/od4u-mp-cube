#!/bin/bash

set -e

./cards2spoiler.py > od4u-mp-cube.txt
./mws2nd.pl -i od4u-mp-cube.txt
