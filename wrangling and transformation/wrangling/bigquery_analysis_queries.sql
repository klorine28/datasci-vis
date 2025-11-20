-- ============================================================================
-- BigQuery Analysis Queries for Billboard & MusicoSet Data
-- ============================================================================
-- Project: Billboard Lyrics Analysis (2000-2023)
-- Author: Lorenzo Garduño
-- Purpose: Genre co-occurrence network analysis queries
-- Date: 2025-01-20 (Updated with correct approach: G = A^T × A)
-- ============================================================================

-- CONFIGURATION
-- Replace these placeholders with your actual BigQuery project and dataset names:
-- - your-project-id
-- - your-dataset

-- ============================================================================
-- QUERY 1: Billboard with Genre Data (Cleaned)
-- ============================================================================
-- Purpose: Append genre information from artist data to billboard dataset
--          and remove Spotify audio features (danceability to time_signature)
-- Output: Cleaned billboard dataset with genre data, ready for analysis
-- ============================================================================

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

-- Notes:
-- - Uses LEFT JOIN to preserve all billboard records
-- - TRIM and LOWER for case-insensitive matching
-- - Drops columns: danceability, energy, key, loudness, mode, speechiness,
--   acousticness, instrumentalness, liveness, valence, tempo, type, id,
--   track_href, analysis_url, duration_ms, time_signature


-- ============================================================================
-- QUERY 2: Genre Co-Occurrence Network (All Time)
-- ============================================================================
-- Purpose: Create genre × genre co-occurrence matrix using G = A^T × A
--          Shows how many artists have BOTH genres in their profile
-- Output: genre_1, genre_2, co_occurrence_count
-- Use case: Network graph with genres as nodes, co-occurrence as edges
-- Matrix: G = A^T × A (see genre_collaboration_network_documentation.md)
-- ============================================================================

-- Step 1: Extract artist-genre relationships (Matrix A)
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

-- Step 2: Self-join to create genre pairs (implements A^T × A)
-- For each artist, create all pairs of their genres
genre_pairs AS (
  SELECT
    ag1.genre AS genre_1,
    ag2.genre AS genre_2,
    ag1.artist
  FROM artist_genres ag1
  INNER JOIN artist_genres ag2
    ON ag1.artist = ag2.artist
  WHERE ag1.genre <= ag2.genre  -- Avoid duplicate pairs, include diagonal
)

-- Step 3: Count co-occurrences (result is Matrix G)
SELECT
  genre_1,
  genre_2,
  COUNT(DISTINCT artist) AS co_occurrence_count
FROM genre_pairs
GROUP BY genre_1, genre_2
ORDER BY co_occurrence_count DESC;

-- Notes:
-- - Output is in "edge list" format for network visualization
-- - Each row represents an edge in the genre co-occurrence network
-- - Weight = number of artists who have BOTH genres
-- - Includes diagonal (genre_1 = genre_2) showing total artists per genre
-- - Can be visualized in NetworkX, Gephi, or D3.js


-- ============================================================================
-- QUERY 3: Genre Co-Occurrence Network (Yearly Evolution 2000-2023)
-- ============================================================================
-- Purpose: Create 23 separate genre networks, one per year
--          Track how genre co-occurrence evolves from 2000 to 2023
-- Output: year, genre_1, genre_2, co_occurrence_count
-- Use case: Temporal network analysis, animated visualizations
-- ============================================================================

-- Step 1: Get artists who appeared on Billboard each year
WITH artists_per_year AS (
  SELECT DISTINCT
    band_singer AS artist,
    year
  FROM `your-project-id.your-dataset.billboard_24years_lyrics_spotify_bigquery`
),

-- Step 2: Extract genre data for all artists
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

-- Step 3: Join to get genres for artists active each year
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

-- Step 4: Create genre pairs per year (implements A^T × A per year)
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

-- Step 5: Count co-occurrences per year
SELECT
  year,
  genre_1,
  genre_2,
  COUNT(DISTINCT artist) AS co_occurrence_count
FROM genre_pairs_by_year
GROUP BY year, genre_1, genre_2
ORDER BY year, co_occurrence_count DESC;

-- Notes:
-- - Creates 23 separate networks (2000-2023)
-- - Each year shows genres of artists on Billboard that year
-- - Export and filter by year for individual network graphs
-- - Useful for tracking genre emergence, fusion, and decline


-- ============================================================================
-- QUERY 4: Export Individual Year Networks (Example for 2023)
-- ============================================================================
-- Purpose: Export a single year's network for focused analysis
-- Output: genre_1, genre_2, co_occurrence_count for specified year
-- ============================================================================

