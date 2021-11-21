#!/bin/bash

# Constantes de estilo
TEXT_BOLD=$(tput bold)
TEXT_ULINE=$(tput sgr 0 1)
TEXT_GREEN=$(tput setaf 2)
TEXT_RESET=$(tput sgr0)

# Archivo temporal del script
TEMP_FILE=$(tempfile --prefix="tmp" --suffix=".userproc.$$")

# Variables de opciones
time=1
count=0
sort_criteria="-k 1"
sort_inv=""
user_manual=0
real_user=0

# Comprobamos que los usuarios introducidos manualmente existan
function check_user_list() {
	for user in $user_list; do
		id $user 1>/dev/null 2>&1
		if [ "$?" -ne "0" ]; then
			exit_error "Usuario desconocido"
		fi
	done
}

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
		if [ "$count" -eq "1" ];then
			user_proc_num=$( ps --no-header -u $user | tr ':' ' ' | awk '{print $3 * 60 * 60 + $4 * 60 + $5;}' | awk -v time=$time '$1 > time {print $1;}' | wc -l)
		else
			user_proc_num=$( ps --no-header -u $user | wc -l)
		fi
		
		user_cpu=$( ps --no-header -eo pid,time,user | grep -w $user | sort -k 2 -r | head -n 1 | tr -s ' ' | awk '{print $1, $2;}')
		echo "$user $user_gid $user_uid $user_proc_num $user_cpu" >> $TEMP_FILE
	done
}


function sort_list() {
	echo -e "$(sort $sort_criteria $sort_inv $TEMP_FILE)" > $TEMP_FILE
}


function print_list() {
	echo -e "${TEXT_BOLD}USER GID UID PNUM GPU(id) GPU(t)${TEXT_RESET}\n$(cat $TEMP_FILE)" > $TEMP_FILE
	column -t -s ' ' $TEMP_FILE
	echo
}


function usage() {
	echo "usage: userProc [-t time] [-usr] [-u user1 user2 ...] [-count] [-inv] [[-c]|[-pid]]"
}

function exit_error() {
	echo "${1:-"Error desconocido"}" 1>&2
	usage
	exit 1
}


while [ "$1" != "" ]; do
	case $1 in
		-h )
			usage
			exit 0
		;;

		-usr )
			real_user=1
		;;

		-count )
			count=1
		;;

		-inv )
			sort_inv="-r"
		;;

		-t )
		shift
			if [[ "$1" =~ ^[0-9]+$ ]]; then
				time=$1
			else
				exit_error "Tiempo incorrecto"
			fi
		;;

		-u )
			user_manual=1
			while [[ "$2" =~ ^[A-Za-z_]+$ ]]; do
				list_modified=1
				shift
				user_list="$user_list $1"
			done

			if [ "$list_modified" -ne "1" ]; then
				exit_error "Error al pasar usuarios"
			else
				list_modified=0
			fi

		;;

		-c )
			if [ "$sort_criteria" != "-k 1" ]; then
				exit_error "Exceso de criterios de ordenación"
			else
				sort_criteria="-k 4 -n"
			fi
		;;

		-pid )
			if [ "$sort_criteria" != "-k 1" ]; then
				exit_error "Exceso de criterios de ordenación"
			else
				sort_criteria="-k 5 -n"
			fi
		;;

		* )
			exit_error "Argumento desconocido"
		;;
	esac
	shift
done

if [ "$user_manual" -eq "0" ]; then
	set_user_list
fi

check_user_list

if [ "$real_user" -eq "1" ]; then
	filter_user_list
fi

set_list
sort_list
print_list
