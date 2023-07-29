CREATE DATABASE songsdb WITH ENCODING = 'UTF8';
CREATE SCHEMA tmp;
CREATE SCHEMA core;
CREATE SCHEMA spotify;
DROP SCHEMA public;

DROP TABLE core.tmp_weekly_tops;

CREATE TABLE core.tmp_weekly_tops (
    id SERIAL,
    rank INTEGER,
    uri VARCHAR(255),
    artist_names VARCHAR(355),
    track_name VARCHAR(355),
    source VARCHAR(255),
    peak_rank INTEGER,
    previous_rank INTEGER,
    weeks_on_chart INTEGER,
    streams INTEGER,
    end_date DATE,
    CONSTRAINT pk_weekly_tops PRIMARY KEY (id)
);


DROP TABLE core.artists cascade;

CREATE TABLE core.artists (
    id SERIAL,
    name VARCHAR(120),
    constraint pk_artists PRIMARY key (id),
    constraint uq_artists_name UNIQUE (name)
);


DROP TABLE core.record_companies CASCADE;

CREATE TABLE core.record_companies (
    id SERIAL,
    name VARCHAR(120),
    constraint pk_record_companies PRIMARY key (id),
    constraint uq_record_companies_name UNIQUE (name)
);


DROP TABLE core.songs CASCADE;

CREATE TABLE core.songs (
    id SERIAL,
    track_name VARCHAR(355),
    record_company_id INTEGER,
    constraint pk_songs PRIMARY key (id),
    constraint fk_songs_record_company_id FOREIGN KEY (record_company_id) REFERENCES core.record_companies(id) ON DELETE CASCADE
);


DROP TABLE core.song_artist;

CREATE TABLE core.song_artist (
    id SERIAL,
    song_id INTEGER,
    artist_id INTEGER,
    constraint pk_song_artist PRIMARY key (id),
    constraint fk_song_artist_song_id FOREIGN KEY (song_id) REFERENCES core.songs(id) ON DELETE cascade,
    constraint fk_song_artist_artist_id FOREIGN KEY (artist_id) REFERENCES core.artists(id) ON DELETE cascade
);


DROP TABLE spotify.weeks_songs;

CREATE TABLE spotify.weeks_songs (
    id SERIAL,
    song_id INTEGER,
    start_date DATE,
    end_date DATE,
    streams INTEGER,
    CONSTRAINT pk_weeks PRIMARY key (id),
    CONSTRAINT uq_weeks_combination UNIQUE (song_id, start_date, end_date),
    CONSTRAINT fk_weeks_song_id_ FOREIGN KEY (song_id) REFERENCES core.songs(id) ON DELETE CASCADE
);
