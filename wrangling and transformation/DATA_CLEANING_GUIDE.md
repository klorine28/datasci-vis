# Data Cleaning and Wrangling Guide

This document explains how raw data from multiple sources was cleaned, transformed, and prepared for analysis. The goal is to make the process understandable and reproducible.

---

## Overview

We work with three main data sources that need to be combined:

| Source | What it contains | Original format |
|--------|------------------|-----------------|
| **Billboard Hot 100** | Chart rankings, song titles, artists, lyrics (2000-2023) | CSV with Spotify audio features |
| **MusicoSet Artists** | Artist metadata, genre tags from Spotify | Tab-separated (TSV) |
| **MusicoSet Songs** | Song metadata, popularity scores | Tab-separated (TSV) |

The cleaning pipeline transforms these into analysis-ready datasets.

---

## Data Flow Diagram

```
Raw Data                    Cleaning                    Wrangling                   Analysis
─────────────────────────────────────────────────────────────────────────────────────────────

billboard_24years_          billboard_cleaning.ipynb    lexical_diversity_          lexical_analysis.ipynb
lyrics_spotify.csv    ───►  (normalize text)      ───►  transformation.ipynb  ───►  genre_analysis.ipynb
                            │                           (calculate metrics)
                            ▼
                       billboard_24years_lyrics_
                       spotify_bigquery.csv
                            │
                            │   BigQuery joins
                            ▼
musicoset_metadata/    musicoset_cleaning.ipynb        bigquery_analysis_
artists.csv       ───► (fix NA values)           ───►  queries.sql          ───►  Genre network data
songs.csv               │                              (genre co-occurrence)
                        ▼
                   musicoset_artists_cleaned.csv
                   musicoset_songs_cleaned.csv
```

---

## Step 1: Billboard Data Cleaning

**Notebook:** `cleaning/billboard_cleaning.ipynb`

### Problem
The original Billboard CSV contains lyrics with newline characters (`\n`) that break BigQuery imports and cause parsing issues.

### Solution
1. **Remove newlines** from all text fields
2. **Normalize whitespace** (collapse multiple spaces into one)
3. **Trim** leading/trailing whitespace

```r
# Key transformation
df <- df %>%
  mutate(across(where(is.character), function(x) {
    x <- str_replace_all(x, "\\n", " ")    # newlines → space
    x <- str_replace_all(x, "\\r", "")     # remove carriage returns
    x <- str_replace_all(x, "\\s+", " ")   # collapse whitespace
    str_trim(x)                             # trim edges
  }))
```

### Song Length Analysis
We identified songs with unusual lengths that might indicate data quality issues:

| Category | Word Count | Count | Percentage |
|----------|------------|-------|------------|
| Too Short | < 100 words | 26 | 0.8% |
| Normal | 100-600 words | 2,352 | 69.2% |
| Too Long | > 600 words | 1,019 | 30.0% |

**Why songs are too long:** Some entries contain multiple versions, remixes, or extended metadata in the lyrics field.

**Why songs are too short:** Instrumental tracks, or lyrics extraction failures.

### Output
- `data/cleaned/billboard_24years_lyrics_spotify_bigquery.csv` (3,397 songs)

---

## Step 2: MusicoSet Metadata Cleaning

**Notebook:** `cleaning/musicoset_cleaning.ipynb`

### Problem
MusicoSet uses tab-separated files with inconsistent NA representations:
- Empty strings `""`
- Literal dashes `"-"`
- Empty brackets `"[]"`

### Solution
Standardize all missing values to proper `NA`:

```r
fix_dash <- function(x) {
  if(is.character(x)) {
    x <- ifelse(str_detect(x, "^-$"), NA_character_, x)   # "-" → NA
    x <- ifelse(str_detect(x, "^\\[\\]$"), NA_character_, x)  # "[]" → NA
    x
  } else x
}
```

### Missing Data Summary

**Artists (11,430 rows):**
| Field | Missing | Percentage |
|-------|---------|------------|
| artist_type | 4,411 | 38.6% |
| main_genre | 3,062 | 26.8% |
| genres | 3,062 | 26.8% |
| image_url | 493 | 4.3% |
| followers | 2 | 0.02% |

**Songs (20,405 rows):** No missing data.

### Output
- `data/cleaned/musicoset_artists_cleaned.csv` (11,430 artists)
- `data/cleaned/musicoset_songs_cleaned.csv` (20,405 songs)

---

## Step 3: Missing Data Analysis

**Notebook:** `cleaning/missing_data_analysis.ipynb`

This notebook visualizes missing data patterns using `naniar` and `visdat` packages.

### Key Findings

**Billboard dataset (56% cells missing):**
- All Spotify audio features (danceability, energy, tempo, etc.) are missing together
- 85.7% of songs lack Spotify features
- Core fields (song, artist, year, lyrics) are complete

**Why Spotify features are missing:** The original Billboard scrape didn't successfully match all songs to Spotify's API. This is a known limitation - the lyrics analysis doesn't require these features.

