#!/bin/bash

TEXT_BOLD=$(tput bold)
TEXT_ULINE=$(tput sgr 0 1)
TEXT_GREEN=$(tput setaf 2)
TEXT_RESET=$(tput sgr0)
TEMP_FILE=$(tempfile --prefix="tmp" --suffix=".userproc.$$")


# Si el usuario no ha indicado lista de usuarios
function set_user_list() {
	user_list=$( ps --no-header -eo time,user | \
				tr ':' ' ' | \
				awk '{print $4, $1 * 60 * 60 + $2 * 60 + $3}' | \
				awk -v time=$time '$2 > time {print $1;}' | \
				sort -u )
}


# Si queremos filtrar 
function filter_user_list() {
	filter_list=$(who | tr -s ' ' | cut -d ' ' -f 1 | tr '\n' '\|')
	user_list=$(echo $user_list | tr ' ' '\n' | grep -E -w $filter_list | tr '\n' ' ')
}


# Establecemos la lista de información
function set_list() {
	for user in $user_list; do
		user_gid=$( id -g $user)
		user_uid=$( id -u $user)
		user_proc_num=$( ps --no-header -u $user | wc -l)
		user_cpu=$(ps --no-header -u $user -eo pid,time | sort -k 2 -r | head -n 1 | tr -s ' ')
		echo "$user $user_gid $user_uid $user_proc_num $user_cpu" >> $TEMP_FILE
	done
}


function sort_list() {
	echo "Soy una avioneta, mira como vuelo FIUUUUMM"
}


function print_list() {
	column -t -s ' ' $TEMP_FILE
	echo
}


set_user_list
#filter_user_list
set_list
print_list