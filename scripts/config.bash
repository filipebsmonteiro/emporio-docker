#!/usr/bin/env bash
config_ ()
{
    dispatch config "help"
}

config_option_h ()
{
    dispatch config "help"
}

config_option_help ()
{
    dispatch config "help"
}

config_command_help ()
{
    logo
    out "
<33>Usage:<0>
  ./env.sh config [command] [options]

<33>Options:
  <32;1>--help<0> (-h)               Display this help message

<33>Available commands:
  <32;1>programs<0>                  Check programs environment <35>(not set variables, hosts)
  <32;1>clone-all<0>                 Clone all projects
  <32;1>fullstack<0>                 Configure the Fullstack <35>(Frontend, Backend, Mysql)
  <32;1>db-import <90;1>[--force]<0>       Import database <90;1>(force if it already exists)
"
}

config_command_programs ()
{
    # sudo if not root
    if [ ! $(id -u) -eq 0 ]; then
        SUDO=sudo
    else
        SUDO=
    fi

    out "<32>Setting up system groups..."
    $SUDO usermod -aG docker $(whoami)

    out "<32>Setting up domain..."
    command -v cid > /dev/null && {
        $SUDO cid usersgrp > /dev/null 2>&1 && {
            out "    <92>Configuring CID user group..."
            $SUDO cid usersgrp add $(whoami) > /dev/null 2>&1 || true
        } || {
            out "CID: there's no usersgrp command available, so there's nothing to do, moving on..."
        }
    }

    ismac && {
        command -v brew > /dev/null || {
            /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
        }
        command -v curl > /dev/null || {
            brew install --with-openssl curl
        }
    }

    out "<32>Checking docker..."
    command -v docker > /dev/null && {
        out "$(docker --version)"
    } || {
        ismac && {
            out "Please install Docker Desktop for Mac and rerun $0 $*"
            out ""
            out "https://docs.docker.com/docker-for-mac/install/"
            exit 1
        }

        iswindows && {
            out "Please install Docker Desktop for Windows and rerun $0 $*"
            out ""
            out "https://docs.docker.com/docker-for-windows/install/"
            exit 1
        }

        out "<33>You don't have docker. Installing..."
        command -v curl > /dev/null && {
            curl -sSL https://get.docker.com/ | sh
        } || {
            wget -qO - https://get.docker.com/ | sh
        }
    }

    out "<32>Checking docker-compose..."
    command -v docker-compose > /dev/null && {
        out "$(docker-compose --version)"
    } || {
        ismac && {
            out "Please install Docker Desktop for Mac and rerun $0 $*"
            out ""
            out "https://docs.docker.com/docker-for-mac/install/"
            exit 1
        }

        iswindows && {
            out "Please install Docker Desktop for Windows and rerun $0 $*"
            out ""
            out "https://docs.docker.com/docker-for-windows/install/"
            exit 1
        }

        out "<33>You don't have docker-compose. Installing..."
        command -v curl > /dev/null && {
            DOCKER_LATEST=$(
                curl -L -H "Accept: application/json" https://github.com/docker/compose/releases/latest | \
                cut -d , -f 2 | \
                cut -d : -f 2 | \
                tr -d \"
            )
            $SUDO curl -L "https://github.com/docker/compose/releases/download/${DOCKER_LATEST}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        } || {
            DOCKER_LATEST=$(
                wget --header="Accept: application/json" -qO- https://github.com/docker/compose/releases/latest | \
                cut -d , -f 2 | \
                cut -d : -f 2 | \
                tr -d \"
            )
            $SUDO wget "https://github.com/docker/compose/releases/download/${DOCKER_LATEST}/docker-compose-$(uname -s)-$(uname -m)" -qO /usr/local/bin/docker-compose
        }
    }

    out "<32>Checking PHP..."
    command -v php > /dev/null && {
        out "$(php --version)"
    } || {
        if islinux; then
            $SUDO apt-get install php-cli php-dev php-curl
        elif ismac; then
            brew install --with-homebrew-curl php
        else
            out "Please install php-cli and php-curl and rerun $0 $*"
            exit 1
        fi
    }

}

