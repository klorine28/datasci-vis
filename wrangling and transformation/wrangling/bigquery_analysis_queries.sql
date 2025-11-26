-- BigQuery Analysis Queries for Billboard & MusicoSet Data
-- Genre co-occurrence network analysis
-- Replace 'your-project-id' and 'your-dataset' with actual values

-- ============================================================================
-- QUERY 1: Billboard with Genre Data
-- ============================================================================
-- Joins Billboard songs with MusicoSet artist genres
-- Drops Spotify audio feature columns

SELECT
    b.ranking,
    b.song,
    b.band_singer,
    b.songurl,
    b.titletext,
    b.url,
    b.year,
    b.lyrics,
    b.uri,
    a.main_genre,
    a.genres AS sub_genres
FROM `your-project-id.your-dataset.billboard_24years_lyrics_spotify_bigquery` AS b
LEFT JOIN `your-project-id.your-dataset.musicoset_artists_cleaned` AS a
    ON TRIM(LOWER(b.band_singer)) = TRIM(LOWER(a.name));


-- ============================================================================
-- QUERY 2: Genre Co-Occurrence Network (All Time)
-- ============================================================================
-- Creates genre × genre matrix: G = A^T × A
-- Output: edge list with co-occurrence counts

WITH artist_genres AS (
  SELECT
    a.name AS artist,
    genre,
    a.main_genre
  FROM `your-project-id.your-dataset.musicoset_artists_cleaned` a
  CROSS JOIN UNNEST(
    ARRAY_CONCAT(
      REGEXP_EXTRACT_ALL(a.genres, r"'([^']+)'"),
      [a.main_genre]
    )
  ) AS genre
),

genre_pairs AS (
  SELECT
    ag1.genre AS genre_1,
    ag2.genre AS genre_2,
    ag1.artist
  FROM artist_genres ag1
  INNER JOIN artist_genres ag2
    ON ag1.artist = ag2.artist
  WHERE ag1.genre <= ag2.genre
)

SELECT
  genre_1,
  genre_2,
  COUNT(DISTINCT artist) AS co_occurrence_count
FROM genre_pairs
GROUP BY genre_1, genre_2
ORDER BY co_occurrence_count DESC;


-- ============================================================================
-- QUERY 3: Genre Co-Occurrence Network (Yearly 2000-2023)
-- ============================================================================
-- Creates 23 separate networks filtered by Billboard chart year

WITH artists_per_year AS (
  SELECT DISTINCT
    band_singer AS artist,
    year
  FROM `your-project-id.your-dataset.billboard_24years_lyrics_spotify_bigquery`
),

artist_genres AS (
  SELECT
    a.name AS artist,
    genre,
    a.main_genre
  FROM `your-project-id.your-dataset.musicoset_artists_cleaned` a
  CROSS JOIN UNNEST(
    ARRAY_CONCAT(
      REGEXP_EXTRACT_ALL(a.genres, r"'([^']+)'"),
      [a.main_genre]
    )
  ) AS genre
),

artist_genres_by_year AS (
  SELECT
    y.year,
    ag.artist,
    ag.genre,
    ag.main_genre
  FROM artists_per_year y
  INNER JOIN artist_genres ag
    ON TRIM(LOWER(y.artist)) = TRIM(LOWER(ag.artist))
),

genre_pairs_by_year AS (
  SELECT
    ag1.year,
    ag1.genre AS genre_1,
    ag2.genre AS genre_2,
    ag1.artist
  FROM artist_genres_by_year ag1
  INNER JOIN artist_genres_by_year ag2
    ON ag1.artist = ag2.artist
    AND ag1.year = ag2.year
  WHERE ag1.genre <= ag2.genre
)

SELECT
  year,
  genre_1,
  genre_2,
  COUNT(DISTINCT artist) AS co_occurrence_count
FROM genre_pairs_by_year
GROUP BY year, genre_1, genre_2
ORDER BY year, co_occurrence_count DESC;


-- ============================================================================
-- QUERY 4: Single Year Network (change year as needed)
-- ============================================================================

WITH artists_per_year AS (
  SELECT DISTINCT
    band_singer AS artist,
    year
  FROM `your-project-id.your-dataset.billboard_24years_lyrics_spotify_bigquery`
  WHERE year = 2023
),

