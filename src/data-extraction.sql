-- CALL core.sp_extraction_split_artist_names( '{}');
-- CALL core.sp_extraction_record_companies( '{}');
-- CALL core.sp_extraction_songs( '{}');
-- RAISE NOTICE 'Creating new song with track name %', new_song_id;

CREATE OR REPLACE PROCEDURE core.sp_extraction_split_artist_names(
OUT artist_names text[]
)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    is_new BOOLEAN;
BEGIN
    SELECT array(SELECT unnest(string_to_array(a.artist_names, ',')) INTO artist_names FROM core.tmp_weekly_tops a);
    FOR i IN array_lower(artist_names, 1)..array_upper(artist_names, 1) LOOP
        SELECT ((SELECT COUNT (id) FROM core.artists WHERE name = TRIM(artist_names[i])) = 0) INTO is_new FROM core.artists;
        IF is_new IS NULL OR is_new THEN
            INSERT INTO core.artists(name)
            VALUES (TRIM(artist_names[i]));
        END IF;
    END LOOP;
END;
$BODY$;


CREATE OR REPLACE PROCEDURE core.sp_extraction_record_companies(
    OUT record_company_names text[]
)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    is_new BOOLEAN;
BEGIN
    SELECT ARRAY (SELECT wt.source FROM core.tmp_weekly_tops wt) INTO record_company_names;
    FOR i IN array_lower(record_company_names, 1)..array_upper(record_company_names, 1) LOOP
        SELECT ((SELECT COUNT (id) FROM core.record_companies WHERE name = record_company_names[i]) = 0) INTO is_new FROM core.record_companies;
        IF is_new IS NULL OR is_new THEN
            INSERT INTO core.record_companies(name)
            VALUES (record_company_names[i]);
        END IF;
    END LOOP;
END;
$BODY$;


CREATE OR REPLACE PROCEDURE core.sp_extraction_songs(
    OUT songs_track_names text[]
)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    songs_ids INTEGER[];
    track_name VARCHAR(355);
    artist_names VARCHAR(355);
    source VARCHAR (255);
    streams INTEGER;
    list_artist_names TEXT[];
    new_song_id INTEGER;
BEGIN
    SELECT ARRAY (SELECT id FROM core.sp_tmp_weekly_tops) INTO songs_ids;
    FOR i IN array_lower(songs_ids, 1)..array_upper(songs_ids, 1) LOOP
        SELECT twt.track_name, twt.artist_names, twt.source, twt.streams INTO track_name, artist_names, source, streams  FROM core.tmp_weekly_tops AS twt WHERE twt.id = i;
        SELECT ARRAY(SELECT unnest(string_to_array(artist_names, ','))) INTO list_artist_names;
        INSERT INTO core.songs(track_name, record_company_id)
        VALUES (
            track_name,
            (SELECT id FROM core.record_companies WHERE name = source)
        )
        RETURNING id into new_song_id;
        FOR j IN array_lower(list_artist_names, 1)..array_upper(list_artist_names, 1) LOOP
        INSERT INTO core.song_artist(song_id, artist_id)
            VALUES (
                new_song_id,
                (SELECT id FROM core.artists WHERE name = TRIM(list_artist_names[j]))
            );
        END LOOP;
    END LOOP;
END;
$BODY$;

-- Modifica la columna start_date = menos 6 días que la columna end_date.
UPDATE spotify.weeks_songs
SET
    start_date = (
        end_date - CAST ('6 days' AS INTERVAL)
    );