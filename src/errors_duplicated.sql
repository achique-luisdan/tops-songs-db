SELECT s.* FROM core.songs s
WHERE s.id NOT IN (
    SELECT MIN (s.id) AS first_id FROM core.songs s
    GROUP BY s.track_name, s.record_company_id
)

SELECT COUNT(s.*) FROM core.songs s
WHERE s.id NOT IN (
    SELECT MIN (id) AS first_id FROM core.songs
    GROUP BY track_name, record_company_id
)

UPDATE spotify.weeks_songs AS ws
    SET ws.song_id = (
        SELECT first_id
        FROM (
            SELECT ARRAY_AGG (ss.id) AS ids,  MIN (ss.id) AS first_id  FROM core.songs ss
            JOIN spotify.weeks_songs wss ON (wss.song_id = ss.id)
            GROUP BY ss.track_name, ss.record_company_id
        ) AS songs
        WHERE ws.song_id = ANY  ( ids)
    )
    WHERE s.id NOT IN (
        SELECT MIN (id) AS first_id FROM core.songs
        GROUP BY track_name, record_company_id
    );

SELECT COUNT (*) FROM spotify.weeks_songs
    WHERE s.id NOT IN (
        SELECT MIN (id) AS first_id FROM core.songs
        GROUP BY track_name, record_company_id
    );


DELETE FROM core.songs s
WHERE s.id NOT IN (
    SELECT MIN (id) AS first_id FROM core.songs
    GROUP BY track_name, record_company_id
);