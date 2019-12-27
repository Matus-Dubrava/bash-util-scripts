#!/bin/bash

# This script lists files in directories that are listed in the PATH variable.

IFS=:
for dir in ${PATH}; do
	echo "${dir}"
	
	for file in ${dir}/*; do
		echo "    ${file}"
	done
done