config_command_clone-all ()
{
    dispatch config "clone emporio-backend"
    dispatch config "clone emporio"
}

config_command_clone ()
{
    repo=${1}

    vcshost="git@github.com"
    vcspath=":filipebsmonteiro/"

    [[ ! $(ssh -T ${vcshost} 2>&1 | grep denied | wc -l) -eq 0 ]] && {
        out "<31>Error, please check your ${vcshost} settings"
        exit 1;
    }

    out ""
    out "<32>Cloning ${repo} repository"

    test -d ../${repo} || {
        git clone ${vcshost}${vcspath}${repo}.git ../${repo} || {
            echo "<31>Error, you don't have permission to fetch ${repo} repository from ${vcshost##*@}<0>"
            exit 1;
        }
    }
}

config_clone_question ()
{
    repo=${1}

    out -n "<32>Do you wish clone the ${repo} repository? [y|n] "
    read -r response
    case $response in
        [yY][eE][sS]|[yY])
           dispatch config "clone ${repo}"
           out ""
           dispatch config "${repo}"
        ;;
        *)
            exit 1
        ;;
    esac
}

config_command_backend ()
{
    backend_path="${pwd}/../emporio-backend"

    if [ ! -d "${backend_path}" ]; then
        out "<31>Backend has not been cloned"
        config_clone_question "emporio-backend"
    fi

    if [ ! -f "${backend_path}/.env" ]; then
        out "<31>'.env' don't exists (copying)"
        cp "${backend_path}/.env.example" "${backend_path}/.env"
    fi

    app_name=$(grep APP_NAME  .env | cut -d '=' -f2)
    sed -i.bak "1 s/.*/APP_NAME=$app_name/" "${backend_path}/.env"
    rm "${backend_path}/.env.bak"

    php_container=$(echo "$app_name-php")

    if [ ! -d "${backend_path}/storage/logs/laravel.log" ]; then

        out "<31>Backend 'laravel.log' don't exists (creating)"
        docker exec -it $php_container touch storage/logs/laravel.log
#        cp "${backend_path}/.env.example" "${backend_path}/.env"
    fi

    out "<92>Change files permission, maybe it asks root password"
    sudo chmod 777 "${backend_path}/storage/logs/laravel.log"
    sudo chmod -R 777 "${backend_path}/storage/framework/sessions"
    sudo chmod -R 777 "${backend_path}/storage/framework/cache"
    sudo chmod -R 777 "${backend_path}/storage/framework/views"

    out "<92>Compose Install"
#    docker-compose exec emporio-backend-php bash -c "cd /var/www/carmen/ && chown -R www-data:www-data app/*"
    docker exec -it $php_container composer install

    out "<92>Artisan Optimize"
    docker exec -it $php_container php artisan optimize
    out ""
}

config_command_generate-backend-keys ()
{
    app_name=$(grep APP_NAME  .env | cut -d '=' -f2)
    php_container=$(echo "$app_name-php")

    out "<33>Generating Keys"
    docker exec -it $php_container php artisan key:generate
    docker exec -it $php_container php artisan jwt:secret
    docker exec -it $php_container php artisan optimize
}

config_command_database-import ()
{
    app_name=$(grep APP_NAME  .env | cut -d '=' -f2)
    php_container=$(echo "$app_name-php")

    out "<33>Migrating and Seeding Datatables"
    docker exec -it $php_container php artisan migrate
    docker exec -it $php_container php artisan migrate --path=database/migrations/loja
    docker exec -it $php_container php artisan db:seed
    docker exec -it $php_container php artisan optimize
}

#config_command_frontend ()
#{
#    if [ ! -d "${pwd}/../emporio" ]; then
#        out "<31>Frontend has not been cloned"
#        config_clone_question "emporio"
#    fi
#
#    out "<32>Configuring Frontend"
#}

