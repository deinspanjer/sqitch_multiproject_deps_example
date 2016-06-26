#!/bin/bash

if [[ "true" = "$(docker inspect --format {{.State.Running}} db)" ]]; then
    echo "*** db is already running!  To reset, 'docker rm -f db' and optionally 'rm -rf mydata/*'"
    echo "*** Tail of 'docker logs db':"
    docker logs --tail 10 db
else
    if [[ -z "$(docker ps --filter name=db -aq)" ]]; then
        echo "*** Creating new local mydata folder..."
        mkdir -p mydata
        echo "*** Creating new db container..."
        docker run --name db -P -d -v $(pwd)/mydata:/var/lib/postgresql/data postgres:9.5
    else
        echo "*** Stopped db found.  Restarting with 'docker start db'"
        docker start db
    fi

    echo "*** Watching logs 30 seconds for initialization to complete..."
    expect <<- DONE
        set timeout 30
        spawn docker logs --tail 4 --follow db
        expect {
            default { puts "\n*** Failed to detect proper startup of db!\n"; exit 1 }
            "Data page checksums are disabled." {
                puts "\n*** Looks like a new db. Waiting for 'init complete'\n"
                expect {
                    default { puts "\n*** Failed to detect proper startup of db!\n"; exit 1 }
                    "PostgreSQL init process complete; ready for start up." {
                        puts "\n*** Init complete. Waiting for restart.\n"
                        expect {
                            default { puts "\n*** Failed to detect proper startup of db!\n"; exit 1 }
                            "LOG:  database system is ready to accept connections" {
                                puts "\n*** Startup complete.\n"
                                exit
                            }
                        }
                    } 
                }
            }
            "LOG:  database system is ready to accept connections*" {
                puts "\n*** db restarted.\n"
                exit
            }
        }
DONE

echo
echo "The Postgres port number is: $(docker port db)"

fi
