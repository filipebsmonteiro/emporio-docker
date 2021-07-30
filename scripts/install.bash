install ()
{
    logo

    sudo rm -Rf ../emporio
    sudo rm -Rf ../emporio-backend

    echo -n "Enter store's name: "
    read name

    sed -i.bak "1 s/.*/APP_NAME=$name/" .env
    rm .env.bak

    out "<33>Setting up prerequisites"
    dispatch config "programs"
    out ""

    out "<33>Cloning projects"
    dispatch config "clone-all"
    out ""

    rm docker/vue/package.json
    cp ../emporio/package.json docker/vue
    cp ../emporio/.env.example ../emporio/.env

    out "<33>Up'ing all services"
    dispatch docker "up"
    out ""

    rm docker/vue/package.json

    out "<33>Configuring projects"
    dispatch config "backend"
    out ""

#    cd ${pwd}

    out "<33>Generating Backend Keys"
    dispatch config "generate-backend-keys"
    out ""

    out "<33>Configuring Database"
    dispatch config "database-import"
    out ""

#    Time for waiting buckets compression
#    sleep 20

#    out "<33>Configuring projects"
#    dispatch config "projects"
#    out ""

    out "<33>Stopping Docker containers"
    dispatch docker "stop"
    out ""

    out "<33>Installation Finished"
    out ""
}
