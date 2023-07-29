-- FUNCIÓN: Consulta Top Canciones de la Semana (fecha_inicio, fecha_fin)
-- SELECT * FROM spotify.sp_top_songs_week('2022-01-07', '2022-01-13');
-- DROP FUNCTION IF EXISTS spotify.sp_top_songs_week(date, date);
CREATE OR REPLACE FUNCTION spotify.sp_top_songs_week(
	IN start_date_week date,
	IN end_date_week date,
	OUT song_id integer,
	OUT rank bigint,
	OUT track_name character varying,
	OUT artist_names text,
	OUT record_company_name character varying,
	OUT streams integer
)
RETURNS SETOF record
    LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    reg RECORD;
BEGIN
    FOR REG IN
        SELECT s.id, ROW_NUMBER () OVER () AS rank, s.track_name, string_agg (a.name, ', ') AS artist_names , rc.name AS record_company_name, ws.streams FROM core.songs s
        JOIN core.record_companies rc ON (s.record_company_id = rc.id)
        JOIN core.song_artist sa ON (s.id = sa.song_id)
        JOIN core.artists a ON (a.id = sa.artist_id)
        JOIN spotify.weeks_songs ws ON (s.id = ws.song_id)
        WHERE ws.start_date = start_date_week AND ws.end_date = end_date_week
        GROUP BY s.id, s.track_name, rc.name,  ws.streams, ws.end_date
        ORDER BY ws.streams DESC
     LOOP
       song_id := reg.id;
       rank := reg.rank;
       track_name := reg.track_name;
       artist_names := reg.artist_names;
       record_company_name := reg.record_company_name;
       streams := reg.streams;
       RETURN NEXT;
    END LOOP;
    RETURN;
END
$BODY$;

-- FUNCIÓN: Consulta Top Canciones de la Semana (fecha_inicio, fecha_fin) retorna más información (puesto previo, movimiento)
-- SELECT * FROM spotify.sp_top_songs_week('2022-01-07', '2022-01-13');
-- DROP FUNCTION IF EXISTS spotify.sp_top_songs_week_full(date, date);

CREATE OR REPLACE FUNCTION spotify.sp_top_songs_week_full(
    IN start_date_week date,
    IN end_date_week date,
    OUT song_id integer,
    OUT rank bigint,
    OUT track_name character varying,
    OUT artist_names text,
    OUT record_company_name character varying,
    OUT streams integer,
    OUT previous bigint,
    OUT move bigint,
    OUT type_move TEXT
)
RETURNS SETOF record
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    reg RECORD;
    start_date_last_week DATE;
    end_date_last_week DATE;
BEGIN
SELECT
    TO_CHAR(start_date_week - CAST ('7 days' AS INTERVAL), 'YYYY-MM-DD'),
    TO_CHAR(end_date_week - CAST ('7 days' AS INTERVAL), 'YYYY-MM-DD')
    INTO start_date_last_week, end_date_last_week;
    FOR REG IN
        SELECT w.*, lw.rank AS previous, lw.rank -w.rank AS move,
            CASE
                WHEN lw.rank - w.rank > 0 THEN 'UP'
                WHEN lw.rank -w.rank < 0 THEN 'DOWN'
                WHEN lw.rank -w.rank = 0 THEN 'STOP'
                ELSE 'UNKNOWN'
            END AS type_move
        FROM spotify.sp_top_songs_week(start_date_week, end_date_week) w
        LEFT JOIN spotify.sp_top_songs_week(start_date_last_week, end_date_last_week) lw ON (w.song_id = lw.song_id)
        ORDER BY w.streams DESC
     LOOP
       song_id := reg.song_id;
       rank := reg.rank;
       track_name := reg.track_name;
       artist_names := reg.artist_names;
       record_company_name := reg.record_company_name;
       streams := reg.streams;
       previous := reg.previous;
       move := reg.move;
       type_move:= reg.type_move;
       RETURN NEXT;
    END LOOP;
    RETURN;
END
$BODY$;

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