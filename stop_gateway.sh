#!/bin/sh

for pid in $(ps -fu www-data  | grep gateway | awk '{ print $2 }'); do sudo kill -9 $pid; done 
