-- FUNCTION: spotify.sp_find_previous_ranks(date, boolean)

-- DROP FUNCTION IF EXISTS spotify.sp_find_previous_ranks(date, boolean);

CREATE OR REPLACE FUNCTION spotify.sp_find_previous_ranks(
	find_end_date_week date,
	include_week boolean,
	OUT found_song_id bigint,
	OUT found_rank bigint)
    RETURNS SETOF record 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
DECLARE
previous_weeks TEXT[];
weekly_rank TEXT[];
rank_previous_weeks TEXT[];
BEGIN
    IF include_week = TRUE THEN
        SELECT ARRAY_AGG (ARRAY [viw.start_date_week, viw.end_date_week]) 
        INTO previous_weeks
        FROM spotify.v_intervals_weeks AS viw
        WHERE viw.end_date_week::DATE <= find_end_date_week;
    ELSE
        SELECT ARRAY_AGG (ARRAY [viw.start_date_week, viw.end_date_week]) 
        INTO previous_weeks
        FROM spotify.v_intervals_weeks AS viw
        WHERE viw.end_date_week::DATE < find_end_date_week;
    END IF; 
    FOR i IN array_lower(previous_weeks, 1)..array_upper(previous_weeks, 1) LOOP
        SELECT ARRAY_AGG ( ARRAY [song_id::TEXT, rank::TEXT, previous_weeks[i][1], previous_weeks[i][2]]) into weekly_rank FROM spotify.sp_top_songs_week(previous_weeks[i][1]::DATE, previous_weeks[i][2]::DATE);
        SELECT array_cat (rank_previous_weeks, weekly_rank) INTO rank_previous_weeks;  
    END LOOP;
    FOR i IN array_lower(rank_previous_weeks, 1)..array_upper(rank_previous_weeks, 1) LOOP
        found_song_id := rank_previous_weeks[i][1];
        found_rank := rank_previous_weeks[i][2];
        RETURN NEXT; 
    END LOOP;
END;
$BODY$;

ALTER FUNCTION spotify.sp_find_previous_ranks(date, boolean)
    OWNER TO postgres;
