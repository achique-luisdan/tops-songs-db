
-- Vista: Consulta intervalos de semanas (start_date_week, end_date_week)
--SELECT * FROM spotify.v_intervals_weeks;

CREATE VIEW spotify.v_intervals_weeks AS
    SELECT
        TO_CHAR(end_date_week - CAST ('6 days' AS INTERVAL),  'YYYY-MM-DD') AS start_date_week,
        TO_CHAR(end_date_week, 'YYYY-MM-DD') AS end_date_week
    FROM
        GENERATE_SERIES('2022-01-06'::DATE, NOW(), '7 days') AS end_date_week;