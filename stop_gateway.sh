#!/bin/sh

for pid in $(ps -fu root  | grep gateway | awk '{ echo $2 }'); do sudo kill -9 $pid; done 