artist_genres AS (
  SELECT
    a.name AS artist,
    genre,
    a.main_genre
  FROM `your-project-id.your-dataset.musicoset_artists_cleaned` a
  CROSS JOIN UNNEST(
    ARRAY_CONCAT(
      REGEXP_EXTRACT_ALL(a.genres, r"'([^']+)'"),
      [a.main_genre]
    )
  ) AS genre
),

artist_genres_by_year AS (
  SELECT
    ag.artist,
    ag.genre,
    ag.main_genre
  FROM artists_per_year y
  INNER JOIN artist_genres ag
    ON TRIM(LOWER(y.artist)) = TRIM(LOWER(ag.artist))
),

genre_pairs AS (
  SELECT
    ag1.genre AS genre_1,
    ag2.genre AS genre_2,
    ag1.artist
  FROM artist_genres_by_year ag1
  INNER JOIN artist_genres_by_year ag2
    ON ag1.artist = ag2.artist
  WHERE ag1.genre <= ag2.genre
)

SELECT
  genre_1,
  genre_2,
  COUNT(DISTINCT artist) AS co_occurrence_count
FROM genre_pairs
GROUP BY genre_1, genre_2
ORDER BY co_occurrence_count DESC;


-- ============================================================================
-- QUERY 5: Genre to Main Genre Mapping
-- ============================================================================
-- Maps each sub-genre to its most common main genre (for node coloring)

WITH artist_genres AS (
  SELECT
    a.name AS artist,
    a.main_genre,
    genre AS sub_genre
  FROM `your-project-id.your-dataset.musicoset_artists_cleaned` a
  CROSS JOIN UNNEST(
    ARRAY_CONCAT(
      REGEXP_EXTRACT_ALL(a.genres, r"'([^']+)'"),
      [a.main_genre]
    )
  ) AS genre
),

genre_main_genre_mapping AS (
  SELECT
    sub_genre,
    main_genre,
    COUNT(DISTINCT artist) AS artist_count
  FROM artist_genres
  GROUP BY sub_genre, main_genre
),

ranked_mappings AS (
  SELECT
    sub_genre,
    main_genre,
    artist_count,
    ROW_NUMBER() OVER (PARTITION BY sub_genre ORDER BY artist_count DESC) AS rank
  FROM genre_main_genre_mapping
)

SELECT
  sub_genre,
  main_genre AS primary_main_genre,
  artist_count
FROM ranked_mappings
WHERE rank = 1
ORDER BY sub_genre;


-- ============================================================================
-- QUERY 6: Genre Statistics by Year
-- ============================================================================
-- Tracks genre counts per year

WITH artists_per_year AS (
  SELECT
    band_singer AS artist,
    year,
    COUNT(*) AS song_count
  FROM `your-project-id.your-dataset.billboard_24years_lyrics_spotify_bigquery`
  GROUP BY band_singer, year
),

artist_genres AS (
  SELECT
    a.name AS artist,
    genre,
    a.main_genre
  FROM `your-project-id.your-dataset.musicoset_artists_cleaned` a
  CROSS JOIN UNNEST(
    ARRAY_CONCAT(
      REGEXP_EXTRACT_ALL(a.genres, r"'([^']+)'"),
      [a.main_genre]
    )
  ) AS genre
),

genre_by_year AS (
  SELECT
    y.year,
    g.genre,
    y.artist,
    y.song_count
  FROM artists_per_year y
  INNER JOIN artist_genres g
    ON TRIM(LOWER(y.artist)) = TRIM(LOWER(g.artist))
)

SELECT
  year,
  genre,
  COUNT(DISTINCT artist) AS artist_count,
  SUM(song_count) AS total_appearances
FROM genre_by_year
GROUP BY year, genre
ORDER BY year DESC, artist_count DESC;


-- ============================================================================
-- QUERY 7: Network Metrics - Node Degree
-- ============================================================================
-- Calculates degree centrality per genre

WITH artist_genres AS (
  SELECT
    a.name AS artist,
    genre
  FROM `your-project-id.your-dataset.musicoset_artists_cleaned` a
  CROSS JOIN UNNEST(
    ARRAY_CONCAT(
      REGEXP_EXTRACT_ALL(a.genres, r"'([^']+)'"),
      [a.main_genre]
    )
  ) AS genre
),

