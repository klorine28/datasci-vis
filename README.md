# Billboard Lyrics Analysis (2000-2023)

Data science and visualization project analyzing Billboard Top 100 songs over 24 years, with a primary focus on lyrical characteristics and secondary exploration of musical features.

## Overview

This project provides an exploratory overview of Billboard hit songs with a **lyrical lean**, as lyrical analysis was the main area of interest.

**Research Question:** How does lexical diversity in song lyrics relate to chart performance and vary across genres in Billboard Hot 100 songs (2000-2023)?

The analysis includes:
- Lexical diversity and complexity metrics (Type-Token Ratio, lexical density, hapax legomena)
- Word frequency analysis and vocabulary richness
- Relationship between chart performance and lyrical characteristics
- Cross-genre comparisons (Pop, Hip Hop, Country, Rock, R&B, Electronic)
- Temporal trends in lyrics complexity (2000-2023)
- Year-by-year and genre-normalized diversity metrics
- Supplementary audio features analysis (Spotify data)
- **Network analysis** of genre collaborations and artist relationships (BigQuery)

## Dataset

- **Billboard Top 100 songs** (2000-2023): 3,397 songs (basic) / 3,649 songs (improved with MusicoSet)
- **Complete lyrics data**: 100% coverage
- **Lyrics quality**: 80.1% normal-length after MusicoSet improvement (up from 69.2%)
- **Spotify audio features**: ~14% coverage (486 songs)

### Data Cleaning & Quality

R-based cleaning pipeline produces BigQuery-ready datasets:

**Billboard Dataset (Two-Stage Cleaning):**

*Stage 1: Basic Text Cleaning*
- Converted multi-line lyrics to single-line format
- Normalized whitespace and removed newlines/carriage returns
- Preserved all 26 columns including Spotify features
- Output: `billboard_24years_lyrics_spotify_bigquery.csv` (3,398 lines: 1 header + 3,397 songs)

*Stage 2: Lyrics Quality Improvement*
- Analyzed word counts: identified 1,045 outliers (too short <100 words or too long >600 words)
- Matched outliers with MusicoSet dataset using **both song name and artist** for accuracy
- Replaced 564 problematic lyrics (16.6% of dataset) with cleaner MusicoSet versions
- Quality improvements:
  - Too-short songs: 26 → 3 (88% reduction)
  - Too-long songs: 1,019 → 724 (29% reduction)
  - Normal-length songs: 69.2% → 80.1% coverage
- Output: `billboard_24years_lyrics_spotify_bigquery_improved.csv` (3,649 songs with improved lyrics)

*Matching Strategy:*
- Normalized song titles and artist names (lowercase, trimmed)
- Inner join on both `song_clean` AND `artist_clean` to prevent mismatches
- Filtered to only accept MusicoSet versions with normal length (100-600 words)
- Prevents false matches (e.g., "Beautiful" by different artists)

**MusicoSet Metadata:**
- Converted standalone `-` and empty `[]` to proper NA values
- Tab-separated format cleaned to standard CSV
- Trimmed whitespace from all text fields
- Artists: 11,518 records, Songs: 20,405 records

**Missing Data:**
- Spotify features: 85.7% missing (2,911/3,397 songs)
- Artist genres: ~27% missing
- Core data (lyrics, rankings, years): 100% complete

**Notebooks:**

*Data Cleaning:*
- `wrangling and transformation/cleaning/billboard_cleaning.ipynb` - Two-stage Billboard cleaning pipeline:
  - Stage 1: Text normalization (newlines, whitespace)
  - Stage 2: Lyrics quality improvement via MusicoSet matching
  - Produces both basic and improved output files
  - Includes word count analysis and before/after visualizations
- `wrangling and transformation/cleaning/musicoset_cleaning.ipynb` - MusicoSet metadata cleaning
- `wrangling and transformation/cleaning/missing_data_analysis.ipynb` - Missing data visualization

*Data Transformation:*
- `wrangling and transformation/wrangling/lexical_diversity_transformation.ipynb` - Lexical analysis transformation pipeline:
  - Joins Billboard with MusicoSet genre data (85.6% coverage)
  - Maps 159 micro-genres to 6 macro-genres (POP, HIP HOP, COUNTRY, ROCK, R&B, ELECTRONIC)
  - Tokenizes lyrics and calculates lexical diversity metrics (TTR, lexical density, hapax ratio)
  - Creates chart performance and temporal features
  - Generates genre and year-normalized scores
  - Output: `billboard_lexical_analysis_ready.csv` (analysis-ready dataset)

**Documentation:**
- `wrangling and transformation/cleaning/BILLBOARD_CSV_CLEANING_DOCUMENTATION.md` - Complete cleaning methodology

### Data Sources

