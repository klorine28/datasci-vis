# Billboard Dataset Cleaning Documentation

## Overview

This document describes the R-based cleaning process for `billboard_24years_lyrics_spotify.csv` to produce BigQuery-compatible output.

**Input**: `data/billboard_24years_lyrics_spotify.csv` (245,854 lines with multi-line lyrics)
**Output**: `data/cleaned/billboard_24years_lyrics_spotify_bigquery.csv` (3,398 lines - single-line format)
**Tool**: R (tidyverse, readr, stringr) via Jupyter notebook

---

## Problem

The original Billboard dataset contains multi-line lyrics fields that cause issues for BigQuery upload:
- Literal newline characters (`\n`) within quoted fields spanning hundreds of lines
- Inconsistent whitespace and formatting
- While technically valid CSV (RFC 4180), BigQuery's parser struggles with multi-line fields

---

## Solution: R Cleaning Notebook

Created `billboard_cleaning.ipynb` - an R notebook that:

### 1. Loads Data
```r
df <- read_csv(input, na=c("", "NA"))
```
- Reads all 26 columns including Spotify features
- Properly handles multi-line quoted fields
- Treats empty strings and "NA" as missing values

### 2. Cleans Text Fields
```r
df2 <- df %>%
  mutate(across(where(is.character), function(x) {
    x <- str_replace_all(x, "\\n", " ")      # newlines → spaces
    x <- str_replace_all(x, "\\r", "")       # remove carriage returns
    x <- str_replace_all(x, "\\s+", " ")     # normalize spaces
    str_trim(x)                               # trim whitespace
  }))
```

**What it does**:
- Converts multi-line lyrics to single-line format
- Normalizes whitespace (multiple spaces → single space)
- Trims leading/trailing whitespace
- **Preserves all numeric columns unchanged** (Spotify features pass through)

### 3. Exports Clean Data
```r
write_csv(df2, output, na="", quote="all", eol="\n")
```
- Quotes all fields for BigQuery compatibility
- Unix-style line endings
- Empty string for NA values
- Each record = exactly one line

---

## Results

### Output Statistics
- **Rows**: 3,397 songs
- **Columns**: 26 (all preserved)
- **File size**: ~9.2 MB
- **Lines**: 3,398 (1 header + 3,397 data rows)
- **Format**: Single-line records, fully quoted

### Verification
✓ No multi-line fields remain
✓ Line count matches expected (data rows + 1 header)
✓ All 26 columns preserved
✓ Numeric Spotify features unchanged

---

## Missing Data Analysis

### Spotify Features (Columns 10-26)

**Missing**: 2,911 out of 3,397 songs (85.7%)
**Complete**: 486 songs (14.3%)

**Affected columns**:
- danceability, energy, key, loudness, mode
- speechiness, acousticness, instrumentalness
- liveness, valence, tempo
- type, id, track_href, analysis_url
- duration_ms, time_signature

### What This Tells Us

**Pattern**: Missing data is **not random**
- Songs without Spotify features likely:
  - Not available on Spotify platform
  - Failed API lookups during original data collection
  - Removed from Spotify since data collection
  - Licensing/availability issues

**Implications for Analysis**:
1. **Limited Spotify analysis**: Only 14.3% of songs have audio features
2. **Cannot impute reliably**: 85.7% missing is too high for statistical imputation
3. **Bias risk**: Songs with Spotify data may differ systematically from those without
4. **Temporal patterns**: Newer songs more likely to have Spotify data

**Recommendations**:
- Keep as NA (honest representation)
- Create indicator variable: `has_spotify_data` for filtering
- Consider re-fetching from Spotify API if needed
- Analyze completeness patterns (by year, artist, ranking)

### Core Data (Columns 1-9)

**Complete**: 100% (no missing values)

All songs have:
- ranking, song, band_singer, year
- songurl, titletext, url
- lyrics (cleaned to single-line format)
- uri

---

## Files Generated

### Notebooks
- `billboard_cleaning.ipynb` - R cleaning script with visualizations

### Data
- `data/cleaned/billboard_24years_lyrics_spotify_bigquery.csv` - cleaned output

### Documentation
- `BILLBOARD_CSV_CLEANING_DOCUMENTATION.md` (this file)

---

## Usage

### Running the Cleaning Notebook

1. Open Jupyter with R kernel:
   ```bash
   jupyter notebook
   ```

2. Navigate to `wrangling and transformation/cleaning/billboard_cleaning.ipynb`

3. Run all cells

4. Output written to `data/cleaned/billboard_24years_lyrics_spotify_bigquery.csv`

### BigQuery Upload

The cleaned file is ready for direct upload:

```bash
bq load \
  --source_format=CSV \
  --skip_leading_rows=1 \
  --allow_quoted_newlines=false \
  your_dataset.billboard_songs \
  data/cleaned/billboard_24years_lyrics_spotify_bigquery.csv
```

---

## Data Dictionary

| Column | Type | Missing | Description |
|--------|------|---------|-------------|
| ranking | INTEGER | 0% | Billboard chart position (1-100) |
| song | STRING | 0% | Song title |
| band_singer | STRING | 0% | Artist/band name |
| songurl | STRING | 0% | Wikipedia URL for song |
| titletext | STRING | 0% | Song title (duplicate) |
| url | STRING | 0% | Wikipedia URL for artist |
| year | INTEGER | 0% | Chart year (2000-2023) |
| lyrics | STRING | 0% | Song lyrics (single-line format) |
| uri | STRING | 0% | Spotify URI |
| danceability | FLOAT | 85.7% | Spotify danceability (0-1) |
| energy | FLOAT | 85.7% | Spotify energy (0-1) |
| key | FLOAT | 85.7% | Musical key (0-11) |
| loudness | FLOAT | 85.7% | Loudness in dB |
| mode | FLOAT | 85.7% | Major (1) or minor (0) |
| speechiness | FLOAT | 85.7% | Speechiness (0-1) |
| acousticness | FLOAT | 85.7% | Acousticness (0-1) |
| instrumentalness | FLOAT | 85.7% | Instrumentalness (0-1) |
| liveness | FLOAT | 85.7% | Liveness (0-1) |
| valence | FLOAT | 85.7% | Musical positivity (0-1) |
| tempo | FLOAT | 85.7% | BPM |
| type | STRING | 85.7% | Object type ("audio_features") |
| id | STRING | 85.7% | Spotify track ID |
| track_href | STRING | 85.7% | Spotify API endpoint |
| analysis_url | STRING | 85.7% | Audio analysis endpoint |
| duration_ms | FLOAT | 85.7% | Track duration (milliseconds) |
| time_signature | FLOAT | 85.7% | Time signature |

---

## Key Differences from Original

| Aspect | Original | Cleaned |
|--------|----------|---------|
| Lines | 245,854 | 3,398 |
| Multi-line lyrics | Yes | No |
| Whitespace | Inconsistent | Normalized |
| Quoting | Mixed | All fields quoted |
| BigQuery compatible | No | Yes |
| Data loss | N/A | None (all data preserved) |

---

*Last updated: 2025-11-16*
*Cleaning method: R (tidyverse)*
*Status: Production ready*
