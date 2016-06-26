#!/usr/bin/env bash 
shopt -s expand_aliases
_pause() {
    read -rsp $'Press any key to continue...\n' -n1 key
}
_print_cmds() {
    case $1 in
        on) set -v ;;
        off) set +v ;;
    esac
}
alias print_cmds='{ _print_cmds $(cat); } 2>/dev/null <<<'

echo "Did you 'source make_sqitch_alias.sh'?  That gives you the alias to run sqitch inside docker if you need it."
source make_sqitch_alias.sh

mkdir -p src
cd src
rm -rf .git *
git init .
touch README.md
git add .
git commit -am 'Init test project'

_pause
echo
echo "Creating two projects..."
print_cmds on
sqitch init proj1 --engine pg --plan-file proj1.plan --target db:pg://postgres@db/postgres
sqitch init proj2 --engine pg --plan-file proj2.plan --target db:pg://postgres@db/proj2
print_cmds off

_pause
echo
echo "For some reason, even passing the --target argument doesn't actually put the targets in sqitch.conf, so let's add them."
print_cmds on
sqitch target
sqitch target add proj1 db:pg://postgres@db/postgres
sqitch target add proj2 db:pg://postgres@db/proj2
sqitch target
print_cmds off

_pause
echo
echo "Now let's add a change to create the proj2 database"
print_cmds on
sqitch add create_proj2_db proj1 -n "Create proj2 db"
sed -i '' -Ee "/BEGIN|COMMIT/d;s/.*XXX.*/CREATE DATABASE proj2;/" deploy/create_proj2_db.sql
sed -i '' -Ee "/BEGIN|COMMIT/d;s/.*XXX.*/DROP DATABASE proj2;/" revert/create_proj2_db.sql
print_cmds off

_pause
echo
echo "And deploy it..."
print_cmds on
sqitch deploy
print_cmds off

_pause
echo
echo "Here are the current plans:"
print_cmds on
sqitch -f proj1.plan plan
sqitch status proj1
echo
sqitch -f proj2.plan plan
sqitch status proj2
print_cmds off

_pause
echo
echo "Now, let's create the second change in proj2 which is dependent on the first."
echo "Note when I try to use the command shown in the sqitch-add.pod#Examples: sqitch add --change x proj2 ... it doesn't work."
echo "Either it adds the change to the default plan, or if I say proj2.plan, it says unknown argument."
echo "So, we'll do it this way instead."

_pause
print_cmds on
sqitch -f proj2.plan add create_a_table -r 'proj1:create_proj2_db' -n "Create proj2 table"
sed -i '' -e "s/.*XXX.*/CREATE TABLE proj2_test_table;/" deploy/create_a_table.sql
sed -i '' -e "s/.*XXX.*/DROP TABLE proj2_test_table;/" revert/create_a_table.sql
print_cmds off

_pause
echo
echo "Here are the current plans:"
print_cmds on
sqitch -f proj1.plan plan
sqitch status proj1
echo
sqitch -f proj2.plan plan
sqitch status proj2
print_cmds off

_pause
echo
echo "And try to deploy it..."
print_cmds on
sqitch deploy proj2
print_cmds off

echo
echo "So, at the moment, it looks like this feature can't be used to order execution of changes across projects, it seems to just be a way to bring a change from another project into this one?"
