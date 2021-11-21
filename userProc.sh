#!/bin/bash

# AUTOR:	Jorge Cabrera Rodríguez
# ALU:		alu0101351773

# Constantes de estilo
TEXT_BOLD=$(tput bold)
TEXT_ULINE=$(tput sgr 0 1)
TEXT_GREEN=$(tput setaf 2)
TEXT_RESET=$(tput sgr0)

# Archivo temporal del script
TEMP_FILE=$(tempfile --prefix="tmp" --suffix=".userproc.$$")

# Variables de opciones
TIME=1
COUNT=0
SORT_CRITERIA="-k 1"
SORT_INV=""
USER_MANUAL=0
REAL_USER=0

# Comprobamos que los usuarios de la lista de usuarios existen
function check_user_list() {
	for U_SER in $USER_LIST; do
		id $U_SER 1>/dev/null 2>&1
		# Si el comando anterior ha fallado (Salida de error)
		if [ "$?" -ne "0" ]; then
			exit_error "Usuario desconocido"
		fi
	done
}

# Creamos una lista de usuarios con procesos 
# que cumplan la condición de tiempo
function set_user_list() {
	USER_LIST=$( ps --no-header -eo time,user | \
				tr ':' ' ' | \
				awk '{print $4, $1 * 3600 + $2 * 60 + $3}' | \
				awk -v time=$TIME '$2 > time {print $1;}' | \
				sort -u )
}


# Filtramos usuarios conectados actualmente 
function filter_user_list() {
	FILTER_LIST=$(who | tr -s ' ' | cut -d ' ' -f 1 | tr '\n' '\|')
	USER_LIST=$(echo $USER_LIST | tr ' ' '\n' | \
				grep -E -w $FILTER_LIST | tr '\n' ' ')
}


# Establecemos la lista de información
function set_list() {
	for U_SER in $USER_LIST; do
		USER_GID=$( id -g $U_SER)
		USER_UID=$( id -u $U_SER)
		
		# Número de procesos que cumplen la condición de tiempo 
		if [ "$COUNT" -eq "1" ];then
			user_proc_num=$(ps --no-header -u $U_SER | tr ':' ' ' | \
							awk '{print $3 * 60 * 60 + $4 * 60 + $5;}' | \
							awk -v time=$TIME '$1 > time {print $1;}' | wc -l)
		# Número de procesos de un usuario
		else
			user_proc_num=$( ps --no-header -u $U_SER | wc -l)
		fi
		
		USER_CPU=$( ps --no-header -eo pid,time,user | grep -w $U_SER | \
					sort -k 2 -r | head -n 1 | \
					tr -s ' ' | awk '{print $1, $2;}')

		echo 	"$U_SER $USER_GID $USER_UID" \
				"$user_proc_num $USER_CPU" >> $TEMP_FILE
	done
}


# Ordenamos la lista de información según los criterios introducidos
function sort_list() {
	echo -e "$(sort $SORT_CRITERIA $SORT_INV $TEMP_FILE)" > $TEMP_FILE
}


# Imprimimos la lista de información contenida en el fichero temporal
function print_list() {
	echo -e "${TEXT_BOLD}USER GID UID PNUM GPU(pid) GPU(t)${TEXT_RESET}" \
			"\n$(cat $TEMP_FILE)" > $TEMP_FILE
	column -t -s ' ' $TEMP_FILE
	echo
}


# Ayuda sobre el script
function usage() {
	echo 	"usage: userProc [-t time] [-usr] [-u user1 user2 ...]" \
			"[-count] [-inv] [[-c]|[-pid]]"
}


# Función auxiliar de error
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
			REAL_USER=1
		;;

		-count )
			COUNT=1
		;;

		-inv )
			SORT_INV="-r"
		;;

		-t )
		shift
			# Solo si el valor introducido es un número
			if [[ "$1" =~ ^[0-9]+$ ]]; then
				TIME=$1
			else
				exit_error "Valor de tiempo incorrecto."
			fi
		;;

		-u )
			USER_MANUAL=1
			# Siempre que el SIGUIENTE argumento sea una palabra
			while [[ "$2" =~ ^[A-Za-z_]+$ ]]; do
				LIST_MODIFIED=1
				shift
				USER_LIST="$USER_LIST $1"
			done

			# En caso de no haber pasado ningún usuario
			if [ "$LIST_MODIFIED" -ne "1" ]; then
				exit_error "Error al pasar usuarios"
			else
				LIST_MODIFIED=0
			fi

		;;

		-c )
			if [ "$SORT_CRITERIA" != "-k 1" ]; then
				exit_error "Exceso de criterios de ordenación"
			else
				SORT_CRITERIA="-k 4 -n"
			fi
		;;

		-pid )
			if [ "$SORT_CRITERIA" != "-k 1" ]; then
				exit_error "Exceso de criterios de ordenación"
			else
				SORT_CRITERIA="-k 5 -n"
			fi
		;;

		* )
			exit_error "Argumento desconocido"
		;;
	esac
	shift
done

if [ "$USER_MANUAL" -eq "0" ]; then
	set_user_list
fi

check_user_list

if [ "$REAL_USER" -eq "1" ]; then
	filter_user_list
fi

set_list
sort_list
print_list
