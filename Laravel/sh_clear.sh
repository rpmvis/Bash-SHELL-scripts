#!/usr/bin/env bash
# script for:
# a) clearing Framework cache, Configuration cache, Route cache
# b) refreshing bootstrap files (compiled.php, services.php).

# run this script from the web root dir

if [ $(id -u) = 0 ]; then
   echo "This script should NOT be run as root"
   exit 1
fi

# composer dump-autoload because namespaces may have changed
echo "composer dump-autoload..."
composer dump-autoload

# clear View cache in /storage/framework/views
echo "removing files from storage/framework/cache..."
rm -R storage/framework/cache/*

# clear View cache in /storage/framework/views
echo "clearing compiled views..."
php artisan view:clear

# clear Configuration cache
echo "clearing Configuration cache..."
php artisan config:clear

# clear Route cache
echo "clearing Route cache..."
php artisan route:clear

# clear Application cache
# OPENSHIFT give this error: Call to ugitcomposerndefined function Illuminate\Cache\apc_clear_cache()
if [ -z "$OPENSHIFT_REPO_DIR" ]; then
    echo "clearing Application cache..."
    php artisan cache:clear
fi

# delete bootstrap/compiled.php
echo "deleting bootstrap/compiled.php and bootstrap/services.php..."
php artisan clear-compiled

#create bootstrap/compiled.php
echo "creating bootstrap/compiled.php and bootstrap/services.php..."
php artisan optimize --force

echo "finish clear. But bootstrap/compiled.php and bootstrap/services.php need www-data owner! RUN  sudo bash sh_upd.sh !"
