# Billboard Lyrics Analysis (2000-2023)

Data science and visualization project analyzing Billboard Top 100 songs over 24 years, focusing on lyrical characteristics and musical features.

## Overview

This project explores patterns in Billboard hit songs through:
- Lexical diversity and complexity metrics
- Word frequency analysis
- Relationship between chart performance and lyrical characteristics
- Temporal trends in lyrics complexity
- Year-by-year rankings of lexical diversity
- Audio features analysis (Spotify data)

## Dataset

- **Billboard Top 100 songs** (2000-2023): 3,397 songs
- **Complete lyrics data**: 100% coverage
- **Spotify audio features**: ~14% coverage (486 songs)

## Notebooks

### `data_exploration_focused.ipynb`
Main analysis notebook with:
- Word frequency and lexical metrics
- Chart position analysis (groups of 5 songs)
- Temporal trends and statistical tests
- Complete year-by-year rankings
- Extreme examples (most/least complex songs)

### `data_exploration_R.ipynb`
R-based exploratory analysis.

## Key Findings

- Lexical diversity shows significant temporal trends
- Top-charting songs show measurably different lyrical complexity
- Decade-by-decade analysis reveals evolving patterns
- Year-over-year rankings provide granular insights

## Setup

```bash
# Create virtual environment
python -m venv .venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate

# Install dependencies
pip install pandas numpy matplotlib seaborn jupyter
```

For R notebooks:
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
├── billboard_24years_lyrics_spotify.csv  # Main dataset
├── musicoset_metadata/                   # Artist and song metadata
│   ├── artists.csv
│   ├── songs.csv
│   └── ReadMe.txt
└── musicoset_songfeatures/               # Additional features
    └── ReadMe.txt
    # Note: Large files (lyrics.csv, acoustic_features.csv) excluded from git
```

## License

Data sourced from publicly available Billboard charts and Spotify API.

## Author

Lorenzo Garduño
