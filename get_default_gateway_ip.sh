#!/bin/bash

# This script just prints out IP address of default gateway.

ip route | grep '^default' | awk '{print $3}'
