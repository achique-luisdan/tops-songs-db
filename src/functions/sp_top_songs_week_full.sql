-- FUNCTION: spotify.sp_top_songs_week_full(date, date)

-- DROP FUNCTION IF EXISTS spotify.sp_top_songs_week_full(date, date);

CREATE OR REPLACE FUNCTION spotify.sp_top_songs_week_full(
	start_date_week date,
	end_date_week date,
	OUT song_id integer,
	OUT rank bigint,
	OUT track_name character varying,
	OUT artist_names text,
	OUT record_company_name character varying,
	OUT streams integer,
	OUT previous bigint,
	OUT move bigint,
	OUT type_move text,
	OUT peak bigint)
    RETURNS SETOF record
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

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
        SELECT
            w.*,
            lw.rank AS previous,
            CASE
                WHEN (lw.rank - w.rank) >= 0 THEN lw.rank - w.rank
                WHEN (lw.rank - w.rank) <= 0 THEN (lw.rank - w.rank) * -1
                ELSE lw.rank - w.rank
            END AS move,
            spfprid.found_song_rank AS peak,
            CASE
                WHEN lw.rank - w.rank > 0 THEN 'UP'
                WHEN lw.rank -w.rank < 0 THEN 'DOWN'
                WHEN lw.rank -w.rank = 0 THEN 'STOP'
                WHEN spfpr.found_song_rank > 0 THEN 'RE-ENTRY'
                WHEN spfpr.found_song_rank IS NULL AND lw.rank IS NULL THEN 'NEW'
                ELSE 'UNKNOWN'
            END AS type_move
        FROM spotify.sp_top_songs_week(start_date_week, end_date_week) w
        LEFT JOIN spotify.sp_top_songs_week(start_date_last_week, end_date_last_week) lw ON (w.song_id = lw.song_id)
        LEFT JOIN
            (SELECT found_song_id, MIN (found_rank) AS found_song_rank FROM spotify.sp_find_previous_ranks(end_date_week, FALSE) GROUP BY found_song_id) spfpr 
            ON (spfpr.found_song_id = w.song_id AND lw.rank IS NULL)
        LEFT JOIN
            (SELECT found_song_id, MIN (found_rank) AS found_song_rank FROM spotify.sp_find_previous_ranks(end_date_week, TRUE) GROUP BY found_song_id) spfprid 
            ON (spfprid.found_song_id = w.song_id)
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
       peak:= reg.peak;
       RETURN NEXT;
    END LOOP;
    RETURN;
END
$BODY$;