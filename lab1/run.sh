psql -h pg -d studs -f ~/RSHD/lab1/procedures.sql
psql -h pg -d studs -f ~/RSHD/lab1/script.sql 2>&1 | sed 's|.*NOTICE:  ||g'