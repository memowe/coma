CREATE TABLE map (
    id          INTEGER,
    name        STRING,
    description STRING,
    PRIMARY KEY (id)
);

CREATE TABLE connection (
    map_id      INTEGER,
    from_name   STRING,
    type        STRING,
    to_name     STRING,
    PRIMARY KEY (map_id, from_name, type, to_name),
    FOREIGN KEY (map_id) REFERENCES map (id)
);

CREATE VIEW connection_type AS
    SELECT DISTINCT type name
        FROM connection;

CREATE VIEW map_from_degree AS
    SELECT map_id, from_name name, COUNT(*) from_degree
        FROM connection
        GROUP BY map_id, name;

CREATE VIEW map_to_degree AS
    SELECT map_id, to_name name, COUNT(*) to_degree
        FROM connection
        GROUP BY map_id, name;

CREATE VIEW map_entity AS
    SELECT map_id, name, SUM(degree) degree
        FROM (
                    SELECT map_id, name, from_degree degree FROM map_from_degree
        UNION ALL   SELECT map_id, name, to_degree   degree FROM map_to_degree
        )
        GROUP BY map_id, name;

CREATE VIEW from_degree AS
    SELECT name, SUM(from_degree) from_degree
        FROM map_from_degree
        GROUP BY name;

CREATE VIEW to_degree AS
    SELECT name, SUM(to_degree) to_degree
        FROM map_to_degree
        GROUP BY name;

CREATE VIEW entity AS
    SELECT name, SUM(degree) degree
        FROM map_entity
        GROUP BY name;