1. **Musicoset Dataset** - [DSW 2019 Project](https://marianaossilva.github.io/DSW2019)
   - Artist and song metadata
   - Additional song features

2. **Billboard Hot 100 (2000-2023) with Spotify Features** - [Kaggle Dataset](https://www.kaggle.com/datasets/suparnabiswas/billboard-hot-1002000-2023-data-with-features/code)
   - Billboard chart data with rankings
   - Lyrics and Spotify audio features

## Notebooks

Located in the `exploration/` folder:

### `exploration/data_exploration_focused.ipynb`
Main analysis notebook with:
- Word frequency and lexical metrics
- Lexical density analysis
- Chart position analysis (groups of 5 songs)
- Temporal trends and statistical tests
- Complete year-by-year rankings
- Extreme examples (most/least complex songs)

### `exploration/data_exploration_R.ipynb`
R-based exploratory analysis with:
- Audio feature correlations and relationships
- Audio features vs chart performance
- Bigrams and phrase analysis
- Energy-valence emotional quadrant analysis
- Lexical diversity and repetition analysis

## Key Findings

- Lexical diversity shows significant temporal trends
- Top-charting songs show measurably different lyrical complexity
- Decade-by-decade analysis reveals evolving patterns
- Year-over-year rankings provide granular insights

## Network Analysis & BigQuery Queries

### Genre Co-Occurrence Network

This project includes advanced network analysis using BigQuery to understand how music genres are related through multi-genre artists.

**Key Components:**

1. **Network Structure**
   - **Nodes**: Music sub-genres (e.g., "pop", "hip hop", "dance pop", "trap")
   - **Edges**: Weighted by number of artists who have BOTH genres in their profile
   - **Time Series**: 23 separate networks showing evolution from 2000-2023 (yearly snapshots)
   - **Node Coloring**: Genres colored by main genre family for visual clustering

2. **Mathematical Framework**
   - Uses matrix multiplication approach: **G = A^T × A**
   - A: Artist-Genre binary matrix (artists × genres)
   - G: Genre-Genre co-occurrence matrix (genres × genres)
   - **Note**: No collaboration matrix needed—measures genre co-occurrence within artists, not cross-artist collaborations

3. **Temporal Approach**
   - Creates 23 independent yearly snapshots (2000-2023)
   - Each year shows genres of artists on Billboard charts that year
   - Enables tracking of genre emergence, fusion, and decline over time
   - Billboard data provides temporal filter; artist genre data provides relationships

4. **Color Coding by Main Genre**
   - Each sub-genre mapped to primary main genre (e.g., "dance pop" → "pop")
   - Mapping determined by most common main_genre among artists with that sub-genre
   - Visual clusters show genre families and cross-genre influences
   - Color palette recommendations provided in documentation

5. **Query Types**
   - Billboard data with genre enrichment
   - Genre co-occurrence networks (all-time and yearly)
   - Genre-to-main-genre mapping (for color coding)
   - Network metrics (degree centrality, emerging genre pairs)
   - Genre statistics by year

**Files:**
- `wrangling and transformation/wrangling/bigquery_analysis_queries.sql` - Complete SQL queries for BigQuery
- `wrangling and transformation/wrangling/genre_collaboration_network_documentation.md` - Detailed methodology and graph theory background

**Applications:**
- Identify genre fusion trends over time (e.g., country-rap, emo rap emergence)
- Track genre hybridization patterns (multi-genre artists)
- Understand cultural shifts in mainstream music (2000-2023)
- Create network visualizations with temporal evolution (NetworkX, Gephi, D3.js)
- Analyze genre families and cross-genre influences through color-coded clusters

## Libraries & Dependencies

### R Libraries

| Library | Purpose | Covered in Practicals? |
|---------|---------|----------------------|
| **tidyverse** | Core data manipulation (dplyr, tidyr, purrr); modern R workflow | ✓ Yes |
| **readr** | Fast CSV reading with proper type inference | ✓ Yes |
| **stringr** | String manipulation; cleaning lyrics and text fields | ✓ Yes (part of tidyverse) |
| **ggplot2** | Advanced data visualization; publication-quality plots | ✓ Yes (part of tidyverse) |
| **naniar** | Missing data analysis and summary statistics | ✗ **No** - Self-learned |
| **visdat** | Missing data visualization; exploratory data quality checks | ✗ **No** - Self-learned |
| **tidytext** | Text mining and NLP; word frequency, bigrams, lexical analysis | ✗ **No** - Self-learned |
| **gridExtra** | Multi-panel plot layouts; arranging complex visualizations | ✗ **No** - Self-learned |

**Note**: Libraries marked "Self-learned" represent techniques acquired independently beyond course materials, particularly for missing data analysis and text mining workflows. Some library choices (e.g., readr, gridExtra) also accommodate working in Jupyter notebooks rather than RStudio.

## Setup

### R Environment

Required packages:
```r
install.packages(c("tidyverse", "readr", "stringr", "naniar", "visdat",
                   "ggplot2", "tidytext", "gridExtra"))
```

### BigQuery Setup (Optional)

For network analysis queries:

1. Create a BigQuery project and dataset
2. Upload cleaned CSV files to BigQuery:
   - `billboard_24years_lyrics_spotify_bigquery.csv`
   - `musicoset_artists_cleaned.csv`
   - `musicoset_songs_cleaned.csv`
3. Update table references in `bigquery_analysis_queries.sql`:
   - Replace `your-project-id` with your GCP project ID
   - Replace `your-dataset` with your BigQuery dataset name
4. Run queries in BigQuery Console or via `bq` CLI

## Usage

```bash
# Start Jupyter for R notebooks
jupyter notebook

# Run BigQuery queries (after setup)
bq query --use_legacy_sql=false < bigquery_analysis_queries.sql
```

## Data Structure

```
data/
├── cleaned/                                        # Cleaned datasets (BigQuery-ready)
│   ├── billboard_24years_lyrics_spotify_bigquery.csv           # 3,397 songs, basic cleaning
│   ├── billboard_24years_lyrics_spotify_bigquery_improved.csv  # 3,649 songs, improved lyrics
│   ├── billboard_lexical_analysis_ready.csv                    # Analysis-ready dataset with lexical metrics
│   ├── genre_macro_mapping.csv                                 # Micro to macro genre mapping
│   ├── musicoset_artists_cleaned.csv                           # 11,518 artists
│   ├── musicoset_songs_cleaned.csv                             # 20,405 songs
│   └── musicoset_lyrics_cleaned.csv                            # 20,404 song lyrics
├── billboard_24years_lyrics_spotify.csv            # Source: Billboard data (raw)
├── musicoset_metadata/                             # Source: Artist and song metadata
│   ├── artists.csv                                 # Tab-separated, raw
│   ├── songs.csv                                   # Tab-separated, raw
│   └── ReadMe.txt
└── musicoset_songfeatures/                         # Source: Additional features
    ├── lyrics.csv
    ├── acoustic_features.csv
    └── ReadMe.txt

wrangling and transformation/
├── cleaning/                                       # R cleaning notebooks
│   ├── billboard_cleaning.ipynb                    # Billboard data cleaning
│   ├── musicoset_cleaning.ipynb                    # MusicoSet metadata cleaning
│   ├── missing_data_analysis.ipynb                 # Missing data visualization
│   └── BILLBOARD_CSV_CLEANING_DOCUMENTATION.md     # Cleaning methodology
└── wrangling/                                      # Data transformation and analysis prep
    ├── lexical_diversity_transformation.ipynb      # Lexical metrics calculation
    ├── lexical_diversity_analysis_feasibility.md   # Research question feasibility assessment
    ├── bigquery_analysis_queries.sql               # BigQuery SQL queries
    └── genre_collaboration_network_documentation.md # Network analysis methodology

exploration/                                        # Analysis notebooks
├── data_exploration_focused.ipynb                  # Main Python analysis
└── data_exploration_R.ipynb                        # R-based exploration
```

## Analysis Focus

This project centers on **lexical diversity analysis** to answer the research question: *How does lexical diversity in song lyrics relate to chart performance and vary across genres in Billboard Hot 100 songs (2000-2023)?*

**Primary Analysis:**
- Lexical diversity metrics (TTR, lexical density, hapax ratio) across 3,397 songs
- Cross-genre comparisons (6 macro-genres with 85.6% coverage)
- Chart performance correlations (Top 10 vs. lower rankings)
- Temporal trends over 24 years (2000-2023)
- Genre and year-normalized diversity scores

**Supplementary Components:**
- Audio feature analysis (Spotify data, 14% coverage) as context
- Network analysis of genre relationships using BigQuery and graph theory
- Artist-level patterns and genre fusion trends

## Development Notes

This project was primarily developed by Lorenzo Garduño. AI assistance (Claude Code) was used to help write and debug portions of the code, particularly for data wrangling and processing tasks. Some git commits were automated through Claude Code for convenience.

## References

### Network Analysis Methodology

Park, M., Thom, J., Mennicken, S., Cramer, H., & Macy, M. (2019). Global music streaming data reveal cross-cultural correlations. *Frontiers in Psychology*, 10, 1873. https://doi.org/10.3389/fpsyg.2019.01873

### Additional References

See `wrangling and transformation/wrangling/genre_collaboration_network_documentation.md` for complete bibliography including:
- Newman, M. E. J. (2001) - Collaboration networks
- Borgatti & Everett (1997) - Network analysis of 2-mode data
- Latapy et al. (2008) - Two-mode network analysis
- Barabási (2016) - Network Science textbook

## License

Data sourced from publicly available Billboard charts and Spotify API. See data sources section for attribution.

## Author

Lorenzo Garduño
