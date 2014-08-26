rm data/graph.sqlite
sqlite3 data/graph.sqlite < data/schema.sql
sqlite3 data/graph.sqlite < data/init_data.sql
