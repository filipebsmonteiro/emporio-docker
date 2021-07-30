docker_command_deps ()
{
    if ! type "docker" > /dev/null; then
        out "<31>Please install Docker"
        exit 1
    fi

    if ! type "docker-compose" > /dev/null; then
        out "<31>Please install Docker Compose"
        exit 1
    fi

#    docker login
}

docker_command_start-backend()
{
    dispatch docker "deps"
    out "<32>Starting containers"
    cd ${pwd}/../emporio-backend
    docker-compose start
    out ""
}

docker_command_stop-backend()
{
    dispatch docker "deps"
    out "<32>Stopping Containers"
    cd ${pwd}/../emporio-backend
    docker-compose stop
    out ""
}

docker_command_up-backend ()
{
    dispatch docker "deps"
    out "<32>Creating and starting ALL services"
    cd ${pwd}/../emporio-backend
    docker-compose up -d
    out ""
}

docker_command_down-backend()
{
    dispatch docker "deps"

    dispatch docker "stop"
    out "<32>Removing Containers"
    cd ${pwd}/../emporio-backend
    docker-compose rm
    out ""
}

dispatch env "$@"
