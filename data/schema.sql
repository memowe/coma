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

CREATE VIEW entity AS
    SELECT DISTINCT *
        FROM (
                    SELECT map_id, from_name name FROM connection
            UNION   SELECT map_id, to_name   name FROM connection
        );

CREATE VIEW connection_type AS
    SELECT DISTINCT type name
        FROM connection;

CREATE VIEW from_degree AS
    SELECT map_id, from_name name, COUNT(*) from_degree
        FROM connection
        GROUP BY map_id, name;

CREATE VIEW to_degree AS
    SELECT map_id, to_name name, COUNT(*) to_degree
        FROM connection
        GROUP BY map_id, name;

CREATE VIEW degree AS
    SELECT map_id, name, SUM(degree) degree
        FROM (
                    SELECT map_id, name, from_degree degree FROM from_degree
            UNION   SELECT map_id, name, to_degree   degree FROM to_degree
        )
        GROUP BY map_id, name;

CREATE VIEW degree_overall AS
    SELECT name, SUM(degree) degree
        FROM degree
        GROUP BY name;
