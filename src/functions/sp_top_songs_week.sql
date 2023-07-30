-- FUNCTION: spotify.sp_top_songs_week(date, date)

-- DROP FUNCTION IF EXISTS spotify.sp_top_songs_week(date, date);

CREATE OR REPLACE FUNCTION spotify.sp_top_songs_week(
	start_date_week date,
	end_date_week date,
	OUT song_id integer,
	OUT rank bigint,
	OUT track_name character varying,
	OUT artist_names text,
	OUT record_company_name character varying,
	OUT streams integer)
    RETURNS SETOF record 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

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