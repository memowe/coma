-- View mit sortierter Stringkonkatenation aller Verbindungen
CREATE VIEW map_summary AS SELECT * FROM (
    SELECT map_id, GROUP_CONCAT(k, ', ') AS connections
        FROM (
            SELECT map_id, PRINTF('%s -%s-> %s', from_name, type, to_name) as k
                FROM connection ORDER BY from_name, type, to_name
        )
        GROUP BY map_id
);

-- Join des Views mit sich selbst, aber nur die passenden
SELECT a_map.name AS "Erste Gruppe", b_map.name "Zweite Gruppe", a.connections
    FROM map_summary AS a, map_summary AS b
        LEFT JOIN map a_map ON a.map_id = a_map.id
        LEFT JOIN map b_map ON b.map_id = b_map.id
    WHERE a.map_id < b.map_id AND a.connections == b.connections;

-- Fertig
DROP VIEW map_summary;
