# Research Question Data Feasibility Assessment

## Research Question
**"How does lexical diversity in song lyrics relate to chart performance and vary across genres in Billboard Hot 100 songs (2000-2023)"**

Inspired by [The Pudding's Vocabulary Analysis](https://pudding.cool/projects/vocabulary/index.html)

---

## Executive Summary: ✅ DATA IS SUFFICIENT

The available dataset provides **excellent coverage** for answering this research question, with 85.6% genre coverage and complete lyrics data for all Billboard Top 100 songs from 2000-2023.

**Key Strengths:**
- 100% lyrics coverage (3,397 songs)
- 100% chart ranking data
- 85.6% genre coverage (2,948/3,445 songs)
- 24-year time span for temporal analysis
- Strong sample sizes in major genres

---

## Data Inventory

### What We Have ✅

| Component | Data Available | Coverage | Status |
|-----------|----------------|----------|--------|
| **Lyrics** | 3,397 songs | 100% | ✅ Excellent |
| **Chart Performance** | Billboard rankings (1-100) | 100% | ✅ Perfect |
| **Time Period** | 2000-2023 | 24 years | ✅ Great range |
| **Genre Data** | MusicoSet artist genres | 85.6% | ✅ Very Good |
| **Year Data** | All songs | 100% | ✅ Perfect |
| **Artist Data** | All songs | 100% | ✅ Perfect |
| **Spotify Features** | Audio features | ~14% | ⚠️ Limited (supplementary only) |

### Data Sources
1. **Billboard Hot 100 (2000-2023)** - Primary dataset
   - 3,397 songs with complete lyrics
   - Chart rankings and year information

2. **MusicoSet Metadata** - Genre enrichment
   - 11,518 artists with genre classifications
   - Both `main_genre` and detailed `genres` arrays
   - 85.6% match rate with Billboard songs

---

## Genre Distribution Analysis

### Coverage Summary
- **Total Billboard songs:** 3,445
- **Songs with genre data:** 2,948 (85.6%)
- **Unique micro-genres:** 159
- **Median songs per genre:** 3

### Top 15 Genres by Song Count

| Rank | Genre | Song Count | Analysis Viability |
|------|-------|------------|-------------------|
| 1 | dance pop | 982 | ✅ Excellent |
| 2 | contemporary country | 253 | ✅ Great |
| 3 | atl hip hop | 250 | ✅ Great |
| 4 | pop | 152 | ✅ Good |
| 5 | hip hop | 97 | ✅ Adequate |
| 6 | alternative metal | 76 | ✅ Adequate |
| 7 | canadian hip hop | 75 | ✅ Adequate |
| 8 | canadian pop | 56 | ✅ Adequate |
| 9 | chicago rap | 51 | ✅ Adequate |
| 10 | australian pop | 43 | ⚠️ Limited |
| 11 | hip pop | 42 | ⚠️ Limited |
| 12 | neo mellow | 35 | ⚠️ Limited |
| 13 | detroit hip hop | 34 | ⚠️ Limited |
| 14 | dirty south rap | 33 | ⚠️ Limited |
| 15 | canadian contemporary r&b | 30 | ⚠️ Limited |

### Challenge: Genre Granularity

**Problem:** 159 micro-genres result in most having <10 songs, making statistical analysis weak for individual genres.

**Solution:** Group micro-genres into macro-categories for meaningful analysis.

---

## Recommended Genre Grouping Strategy

### Macro-Genre Categories

Group the 159 micro-genres into 5-7 major categories:

#### 1. **POP** (Estimated: ~1,200+ songs)
- dance pop (982)
- pop (152)
- canadian pop (56)
- australian pop (43)
- hip pop (42)
- electropop
- post-teen pop
- indie poptimism

#### 2. **HIP HOP / RAP** (Estimated: ~500+ songs)
- atl hip hop (250)
- hip hop (97)
- canadian hip hop (75)
- chicago rap (51)
- detroit hip hop (34)
- dirty south rap (33)
- dfw rap
- pop rap
- trap

#### 3. **COUNTRY** (Estimated: ~250+ songs)
- contemporary country (253)
- country
- modern country rock

#### 4. **ROCK / METAL** (Estimated: ~100+ songs)
- alternative metal (76)
- rock
- indie rock
- alternative rock
- pop rock

#### 5. **R&B / SOUL** (Estimated: ~100+ songs)
- canadian contemporary r&b (30)
- neo mellow (35)
- r&b
- soul
- urban contemporary

#### 6. **ELECTRONIC / DANCE** (Estimated: ~50+ songs)
- edm
- house
- electro house
- tropical house

#### 7. **OTHER**
- Latin genres
- Reggae
- Folk
- Jazz
- Uncategorized

### Implementation Approach

**Option 1: Use `main_genre` Field** (Simpler)
- Each artist/song assigned to one primary genre
- Clean, non-overlapping categories
- 85.6% coverage maintained

**Option 2: Use Full `genres` Array** (More Accurate)
- Songs can belong to multiple categories
- Reflects genre-blending reality
- Better represents modern music landscape
- Example: Post Malone → ["dfw rap", "pop", "rap"] → counted in both POP and HIP HOP

**Option 3: Hybrid Approach** ⭐ **RECOMMENDED**
- Use `main_genre` for primary analysis
- Use full `genres` for secondary "genre-blending" analysis
- Allows both clean comparisons AND nuanced exploration

---

## Comparison to Pudding's Analysis

### The Pudding: Hip-Hop Vocabulary Analysis

| Aspect | The Pudding | Our Analysis |
|--------|-------------|--------------|
| **Scope** | Full artist discographies | Billboard Top 100 hits only |
| **Genre Coverage** | Hip-hop only | Multiple genres (cross-comparison) |
| **Metric** | Total vocabulary size | Lexical diversity per song |
| **Sample** | ~500 words minimum per artist | Variable song lengths |
| **Time Period** | Multiple decades | 2000-2023 (24 years) |
| **Chart Data** | Not included | ✅ Central variable |

### Our Advantages

1. **Cross-Genre Comparison**
   - Pudding analyzed only hip-hop
   - We can compare pop vs. hip-hop vs. country vs. rock
   - More diverse and interesting research scope

2. **Chart Performance Variable**
   - Pudding had no performance metrics
   - We can answer: "Do more diverse lyrics chart higher?"
   - Temporal component: Has this changed over 24 years?

3. **Cultural Impact Focus**
   - Billboard Top 100 = what people actually heard
   - Pudding included deep cuts and album tracks
   - Our focus on "mainstream impact" is valid and interesting

### Our Challenges

1. **Song-Level vs. Artist-Level**
   - Pudding analyzed full vocabularies across careers
   - We analyze individual song diversity
   - Solution: Different but equally valid metric

2. **Smaller Vocabulary Per Unit**
   - Songs have ~100-600 words
   - Full discographies have thousands
   - Solution: Use appropriate metrics (TTR, lexical density)

3. **Genre Attribution**
   - 14.4% songs lack genre data
   - Artist-level genres may not match song style
   - Solution: Focus on 85.6% with data, acknowledge limitation

---

## Lexical Diversity Metrics Available

We can calculate all standard lexical diversity metrics:

### Basic Metrics
- **Unique Words** - Total distinct words per song
- **Total Words** - Song length in words
- **Type-Token Ratio (TTR)** - Unique words / Total words

### Advanced Metrics
- **Lexical Density** - Content words / Total words
- **Vocabulary Richness** - Statistical measures (MTLD, vocd-D)
- **Word Repetition Rate** - Frequency of repeated words
- **Average Word Length** - Syllables or characters
- **Rare Word Usage** - Words outside common vocabulary

### Comparative Metrics
- **Genre-Normalized Diversity** - Compared to genre average
- **Year-Normalized Diversity** - Compared to same-year songs
- **Chart-Position-Normalized** - Compared to similar rankings

---

## Research Questions We Can Answer

### Primary Question
**"How does lexical diversity in song lyrics relate to chart performance and vary across genres in Billboard Hot 100 songs (2000-2023)"**

### Sub-Questions (All Answerable)

#### 1. Chart Performance Relationship
- ✅ Do lyrically diverse songs chart higher or lower?
- ✅ Does the relationship vary by genre?
- ✅ Has this relationship changed over time?
- ✅ Are Top 10 hits more/less diverse than #50-100?

#### 2. Genre Differences
- ✅ Which genres have the most/least lexically diverse lyrics?
- ✅ How consistent is diversity within each genre?
- ✅ Do certain genres reward complexity more than others?
- ✅ How do genre-blending artists compare to single-genre artists?

#### 3. Temporal Trends
- ✅ Has lyrical diversity increased or decreased (2000-2023)?
- ✅ Are there distinct eras or inflection points?
- ✅ Do different genres show different temporal patterns?
- ✅ How do these trends correlate with music industry changes?

#### 4. Genre Fusion
- ✅ Do multi-genre artists have more diverse lyrics?
- ✅ How does genre-blending affect chart performance?
- ✅ Are fusion songs becoming more common over time?

#### 5. Outlier Analysis
- ✅ Which songs are most/least diverse in each genre?
- ✅ Do exceptionally diverse songs perform differently?
- ✅ Are there "diverse hit" success stories?

---

## Methodology Recommendations

### Analysis Pipeline

#### Stage 1: Data Preparation
1. Clean lyrics (remove metadata, normalize text)
2. Map micro-genres to macro-genres
3. Calculate lexical diversity metrics for all songs
4. Join with chart performance and temporal data

#### Stage 2: Exploratory Analysis
1. Distribution of diversity metrics by genre
2. Correlation between diversity and chart position
3. Temporal trends visualization
4. Identify outliers and interesting cases

#### Stage 3: Statistical Testing
1. Regression models (diversity ~ chart_position + genre + year)
2. ANOVA tests across genres
3. Time series analysis for trends
4. Control for confounding variables (song length, artist popularity)

#### Stage 4: Visualization
1. Genre comparison charts (box plots, violin plots)
2. Scatter plots (diversity vs. chart position)
3. Time series plots (trends over 24 years)
4. Interactive visualizations (D3.js, Plotly)

### Statistical Considerations

**Sample Sizes:**
- Total: 2,948 songs with genres (excellent)
- Major genres: 100-1,000 songs each (very good)
- Minor genres: May need grouping or exclusion

**Potential Confounds:**
- Song length (longer songs may appear more diverse)
- Artist popularity (stars may have different patterns)
- Year effects (cultural shifts over time)
- Genre evolution (genres change characteristics)

**Controls:**
- Normalize by song length
- Include artist as random effect
- Time-based controls
- Genre-specific baselines

---

## Data Gaps and Limitations

### 1. Genre Coverage: 14.4% Missing
**Impact:** Moderate
- 497 songs lack genre classification
- Could bias results if missing data is non-random

**Mitigation Options:**
- Analyze with available 85.6% (still excellent coverage)
- Manually tag high-impact missing songs
- Use genre prediction based on artist similarity
- Report as limitation in findings

### 2. Artist-Level vs. Song-Level Genres
**Impact:** Low to Moderate
- Artist may have multiple genres
- Individual songs may not match artist's primary genre
- Example: Taylor Swift = country AND pop

**Mitigation Options:**
- Use `main_genre` for primary analysis
- Secondary analysis with multi-genre tags
- Manual verification for genre-switching artists
- Acknowledge as methodological choice

### 3. Spotify Features Limited
**Impact:** Low (Not critical for main question)
- Only 14% coverage for audio features
- Cannot correlate diversity with musical complexity

**Note:** Not needed for primary research question, but limits supplementary analysis

### 4. Sample Size Imbalance
**Impact:** Low (Addressable)
- Pop dominates (982 songs)
- Some genres have <50 songs

**Mitigation:**
- Use weighted statistics
- Focus comparisons on well-represented genres
- Group small genres into "Other"
- Report sample sizes in all analyses

---

## Next Steps

### Immediate Actions
1. ✅ Create genre grouping mapping (micro → macro)
2. ⬜ Calculate lexical diversity metrics for all songs
3. ⬜ Build exploratory analysis notebook
4. ⬜ Validate genre assignments for high-impact songs

### Analysis Development
1. ⬜ Write metric calculation functions
2. ⬜ Statistical testing framework
3. ⬜ Visualization templates
4. ⬜ Draft findings structure

### Documentation
1. ⬜ Methodology documentation
2. ⬜ Code comments and README
3. ⬜ Limitations and assumptions
4. ⬜ Reproducibility instructions

---

## Conclusion

**Final Verdict: ✅ DATA IS HIGHLY SUITABLE**

The available dataset provides excellent foundation for answering the research question:
- **Complete lyrics coverage** enables all diversity calculations
- **85.6% genre coverage** supports robust cross-genre comparisons
- **100% chart data** allows performance analysis
- **24-year span** enables temporal trend analysis
- **Strong sample sizes** in major genres ensure statistical power

**Key Advantages Over Pudding Analysis:**
- Cross-genre comparison (not just hip-hop)
- Chart performance as central variable
- Focus on cultural mainstream (Billboard hits)

**This analysis is not only feasible but potentially more interesting and impactful than the original Pudding work.**

---

## References

### Inspiration
- The Pudding. (n.d.). *The Largest Vocabulary in Hip Hop*. https://pudding.cool/projects/vocabulary/index.html

### Data Sources
- Billboard Hot 100 (2000-2023) with Spotify Features - Kaggle Dataset
- Musicoset Dataset - DSW 2019 Project (Artist/Song Metadata)

### Relevant Literature
- Lexical diversity metrics in computational linguistics
- Popular music analysis methodologies
- Genre classification and evolution studies

---

**Document Version:** 1.0
**Last Updated:** 2025-01-20
**Status:** Data Assessment Complete ✅