### Visualizations Generated
- `outputs/exploratory/missingness_billboard_overview.png`
- `outputs/exploratory/missingness_artists_overview.png`
- `outputs/exploratory/missingness_spotify_by_year.png`

---

## Step 4: BigQuery Processing

**File:** `wrangling/bigquery_analysis_queries.sql`

BigQuery is used for heavy joins and genre network calculations that would be slow in R.

### Query 1: Join Billboard with Genres
Matches Billboard artists to MusicoSet genre data:

```sql
SELECT b.*, a.main_genre, a.genres AS sub_genres
FROM billboard AS b
LEFT JOIN musicoset_artists AS a
  ON TRIM(LOWER(b.band_singer)) = TRIM(LOWER(a.name))
```

**Match rate:** ~87% of Billboard songs get genre assignments.

### Query 2-3: Genre Co-Occurrence Network
Creates a genre-to-genre network based on artists who work in multiple genres.

**How it works:**
1. Extract all genre tags for each artist (stored as JSON arrays in MusicoSet)
2. Create pairs of genres that share the same artist
3. Count how many artists work in both genres = edge weight

**Matrix formula:** `G = A^T × A` where A is the artist-genre binary matrix.

### Output Files
- `data/sql_query_out/QUERY 1_ Billboard with Genre Data.csv`
- `data/sql_query_out/QUERY 2_ Genre Co-Occurrence Network.csv`
- `data/sql_query_out/QUERY 3-4_ Yearly networks (2000-2023)`

---

## Step 5: Lexical Diversity Transformation

**Notebook:** `wrangling/lexical_diversity_transformation.ipynb`

This is the main feature engineering step that calculates text metrics for each song.

### Genre Mapping
Maps ~1,560 Spotify micro-genres (like "dance pop", "atl hip hop") to 8 macro categories:

| Macro Genre | Examples | Pattern Used |
|-------------|----------|--------------|
| POP | dance pop, indie pop, teen pop | `pop(?!.*punk)` |
| HIP HOP | trap, drill, rap | `hip hop`, `\brap\b`, `trap` |
| COUNTRY | contemporary country, americana | `country`, `bluegrass` |
| ROCK | alternative, indie rock, punk | `rock(?!.*opera)`, `punk` |
| R&B | soul, neo soul, funk | `r&b`, `\bsoul\b` |
| ELECTRONIC | EDM, house, techno | `edm`, `house`, `techno` |
| LATIN | reggaeton, salsa, bachata | `latin`, `reggaeton` |
| OTHER | unclassified genres | fallback |

### Tokenization
Lyrics are split into individual words using `tidytext`:

```r
tokens <- df %>%
  unnest_tokens(word, lyrics) %>%
  mutate(
    word = str_replace_all(word, "\\d+", ""),      # remove numbers
    word = str_replace_all(word, "'s$", ""),       # remove possessives
    word = str_replace_all(word, "[^a-z]", "")     # keep only letters
  ) %>%
  filter(word != "")
```

### Metrics Calculated

#### Basic Lexical Metrics
| Metric | Formula | What it measures |
|--------|---------|------------------|
| **TTR** | unique words / total words | Vocabulary variety |
| **Lexical Density** | content words / total words | Meaningful content ratio |
| **Hapax Ratio** | words appearing once / unique words | Vocabulary breadth |

#### Content Words Definition
Content words = all words NOT in the stop word list.

The `tidytext::stop_words` dataset includes ~1,000 function words like: *the, a, is, are, was, have, do, will, would, to, of, in, for, on, with, at, by, as, into, through, etc.*

Everything else (nouns, verbs, adjectives, adverbs) counts as a content word.

#### Repetitiveness Metrics
| Metric | Formula | What it measures |
|--------|---------|------------------|
| **Compression Ratio** | gzip(lyrics) / original size | Algorithmic repetitiveness |
| **Repeated Line Ratio** | repeated lines / total lines | Chorus/hook repetition |

**Compression method:** gzip (DEFLATE algorithm via `memCompress()`). More repetitive lyrics compress better (lower ratio).

#### Vocabulary Uniqueness
| Metric | Formula | What it measures |
|--------|---------|------------------|
| **Rare Word Ratio** | words not in common 10k / unique words | Creative vocabulary |
| **Jaccard Genre** | intersection(song, genre vocab) / union | Genre typicality |
| **Jaccard Corpus** | intersection(song, all songs) / union | Mainstream vocabulary |

The common word list is loaded from `data/cleaned/common_english_words_10k.csv`.

### Feature Engineering

Additional derived features:

```r
df <- df %>%
  mutate(
    # Chart categories
    chart_tier = case_when(
      ranking <= 10 ~ "Top 10",
      ranking <= 25 ~ "11-25",
      ranking <= 50 ~ "26-50",
      ranking <= 75 ~ "51-75",
      ranking <= 100 ~ "76-100"
    ),

    # Time periods
    decade = case_when(
      year < 2010 ~ "2000s",
      year < 2020 ~ "2010s",
      TRUE ~ "2020s"
    ),

    # Length flags
    is_normal_length = total_words >= 100 & total_words <= 900,
    has_complete_data = !is.na(macro_genre) & is_normal_length & !is.na(ttr)
  )
```

