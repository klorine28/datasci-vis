# Research Question Data Feasibility Assessment

## Research Question
**"How does lexical diversity in song lyrics relate to chart performance and vary across genres in Billboard Hot 100 songs (2000-2023)"**

Inspired by [The Pudding's Vocabulary Analysis](https://pudding.cool/projects/vocabulary/index.html)

---

## Summary

The dataset provides sufficient coverage for this research question.

**Coverage:**
- 3,397 songs with complete lyrics (100%)
- 3,024/3,443 songs with genre data (87.8%)
- 100% Top 10 coverage after manual validation
- 24-year time span (2000-2023)

---

## Data Inventory

| Component | Coverage | Notes |
|-----------|----------|-------|
| Lyrics | 100% | 3,397 songs |
| Chart rankings | 100% | Position 1-100 |
| Year | 100% | 2000-2023 |
| Genre | 85.6% | Via MusicoSet artist data |
| Spotify features | ~14% | Limited, supplementary only |

### Data Sources
1. **Billboard Hot 100 (2000-2023)** - Chart data, lyrics
2. **MusicoSet** - Artist genre classifications (11,518 artists)

---

## Genre Distribution

### Coverage
- Total songs: 3,445
- Songs with genre: 2,948 (85.6%)
- Unique micro-genres: 159
- Median songs per genre: 3

### Top Genres by Count

| Genre | Count |
|-------|-------|
| dance pop | 982 |
| contemporary country | 253 |
| atl hip hop | 250 |
| pop | 152 |
| hip hop | 97 |
| alternative metal | 76 |
| canadian hip hop | 75 |

### Genre Grouping

159 micro-genres grouped into 6 macro categories:

1. **POP** (~1,200 songs) - dance pop, pop, canadian pop, electropop
2. **HIP HOP** (~500 songs) - atl hip hop, trap, chicago rap, pop rap
3. **COUNTRY** (~250 songs) - contemporary country
4. **ROCK** (~100 songs) - alternative metal, rock, indie rock
5. **R&B** (~100 songs) - r&b, neo mellow, urban contemporary
6. **ELECTRONIC** (~50 songs) - edm, house

---

## Metrics Calculated

### Basic
- Unique words per song
- Total words per song
- Type-Token Ratio (TTR)

### Advanced
- Lexical density (content words / total)
- Hapax legomena (words appearing once)
- Rare word ratio (words not in top 10k common English)

### Comparative
- Jaccard similarity (genre, corpus, common words)
- Genre-normalized TTR (z-score)
- Year-normalized TTR (z-score)

---

## Research Questions Addressable

1. **Chart Performance**
   - Does TTR correlate with chart position?
   - Does this vary by genre?

2. **Genre Differences**
   - Which genres have highest/lowest TTR?
   - How consistent is diversity within genres?

3. **Temporal Trends**
   - Has TTR changed from 2000-2023?
   - Do genres show different patterns?

---

## Limitations

### 1. Missing Genre Data (14.4%)
- 497 songs lack genre classification
- May introduce bias if missing is non-random

### 2. Artist-Level Genres
- Genres assigned at artist level, not song level
- Artist with multiple genres creates ambiguity

### 3. Limited Spotify Data
- Only 14% have audio features
- Cannot correlate diversity with musical features

### 4. Sample Imbalance
- Pop dominates (982 songs)
- Some genres have <50 songs

---

## Comparison to Pudding Analysis

| Aspect | The Pudding | This Analysis |
|--------|-------------|---------------|
| Scope | Full discographies | Billboard hits only |
| Genres | Hip-hop only | Multiple genres |
| Metric | Total vocabulary | Per-song diversity |
| Chart data | None | Central variable |

---

## Data Quality Notes (2025-01-25)

### Manual Validation
- 30 Top 10 songs corrected (featured artist issues)
- 284 duplicate rows removed
- 192 missing genre entries filled
- Coverage improved: 82.8% → 87.8%

### Final Dataset
- 3,443 unique songs
- 87.8% genre coverage
- 100% Top 10 coverage

---

## References

- The Pudding. *The Largest Vocabulary in Hip Hop*. https://pudding.cool/projects/vocabulary/index.html
- Billboard Hot 100 (2000-2023) - Kaggle
- Musicoset Dataset - DSW 2019

---

**Last Updated:** 2025-01-25
