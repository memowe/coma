rm t/graph.sqlite
sqlite3 t/graph.sqlite < data/schema.sql
sqlite3 t/graph.sqlite < t/init_data.sql