### Output
- `data/cleaned/billboard_lexical_analysis_ready.csv` (3,427 songs, 2,822 with complete data)
- `data/cleaned/genre_macro_mapping.csv` (genre classification reference)

---

## Final Dataset Schema

The analysis-ready dataset (`billboard_lexical_analysis_ready.csv`) contains:

### Identification
| Column | Type | Description |
|--------|------|-------------|
| song | string | Song title |
| band_singer | string | Artist name |
| year | int | Chart year (2000-2023) |

### Genre
| Column | Type | Description |
|--------|------|-------------|
| main_genre | string | Spotify micro-genre |
| macro_genre | string | Mapped macro category (8 values) |

### Chart Performance
| Column | Type | Description |
|--------|------|-------------|
| ranking | int | Billboard position (1-100) |
| chart_tier | string | Position category |
| chart_score | int | Inverted ranking (101 - ranking) |
| is_top10 | bool | Whether song reached top 10 |

### Lexical Metrics
| Column | Type | Description |
|--------|------|-------------|
| total_words | int | Word count |
| unique_words | int | Distinct words |
| ttr | float | Type-token ratio |
| lexical_density | float | Content word ratio |
| rare_word_ratio | float | Non-common words ratio |
| compression_ratio | float | gzip compression ratio |
| hapax_ratio | float | Single-use word ratio |

### Similarity Metrics
| Column | Type | Description |
|--------|------|-------------|
| jaccard_genre | float | Similarity to genre vocabulary |
| jaccard_corpus | float | Similarity to all songs |
| jaccard_common | float | Similarity to common English |

### Flags
| Column | Type | Description |
|--------|------|-------------|
| has_complete_data | bool | TRUE if suitable for analysis |
| is_normal_length | bool | TRUE if 100-900 words |

---

## Data Quality Notes

### Known Limitations

1. **Genre coverage gap (post-2019):** MusicoSet was compiled in 2019, so newer artists (Ice Spice, NewJeans, etc.) are missing. Supplementary data from Spotify API was added to improve coverage.

2. **Artist-level genre assignment:** Genres are assigned per artist, not per song. A pop artist's country crossover song still gets labeled as pop.

3. **Lyrics quality varies:** Some songs have incomplete lyrics, repeated sections, or metadata mixed in.

4. **Duplicate rows:** Songs with multiple credited artists appear multiple times (e.g., "Smooth" by Santana and Rob Thomas).

### Filtering Recommendations

For most analyses, filter to complete data:

```r
df_analysis <- df %>%
  filter(has_complete_data == TRUE)
```

This gives 2,822 songs (82.3% of total) with:
- Valid genre assignment
- Normal song length (100-900 words)
- All lexical metrics calculated

---

## Reproducibility

To reproduce this pipeline:

1. **Run cleaning notebooks in order:**
   - `musicoset_cleaning.ipynb`
   - `billboard_cleaning.ipynb`
   - `missing_data_analysis.ipynb` (optional, for diagnostics)

2. **Run BigQuery queries** (if doing genre network analysis)

3. **Run transformation notebook:**
   - `lexical_diversity_transformation.ipynb`

4. **Run analysis notebooks:**
   - `lexical_analysis.ipynb`
   - `genre_analysis.ipynb`

### Required R Packages

```r
install.packages(c(
  "tidyverse",   # Core data manipulation
  "tidytext",    # Text tokenization
  "stringr",     # String operations
  "naniar",      # Missing data analysis
  "visdat",      # Data visualization
  "ggplot2",     # Plotting
  "scales",      # Axis formatting
  "viridis"      # Color palettes
))
```

---

## File Reference

### Input Files (Raw)
| File | Description |
|------|-------------|
| `data/billboard_24years_lyrics_spotify.csv` | Original Billboard data |
| `data/musicoset_metadata/artists.csv` | MusicoSet artist metadata |
| `data/musicoset_metadata/songs.csv` | MusicoSet song metadata |

### Intermediate Files (Cleaned)
| File | Description |
|------|-------------|
| `data/cleaned/billboard_24years_lyrics_spotify_bigquery.csv` | Normalized Billboard |
| `data/cleaned/musicoset_artists_cleaned.csv` | Cleaned artist metadata |
| `data/cleaned/musicoset_songs_cleaned.csv` | Cleaned song metadata |
| `data/cleaned/common_english_words_10k.csv` | Reference word list |

### Output Files (Analysis-Ready)
| File | Description |
|------|-------------|
| `data/cleaned/billboard_lexical_analysis_ready.csv` | Main analysis dataset |
| `data/cleaned/genre_macro_mapping.csv` | Genre classification map |
| `data/sql_query_out/*.csv` | BigQuery results for genre network |

### Summary Statistics
| File | Description |
|------|-------------|
| `outputs/lexical_analysis/lexical_analysis_summary_by_genre.csv` | Descriptive stats by genre |
| `outputs/lexical_analysis/lexical_analysis_correlations.csv` | Correlation results |