genre_pairs AS (
  SELECT
    ag1.genre AS genre_1,
    ag2.genre AS genre_2,
    ag1.artist
  FROM artist_genres ag1
  INNER JOIN artist_genres ag2
    ON ag1.artist = ag2.artist
  WHERE ag1.genre < ag2.genre
),

genre_connections AS (
  SELECT
    genre_1,
    genre_2,
    COUNT(DISTINCT artist) AS connection_weight
  FROM genre_pairs
  GROUP BY genre_1, genre_2
)

SELECT
  genre,
  COUNT(DISTINCT connected_genre) AS degree,
  SUM(connection_weight) AS total_connections
FROM (
  SELECT genre_1 AS genre, genre_2 AS connected_genre, connection_weight FROM genre_connections
  UNION ALL
  SELECT genre_2 AS genre, genre_1 AS connected_genre, connection_weight FROM genre_connections
)
GROUP BY genre
ORDER BY degree DESC, total_connections DESC;


-- ============================================================================
-- QUERY 8: Emerging Genre Pairs (2000-2011 vs 2012-2023)
-- ============================================================================
-- Compares early and late period co-occurrence counts

WITH artists_early AS (
  SELECT DISTINCT band_singer AS artist
  FROM `your-project-id.your-dataset.billboard_24years_lyrics_spotify_bigquery`
  WHERE year BETWEEN 2000 AND 2011
),

artists_late AS (
  SELECT DISTINCT band_singer AS artist
  FROM `your-project-id.your-dataset.billboard_24years_lyrics_spotify_bigquery`
  WHERE year BETWEEN 2012 AND 2023
),

artist_genres AS (
  SELECT
    a.name AS artist,
    genre
  FROM `your-project-id.your-dataset.musicoset_artists_cleaned` a
  CROSS JOIN UNNEST(
    ARRAY_CONCAT(
      REGEXP_EXTRACT_ALL(a.genres, r"'([^']+)'"),
      [a.main_genre]
    )
  ) AS genre
),

early_pairs AS (
  SELECT
    ag1.genre AS genre_1,
    ag2.genre AS genre_2,
    COUNT(DISTINCT ag1.artist) AS early_count
  FROM artist_genres ag1
  INNER JOIN artist_genres ag2
    ON ag1.artist = ag2.artist
  INNER JOIN artists_early e
    ON TRIM(LOWER(ag1.artist)) = TRIM(LOWER(e.artist))
  WHERE ag1.genre < ag2.genre
  GROUP BY genre_1, genre_2
),

late_pairs AS (
  SELECT
    ag1.genre AS genre_1,
    ag2.genre AS genre_2,
    COUNT(DISTINCT ag1.artist) AS late_count
  FROM artist_genres ag1
  INNER JOIN artist_genres ag2
    ON ag1.artist = ag2.artist
  INNER JOIN artists_late l
    ON TRIM(LOWER(ag1.artist)) = TRIM(LOWER(l.artist))
  WHERE ag1.genre < ag2.genre
  GROUP BY genre_1, genre_2
)

SELECT
  COALESCE(e.genre_1, l.genre_1) AS genre_1,
  COALESCE(e.genre_2, l.genre_2) AS genre_2,
  COALESCE(e.early_count, 0) AS early_count,
  COALESCE(l.late_count, 0) AS late_count,
  COALESCE(l.late_count, 0) - COALESCE(e.early_count, 0) AS absolute_growth,
  CASE
    WHEN e.early_count IS NULL OR e.early_count = 0 THEN NULL
    ELSE ROUND((COALESCE(l.late_count, 0) - e.early_count) / e.early_count * 100, 2)
  END AS percent_growth
FROM early_pairs e
FULL OUTER JOIN late_pairs l
  ON e.genre_1 = l.genre_1 AND e.genre_2 = l.genre_2
WHERE COALESCE(l.late_count, 0) - COALESCE(e.early_count, 0) > 0
ORDER BY absolute_growth DESC;


-- ============================================================================
-- Notes
-- ============================================================================
-- Matrix formula: G = A^T × A (genre co-occurrence via artist-genre matrix)
-- See genre_collaboration_network_documentation.md for methodology
-- Export results to CSV for visualization in Gephi/NetworkX
