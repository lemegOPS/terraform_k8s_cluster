#!/bin/bash
ip = curl --silence ifconfig.me
echo $ip/32
