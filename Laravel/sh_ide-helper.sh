#!/usr/bin/env bash
# script for (re)generating ide-helper file "_ide_helper.php"

if [ $(id -u) = 0 ]; then
   echo "This script should NOT be run as root"
   exit 1
fi

# bash file for generating helper file "_ide_helper.php"
echo "composer dump-autoload..."
composer dump-autoload

echo "deleting bootstrap/compiled.php and bootstrap/services.php..."
php artisan clear-compiled

echo "ide-helper:generate..."
php artisan ide-helper:generate

echo "creating bootstrap/compiled.php and bootstrap/services.php..."
php artisan optimize --force

echo "ready"
