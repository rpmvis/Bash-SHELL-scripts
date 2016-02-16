#!/bin/bash
PROGNAME=$(basename $0)
#LINUX_GROUP_NAME_DEFAULT="apache_group"
LINUX_GROUP_NAME_DEFAULT="www-data"

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
            local local_temp="$x"
        fi
    done

    #echo "local_temp: '$local_temp'"
    eval $local_result="'$local_temp'"
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

    #echo "local_temp: '$local_temp'"
    eval $local_result="'$local_temp'"
}

file_options="./bin/console;./app/console"
get_file_existent $file_options console_file
if [[ ! $console_file ]]; then
    error_exit "line $LINENO" "console file ($file_options) not found! Upd command aborted."
fi

function clear_cache(){
#    cache_dir_options="./var/cache;./app/cache"
#    get_dir_existent $cache_dir_options cache_dir
#    #echo "result_dir: $result_dir"
#    if [[ ! $cache_dir ]]; then
#        error_exit "line $LINENO" "cache directory ($cache_dir_options) not found!  Removing cache files aborted."
#    fi
#    rm -rf "$cache_dir/*"
#    echo "${PROGNAME}: All files and directories in cache directory '$cache_dir' have been deleted."
    php $console_file cache:clear --no-warmup
    # warmup:  initialize any cache needed by the application
    # php $console_file cache:warmup
    echo "${PROGNAME}: cache cleared (no warm up)."
}


if [ $# > 0 ]; then
  case $1 in
	vendors|vendor)
	    clear_cache
	    file_options="./composer.phar;"
	    get_file_existent $file_options, composer_file
	    if [[ $composer_file ]]; then
	        php $composer_file update
	    else
	        composer update
	    fi
    ;;
	composer)
	    file_options="./composer.phar;"
	    get_file_existent $file_options, composer_file
	    if [[ $composer_file ]]; then
	        sudo php $composer_file self-update
	    else
	        sudo composer self-update
	    fi
        echo "${PROGNAME}: end of 'composer self-update' command."
    ;;
	assets)
	    clear_cache
	    php $console_file assets:install --symlink
    ;;
	db|database)
	    php $console_file doctrine:schema:update --force
	    echo "${PROGNAME}: end of Database update from Entity files."
    ;;
	cache)
        clear_cache
    ;;
	permissions)
	    cache_dir_options="./var/cache;./app/cache"
	    get_dir_existent $cache_dir_options cache_dir
	    logs_dir_options="./var/logs;./app/logs"
	    get_dir_existent $logs_dir_options logs_dir
        if [[ ! $cache_dir ]]; then
            error_exit "line $LINENO" "Cannot set permissions on cache directory! No cache directory ($cache_dir_options) was found."
        fi
        if [[ ! $logs_dir ]]; then
            error_exit "line $LINENO" "Cannot set permissions on logs directory! No logs directory ($logs_dir_options) was found."
        fi

        # find user and group for chown command
        me=$(whoami)

        # remove whitespaces from LINUX_GROUP_NAME_DEFAULT (with parameter expansion method)
        LINUX_GROUP_NAME_DEFAULT=$(echo ${LINUX_GROUP_NAME_DEFAULT//[[:blank:]]/})
        case $LINUX_GROUP_NAME_DEFAULT in
            null|"")
                # ps:       selects all processes of current user
                # aux:      a = show processes for all users; u = display the process's user/owner; x = also show processes not attached to a terminal
                # grep-E:   interpret PATTERN as an extended regular (POSIX) expression
                # grep -v root: Invert selection into non-matching lines; thus: all lines excluded those with 'root'
                # head -1:  display first line of input
                # f:        display full format listing
                HTTPDUSER=$(ps aux | grep -E '[a]pache.*start|[h]ttpd|[_]www|[w]ww-data|[n]ginx' | grep -v root | head -1 | cut -d\  -f1)
                #echo "HTTPDUSER is: $HTTPDUSER"
                linux_group_name=$HTTPDUSER
            ;;
            *)
                linux_group_name=$LINUX_GROUP_NAME_DEFAULT
            ;;
        esac

	    sudo chown -R "$me":"$linux_group_name" $cache_dir
	    sudo chown -R "$me":"$linux_group_name" $logs_dir
	    sudo setfacl -R -m u:"$me":rwX -m u:"$linux_group_name":rwX $cache_dir $logs_dir
        sudo setfacl -dR -m u:"$me":rwX -m u:"$linux_group_name":rwX $cache_dir $logs_dir
        echo "${PROGNAME}: Permissions set for $me:$linux_group_name in directories '$cache_dir' and '$logs_dir' via setfacl."
    ;;
    bundles)
        if [ $# != 1 ]; then
            error_exit "line $LINENO" "$# parameter(s) given; 1 parameter expected!"
        fi
        php $console_file config:dump
    ;;
    confbundle)
        if [ $# != 2 ]; then
            error_exit "line $LINENO" "$# parameter(s) given; 2 parameters expected!"
        fi
        php $console_file config:dump-reference $2
    ;;
    test)
        s="*  391   8912k  *"
        s2=$(echo ${s//[[:blank:]]/})
        echo "s2: $s2"
    ;;
    *)
        error_exit "line $LINENO" "unknown argument '$1' for 'upd' command."
    ;;
  esac
  exit 0
fi

echo "================================================================================"
echo "Usage: upd COMMAND"
echo
echo "COMMAND may be:"
echo "  vendors       runs a composer update."
echo "  db            runs console command 'doctrine:schema:update --force'"
echo "  database      same as above"
echo "  assets        runs console command 'assets:install' which installs Web Assets in the Web directory"
echo "  cache         completely empties the cache directory"
echo "  permissions   sets up permissions nicely, for cache and logs directories;"
echo "                your web user may be named 'apache' or 'httpd' or 'www-data'."
echo "  composer      runs a composer self-update."
echo "  confbundle    dumps configuration referencences for a bundle to be used in a Symfony configuration file."
echo "                1st parameter is 'confbundle', the second the name of the bundle"
echo
echo "Note: 'upd' MUST be run from the root directory of the project - as 'bash ./upd.sh'"
echo "================================================================================"
exit 1