WITH artists_per_year AS (
  SELECT DISTINCT
    band_singer AS artist,
    year
  FROM `your-project-id.your-dataset.billboard_24years_lyrics_spotify_bigquery`
  WHERE year = 2023  -- Change year as needed
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

-- Notes:
-- - Modify WHERE year = 2023 to export different years
-- - Save each year as separate CSV for visualization
-- - Recommended: genre_network_2000.csv, genre_network_2001.csv, etc.


-- ============================================================================
-- QUERY 5: Genre to Main Genre Mapping (For Node Coloring)
-- ============================================================================
-- Purpose: Map each sub-genre to its primary main genre for visualization coloring
-- Output: sub_genre, primary_main_genre, artist_count
-- Use case: Assign colors to nodes based on main genre family
-- ============================================================================

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

-- For each sub-genre, find the most common main genre
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

-- Get the primary main genre for each sub-genre
SELECT
  sub_genre,
  main_genre AS primary_main_genre,
  artist_count
FROM ranked_mappings
WHERE rank = 1
ORDER BY sub_genre;

-- Notes:
-- - Assigns each sub-genre to its most common main genre
-- - Use this to color nodes in visualization tools
-- - Recommended color palette in documentation
-- - Export as genre_colors.csv


-- ============================================================================
-- QUERY 6: Genre Statistics by Year
-- ============================================================================
-- Purpose: Track genre popularity and diversity over time
-- Output: year, genre, artist_count, total_appearances
-- Use case: Understand which genres dominated each year
-- ============================================================================

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

-- Notes:
-- - artist_count: unique artists with that genre per year
-- - total_appearances: total song appearances (some artists have multiple songs)
-- - Shows genre representation on Billboard charts


-- ============================================================================
-- QUERY 7: Network Metrics - Node Degree
-- ============================================================================
-- Purpose: Calculate degree centrality for each genre (how many other genres it connects to)
-- Output: genre, degree, total_connections
-- Use case: Identify "hub" genres that connect to many others
-- ============================================================================

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
  WHERE ag1.genre < ag2.genre  -- Exclude self-loops and duplicates
),

genre_connections AS (
  SELECT
    genre_1,
    genre_2,
    COUNT(DISTINCT artist) AS connection_weight
  FROM genre_pairs
  GROUP BY genre_1, genre_2
)

-- Calculate degree (number of connections) per genre
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

-- Notes:
-- - degree: number of unique genres this genre co-occurs with
-- - total_connections: sum of all co-occurrence counts
-- - High degree = "hub" genre that connects to many others (e.g., "pop")


-- ============================================================================
-- QUERY 8: Emerging Genre Pairs (Comparing Two Time Periods)
-- ============================================================================
-- Purpose: Identify genre pairs that became more connected over time
-- Output: genre_1, genre_2, early_count, late_count, growth
-- Use case: Detect genre fusion trends
-- ============================================================================

WITH artists_early AS (
  SELECT DISTINCT band_singer AS artist
  FROM `your-project-id.your-dataset.billboard_24years_lyrics_spotify_bigquery`
  WHERE year BETWEEN 2000 AND 2011  -- First half
),

artists_late AS (
  SELECT DISTINCT band_singer AS artist
  FROM `your-project-id.your-dataset.billboard_24years_lyrics_spotify_bigquery`
  WHERE year BETWEEN 2012 AND 2023  -- Second half
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

-- Early period network
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

-- Late period network
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

-- Compare periods
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
WHERE COALESCE(l.late_count, 0) - COALESCE(e.early_count, 0) > 0  -- Only growing pairs
ORDER BY absolute_growth DESC;

-- Notes:
-- - Identifies genre pairs that became more common over time
-- - absolute_growth: raw increase in artist count
-- - percent_growth: percentage increase
-- - New pairs (early_count = 0) show emerging genre combinations


-- ============================================================================
-- END OF QUERIES
-- ============================================================================

-- For detailed documentation on the genre co-occurrence network methodology,
-- see: genre_collaboration_network_documentation.md

-- Key Concepts:
-- - G = A^T × A (genre co-occurrence, NOT collaboration)
-- - A = Artist-Genre matrix (binary)
-- - G = Genre-Genre co-occurrence matrix (weighted by artist count)
-- - No collaboration matrix (C) is needed
-- - Edges represent multi-genre artists, not cross-genre collaborations

-- Query execution tips:
-- 1. Replace all instances of 'your-project-id' and 'your-dataset'
-- 2. Test queries on small subsets first (e.g., WHERE year = 2023)
-- 3. Use BigQuery's query validator before running expensive queries
-- 4. Export results to CSV for visualization in Gephi/NetworkX/D3.js
-- 5. For yearly evolution, export one CSV per year (2000-2023)

-- Visualization workflow:
-- 1. Run QUERY 3 to get all yearly networks
-- 2. Run QUERY 5 to get genre-to-color mapping
-- 3. Export 23 separate CSVs (one per year)
-- 4. Load into Gephi/NetworkX for visualization
-- 5. Apply colors based on main genre
-- 6. Create animated visualization showing evolution

-- Recommended file naming:
-- - genre_network_2000.csv, genre_network_2001.csv, ..., genre_network_2023.csv
-- - genre_colors.csv (for node coloring)
-- - genre_stats_by_year.csv (for context)
