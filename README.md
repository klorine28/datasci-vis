# Billboard Lyrics Analysis (2000-2023)

Data science and visualization project analyzing Billboard Top 100 songs over 24 years, with a primary focus on lyrical characteristics and secondary exploration of musical features.

## Overview

This project provides an exploratory overview of Billboard hit songs with a **lyrical lean**, as lyrical analysis was the main area of interest. The analysis includes:
- Lexical diversity and complexity metrics (density and diversity)
- Word frequency analysis
- Relationship between chart performance and lyrical characteristics
- Temporal trends in lyrics complexity
- Year-by-year rankings of lexical diversity
- Supplementary audio features analysis (Spotify data)

## Dataset

- **Billboard Top 100 songs** (2000-2023): 3,397 songs
- **Complete lyrics data**: 100% coverage
- **Spotify audio features**: ~14% coverage (486 songs)

### Data Cleaning & Quality

R-based cleaning pipeline produces BigQuery-ready datasets:

**Billboard Dataset:**
- Converted multi-line lyrics to single-line format
- Normalized whitespace and removed newlines
- Preserved all 26 columns including Spotify features
- Output: 3,398 lines (1 header + 3,397 songs)

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
- `wrangling and transformation/cleaning/billboard_cleaning.ipynb` - Billboard data cleaning
- `wrangling and transformation/cleaning/musicoset_cleaning.ipynb` - MusicoSet metadata cleaning
- `wrangling and transformation/cleaning/missing_data_analysis.ipynb` - Missing data visualization

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

## Usage

```bash
# Start Jupyter for R notebooks
jupyter notebook
```

## Data Structure

```
data/
├── cleaned/                                        # Cleaned datasets (BigQuery-ready)
│   ├── billboard_24years_lyrics_spotify_bigquery.csv  # 3,397 songs, single-line format
│   ├── musicoset_artists_cleaned.csv                  # 11,518 artists
│   └── musicoset_songs_cleaned.csv                    # 20,405 songs
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
└── cleaning/                                       # R cleaning notebooks
    ├── billboard_cleaning.ipynb                    # Billboard data cleaning
    ├── musicoset_cleaning.ipynb                    # MusicoSet metadata cleaning
    ├── missing_data_analysis.ipynb                 # Missing data visualization
    └── BILLBOARD_CSV_CLEANING_DOCUMENTATION.md     # Cleaning methodology

exploration/                                        # Analysis notebooks
├── data_exploration_focused.ipynb                  # Main Python analysis
└── data_exploration_R.ipynb                        # R-based exploration
```

## Note on Analysis Focus

This project emphasizes **lyrical analysis** as the primary area of investigation. The exploration provides an overview of Billboard hits with particular attention to vocabulary complexity, repetition patterns, and linguistic trends over time. Audio feature analysis is included as supplementary context.

## Development Notes

This project was primarily developed by Lorenzo Garduño. AI assistance (Claude Code) was used to help write and debug portions of the code, particularly for data wrangling and processing tasks. Some git commits were automated through Claude Code for convenience.

## License

Data sourced from publicly available Billboard charts and Spotify API. See data sources section for attribution.

## Author

Lorenzo Garduño
