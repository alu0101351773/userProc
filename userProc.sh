#!/bin/bash

TEXT_BOLD=$(tput bold)
TEXT_ULINE=$(tput sgr 0 1)
TEXT_GREEN=$(tput setaf 2)
TEXT_RESET=$(tput sgr0)


function basic_function() {

	user_list=$( ps --no-header -eo time,user | \
				tr ':' ' ' | \
				awk '{print $4, $1 * 60 * 60 + $2 * 60 + $3}' | \
				awk '$2 > 1 {print $1;}' | \
				sort -u | \
				tr '\n' ' ' )

	for user in $user_list; do
		user_gid=$( id -g $user)
		user_uid=$( id -u $user)
		user_proc_num=$( ps --no-header -u $user | wc -l)
		user_cpu=$(ps --no-header -u $user -eo pid,time | sort -k 2 -r | head -n 1 | tr -s ' ')
		echo "$user $user_uid $user_proc_num $user_cpu"
	done
}

basic_function 

while []; do

done