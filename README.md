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

The dataset underwent comprehensive cleaning to ensure analysis quality:

**Issues Addressed:**
- **Standalone dash conversion**: Converted 3,148+ standalone "-" values (representing unknown/missing data) to proper NA values
- **Lyrics data quality**: Identified and flagged 5 songs with suspiciously short lyrics (< 50 words) due to scraping errors
- **Outlier detection**: Found 8 songs with extreme word counts (>3 standard deviations), including one with 10,498 words
- **Data validation**: Verified all rankings (1-100), years (2000-2023), and lexical metrics are within valid ranges

**Cleaning Process:**
- Missing data visualization and temporal analysis
- Text standardization (whitespace trimming)
- Genre string parsing from list format
- Statistical outlier flagging for manual review
- Export of flagged records for quality control

**Documentation:**
- `cleaning/DATA_CLEANING_PROCESS.md` - Comprehensive cleaning documentation
- `wrangling and transformation/data_cleaning.ipynb` - Cleaning notebook
- `cleaning/flagged_records_for_review.csv` - 539 songs flagged for manual review

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

## Setup

### Python Environment (using UV)

This project uses [UV](https://github.com/astral-sh/uv) for fast Python package management:

```bash
# Create virtual environment with UV
uv venv

# Activate virtual environment
source .venv/bin/activate  # On Windows: .venv\Scripts\activate

# Install dependencies
uv pip install pandas numpy matplotlib seaborn jupyter
```

Alternatively, with standard pip:
```bash
python -m venv .venv
source .venv/bin/activate
pip install pandas numpy matplotlib seaborn jupyter
```

### R Notebooks

```r
install.packages(c("tidyverse", "ggplot2", "tidytext", "gridExtra", "stringr"))
```

## Usage

```bash
# Activate virtual environment
source .venv/bin/activate

# Start Jupyter
jupyter notebook
```

## Data Structure

```
data/
├── cleaned/                              # 4 core cleaned datasets
│   ├── billboard_master.csv             # Song-level data (3,397 songs)
│   ├── song_artists.csv                 # Artist-level data (3,423 records)
│   ├── temporal_trends.csv              # Year × genre aggregations (754 rows)
│   └── genre_network.csv                # Genre co-occurrence (6,316 pairs)
├── billboard_24years_lyrics_spotify.csv  # Source: Billboard data
├── musicoset_metadata/                   # Source: Artist and song metadata
│   ├── artists.csv
│   ├── songs.csv
│   └── ReadMe.txt
└── musicoset_songfeatures/               # Source: Additional features
    ├── lyrics.csv
    ├── acoustic_features.csv
    └── ReadMe.txt

cleaning/
├── flagged_records_for_review.csv       # 539 songs flagged for quality issues
└── DATA_CLEANING_PROCESS.md             # Detailed cleaning documentation

wrangling and transformation/
├── data_wrangling_sql.ipynb             # Data wrangling pipeline
├── data_cleaning.ipynb                  # Data cleaning notebook
├── DATA_WRANGLING_METHODOLOGY.md        # Wrangling methodology
└── DATASET_SCHEMAS.md                   # Dataset schemas reference
```

## Note on Analysis Focus

This project emphasizes **lyrical analysis** as the primary area of investigation. The exploration provides an overview of Billboard hits with particular attention to vocabulary complexity, repetition patterns, and linguistic trends over time. Audio feature analysis is included as supplementary context.

## Development Notes

This project was primarily developed by Lorenzo Garduño. AI assistance (Claude Code) was used to help write and debug portions of the code, particularly for data wrangling and processing tasks. Some git commits were automated through Claude Code for convenience.

## License

Data sourced from publicly available Billboard charts and Spotify API. See data sources section for attribution.

## Author

Lorenzo Garduño
