SELECT * FROM spotify.v_intervals_weeks;

CALL spotify.sp_find_week_by_date('2022-06-07', NULL, NULL);

SELECT * FROM spotify.sp_top_songs_week('2022-06-03', '2022-06-09');

