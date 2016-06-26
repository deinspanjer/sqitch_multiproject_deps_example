# sqitch_multiproject_deps_example
A couple of Docker images that demonstrate how to use multi-project dependencies in Sqitch

Usage:

1. Have docker installed and working
2. Clone this project
3. If you want to be able to play with sqitch commands locally, run `source make_sqitch_alias.sh`
4. Start the testing Postgres DB inside a docker container by running: `./start_sandbox_db.sh`
5. Run the script that demonstrates the sqitch commands by running: `./setup_sqitch.sh`

Advanced Usage:

1. Just read the source of the setup_sqitch.sh script. :)
