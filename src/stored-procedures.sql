-- FUNCIÓN: Consulta Top Canciones de la Semana (fecha_inicio, fecha_fin)
-- SELECT * FROM spotify.sp_top_songs_week('2022-01-07', '2022-01-13');

CREATE OR REPLACE FUNCTION spotify.sp_top_songs_week (
    IN start_date_week DATE,
    IN end_date_week DATE,
    OUT rank BIGINT,
    OUT track_name VARCHAR,
    OUT artist_names TEXT,
    OUT record_company_name VARCHAR,
    OUT streams INTEGER
)
RETURNS SETOF RECORD AS $BODY$
DECLARE
    reg RECORD;
BEGIN
    FOR REG IN
        SELECT ROW_NUMBER () OVER () AS rank, s.track_name, string_agg (a.name, ', ') AS artist_names , rc.name AS record_company_name, ws.streams FROM core.songs s
        JOIN core.record_companies rc ON (s.record_company_id = rc.id)
        JOIN core.song_artist sa ON (s.id = sa.song_id)
        JOIN core.artists a ON (a.id = sa.artist_id)
        JOIN spotify.weeks_songs ws ON (s.id = ws.song_id)
        WHERE ws.start_date = start_date_week AND ws.end_date = end_date_week
        GROUP BY s.id, s.track_name, rc.name,  ws.streams, ws.end_date
        ORDER BY ws.streams DESC
     LOOP
       rank := reg.rank;
       track_name := reg.track_name;
       artist_names := reg.artist_names;
       record_company_name := reg.record_company_name;
       streams := reg.streams;
       RETURN NEXT;
    END LOOP;
    RETURN;
END
$BODY$ LANGUAGE 'plpgsql';


-- PROCESO ALMACENADO: Busca la semana dado una fecha de entrada
-- CALL spotify.sp_find_week_by_date('2022-06-07', NULL, NULL);

CREATE OR REPLACE PROCEDURE spotify.sp_find_week_by_date(
	IN find_date DATE,
    OUT found_start_date DATE,
    OUT found_end_date DATE
)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
is_new BOOLEAN;
BEGIN
    SELECT viw.start_date_week, viw.end_date_week INTO found_start_date, found_end_date FROM spotify.v_intervals_weeks AS viw
    WHERE find_date BETWEEN viw.start_date_week::DATE AND viw.end_date_week::DATE
    LIMIT 1;
END;
$BODY$;