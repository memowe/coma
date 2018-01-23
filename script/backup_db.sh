timestamp=`date -u +"%Y-%m-%dT%H:%M:%SZ"`
sqlite3 data/graph.sqlite '.dump' > "data/backup/$timestamp.sql"
