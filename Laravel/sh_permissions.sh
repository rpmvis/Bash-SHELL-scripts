#!/bin/bash
# script for setting Linux directory / file permissions with Laravel framework.
# Permissions are set for the "storage", "bootstrap", datatables" maps, amongst others.

if ! [ $(id -u) = 0 ]; then
   echo "This script must be run as root"
   exit 1
fi

PROGNAME=$(basename $0)

function error_exit(){
#	Function for exit due to fatal program error
#		Accepts 1 argument:
#			string containing descriptive error message
#	----------------------------------------------------------------
    # The Unix / Linux standard I/O streams with numbers:
    #
    # Handle	Name	Description
    # 0	stdin	Standard input
    # 1	stdout	Standard output
    # 2	stderr	Standard error
    # 1>&2: Redirect (1 = stdin) (>=to) (& = descriptor of) (2=stdout)
	echo "ERROR ${PROGNAME}: ${1:-"Unknown Error"}: $2" 1>&2
	exit 1
}

function get_dir_existent(){
    local local_dir_options=$1
    local local_result=$2

    local local_temp=''
    # split string with directories, delimited by ";"
    local arr=$(echo $local_dir_options | tr ";" "\n")

    for x in $arr
    do
        if [[ -d "$x" ]]; then
            # echo "bingo"
            local local_temp="$x"
        fi
    done

    eval $local_result="'$local_temp'"
    # echo "local_result: '$local_result'"
}

function get_file_existent(){
    local local_file_options=$1
    local local_result=$2
    local local_temp=''

    # split string with files, delimited by ";"
    local arr=$(echo $local_file_options | tr ";" "\n")

    for x in $arr
    do
        if [[ -f "$x" ]]; then
            local local_temp="$x"
        fi
    done

    eval $local_result="'$local_temp'"
}

map="./storage"

# storage directory: ensure we are on the root of the Laravel application
storage_dir_options="$map;"
get_dir_existent $storage_dir_options storage_dir
if [[ ! $storage_dir ]]; then
    error_exit "line $LINENO" "Cannot set permissions on storage directory! No storage directory ($cache_dir_options) was found."
fi

echo "setting permissions for map $map..."
chown -R rene:www-data $map
find $map -type d -exec chmod 775 {} \; && find $map -type f -exec chmod 664 {} \;

#echo "setting permissions for gitignore files in $map map..."
chown rene:www-data $map/app/.gitignore $map/framework/.gitignore $map/framework/cache/.gitignore $map/framework/sessions/.gitignore $map/logs/.gitignore

file="$map/.gitignore"
if [[ -f "$file" ]]; then
    #echo "setting permissions for gitignore file in $map map..."
    chown rene:www-data $file
fi

map="./bootstrap"

echo "setting permissions for map $map..."
chown -R rene:www-data $map
find $map -type d -exec chmod 775 {} \; && find $map -type f -exec chmod 775 {} \;

map="./public"
echo "setting permissions for map $map..."
chown -R rene:www-data $map
find $map -type d -exec chmod 775 {} \; && find $map -type f -exec chmod 664 {} \;

map="./datatables"
if [[ -d "$map" ]]; then
    echo "setting permissions for map $map..."
    chown -R rene:www-data $map
    find $map -type d -exec chmod 775 {} \; && find $map -type f -exec chmod 664 {} \;
fi

map="./.openshift/action_hooks"
if [[ -d "$map" ]]; then
    echo "setting executable permission for files in $map map..."
    find $map -type f -exec chmod +x {} +
fi

file="./storage/logs/laravel.log"
if [[ ! -f "$file" ]]; then
    touch $file
fi

echo "setting permissions for file $file..."
chown -R rene:www-data $file
chmod 664 $file

echo "you may run as user: composer dump-autoload ..."

echo "ready."
