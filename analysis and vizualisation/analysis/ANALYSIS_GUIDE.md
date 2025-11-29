# Lexical Analysis of Billboard Hot 100 (2000-2023)

## Understanding the Metrics

Each metric captures a different aspect of lyrical style. Understanding what they measure helps interpret the graphs.

### Type-Token Ratio (TTR)
**Formula:** unique words / total words

**What it tells us:** How varied is the vocabulary within a single song?

- High TTR (0.4+): Uses many different words, less repetition
- Low TTR (<0.2): Repeats the same words frequently

**Example:** A song with 500 words where 200 are unique has TTR = 0.40

**Use case:** Comparing vocabulary variety across genres or chart positions.

---

### Rare Word Ratio
**Formula:** words not in top 10k common English / total unique words

**What it tells us:** How creative or unusual is the vocabulary?

- High (0.3+): Uses slang, invented words, niche vocabulary
- Low (<0.1): Sticks to everyday common words

**Example:** Hip-hop often scores high (slang, ad-libs). Pop scores low (simple, universal lyrics).

**Use case:** Measuring creative vocabulary independent of repetition.

---

### Lexical Density
**Formula:** content words / total words

**What it tells us:** How much meaning is packed into the lyrics?

- High (0.5+): Dense with nouns, verbs, adjectives (information-rich)
- Low (<0.3): More filler words, pronouns, articles (conversational)

**Example:** Storytelling country = high density. Dance pop = low density.

**Use case:** Distinguishing substantive lyrics from filler-heavy hooks.

---

### Repeated Line Ratio
**Formula:** (total_lines - unique_lines) / total_lines

**What it tells us:** How structurally repetitive is the song?

- High (0.5+): Many repeated choruses/hooks
- Low (<0.2): Mostly unique lines (verse-heavy)

**Example:** EDM drops repeat the same line many times. Rap verses rarely repeat.

**Use case:** Captures structural repetition that word-level TTR misses.

---

### Compression Ratio (Nature Paper Method)
**Formula:** gzip compressed size / original size

**What it tells us:** How compressible are the lyrics? More repetitive text compresses better.

- Low (<0.4): Highly repetitive (compresses well)
- High (>0.6): Less repetitive (doesn't compress as much)

**Example:** A song with many repeated hooks compresses to a smaller size because gzip exploits redundancy.

**Use case:** Objective, algorithmic measure of repetitiveness used in academic research ([Nature paper](https://www.nature.com/articles/s41598-024-55742-x)).

---

### Jaccard Similarity Metrics

**Formula:** |A ∩ B| / |A ∪ B| (intersection over union)

Three versions measure different types of vocabulary overlap:

#### jaccard_genre (Genre-Typical)
**What it tells us:** How typical is this song's vocabulary for its genre?

- High: Uses words common in the genre (fits the mold)
- Low: Uses unusual words for the genre (stands out)

**Use case:** Identifying genre-defying songs or genre conformity.

#### jaccard_corpus (Mainstream)
**What it tells us:** How similar is this song to Billboard hits overall?

- High: Uses typical Billboard vocabulary
- Low: Uses unusual vocabulary for a hit song

**Use case:** Measuring how "mainstream" a song's word choices are.

#### jaccard_common (Everyday Language)
**What it tells us:** How much does this song use common English words?

- High: Mostly everyday vocabulary
- Low: More specialized/creative vocabulary

**Use case:** Baseline comparison to general English usage.

---

## How Metrics Relate

| Metric | Measures | High Value Means |
|--------|----------|------------------|
| TTR | Word variety | Less repetition |
| Rare Word Ratio | Creative vocab | More unusual words |
| Lexical Density | Information density | More content words |
| Repeated Line Ratio | Structural repetition | More chorus/hook repeats |
| Compression Ratio | Algorithmic repetitiveness | Less compressible (less repetitive) |
| Jaccard Genre | Genre conformity | Typical for genre |
| Jaccard Corpus | Mainstream fit | Typical for Billboard |

**Key insight:** A song can have high TTR (varied words) but also high repeated_line_ratio (same lines repeat) - these capture different aspects of repetition. Compression ratio provides an objective, algorithmic measure.

---

## Observed Patterns

### By Genre

**TTR:**
- Country, Latin, Hip-Hop: Higher values
- Pop, Electronic: Lower values
- Rock: Middle

**Lexical Density:**
- Latin: High (Spanish words not in English stop word list)
- Hip-Hop: High
- Pop: Lower

**Rare Words:**
- Latin: Highest (Spanish/English mixing)
- Hip-Hop: High (slang)
- Rock, R&B: Lower

### Chart Performance

Correlation between TTR and chart position: weak negative (near zero)

Jaccard similarity vs ranking: essentially no correlation (rho ≈ -0.01)

### Time Trends (2000-2023)

- Song length decreased
- TTR relatively stable
- Some increase in vocabulary mixing

---

## Limitations

1. Stop word filtering may not work well for code-switching lyrics
2. Longer songs get higher unique counts but lower TTR
3. Only Billboard hits, not album cuts
4. Some pre-2010 lyrics have data quality issues
5. Genre assigned at artist level, not song level
6. Jaccard reference sets built from Billboard only

---

# Genre Network Analysis (2000-2023)

## Data Origin

Sub-genres come from **MusicoSet**, which contains artist metadata from **Spotify's API**.

The `genres` column stores Spotify's genre tags per artist:
```
"['dance pop', 'pop', 'post-teen pop']"
```

These tags are assigned by Spotify's algorithm based on music characteristics and listener behavior.

### Extraction Process

1. MusicoSet `artists.csv` contains `genres` column as string arrays
2. BigQuery regex extracts each genre: `REGEXP_EXTRACT_ALL(genres, r"'([^']+)'")`
3. `CROSS JOIN UNNEST()` creates one row per genre per artist
4. Self-join on artist creates genre pairs (co-occurrence)

### What's Included

| Stage | Count | Description |
|-------|-------|-------------|
| All MusicoSet genres | ~3,000+ | Every Spotify genre tag in the dataset |
| Billboard-matched artists | 1,560 | Genres from artists appearing on Billboard 2000-2023 |
| After edge filtering | 957 | Genres with ≥2 shared artists (edge weight ≥2) |

**No sub-genre filtering** - all genres from Billboard artists are included. The reduction from 1,560 to 957 nodes happens because ~600 genres only connect via single-artist edges, which are filtered out.

### Filtering Applied

1. **Artist filter**: Only MusicoSet artists matched to Billboard chart entries
2. **Edge filter**: `co_occurrence_count >= 2` (removes weak/noise connections)
3. **No genre filter**: All sub-genres from matched artists are used

## Structure

**Nodes:** 957 subgenres
- Size = artist count
- Color = macro genre (16 categories)
- Labels = top 15% nodes by artist count (with text wrapping for multi-word genres)

**Edges:** 8,597 connections
- Weight = number of artists working in both genres

**Layout:** Force-directed (Fruchterman-Reingold)
- Inverted weights: strong connections attract
- 3.5x center scaling to spread dense center
- Collision detection (factor 0.4) to prevent node overlap

**Yearly Snapshots:**
- Same FR layout algorithm per year
- "pop" genre anchored at center (0, 0) for stable focal point
- All coordinates shifted so pop remains fixed across years
- Designed for flipbook-style animation to show evolution

## Methodology

Co-occurrence matrix from BigQuery:
```
G = A^T × A
```
Where A is artist-genre binary matrix.

### Macro Genre Mapping (16 categories)

| Macro | Color | Examples |
|-------|-------|----------|
| POP | #FF6B6B | dance pop, electropop |
| HIP HOP | #2E7D32 | rap, trap |
| COUNTRY | #FFD93D | contemporary country |
| ROCK | #4A90D9 | album rock, indie rock |
| R&B | #F38181 | r&b, soul |
| ELECTRONIC | #AA96DA | edm, house |
| LATIN | #8D6E63 | reggaeton, banda |
| METAL | #37474F | nu metal, metalcore |
| JAZZ | #FF8C42 | jazz, bebop |
| BLUES | #1E88E5 | blues, delta blues |
| FOLK | #A5D6A7 | folk, singer-songwriter |
| CLASSICAL | #CE93D8 | classical, opera |
| REGGAE | #FFEE58 | reggae, ska |
| NEW AGE | #80DEEA | ambient, meditation |
| AVANT-GARDE | #BCAAA4 | experimental |
| OTHER | #9E9E9E | miscellaneous |

### Metrics

- **Degree:** Number of connected genres
- **Strength:** Sum of edge weights
- **Betweenness:** Frequency on shortest paths

---

## Observed Patterns

### Hub Genres (by strength)

| Genre | Connections | Shared Artists |
|-------|-------------|----------------|
| rock | 172 | 4,062 |
| folk rock | 105 | 2,846 |
| singer-songwriter | 140 | 2,740 |
| modern rock | 153 | 2,723 |

### Strongest Collaborations

| Pair | Shared Artists |
|------|----------------|
| hip hop ↔ rap | 287 |
| pop rap ↔ rap | 273 |
| dance pop ↔ pop | 268 |

### Network Properties

- Density: 0.0188
- Components: 11
- Average degree: ~18 connections per genre

### Yearly Observations

- 2000-2005: Rock and pop clusters dominant
- 2010-2015: Hip hop cluster grows, electronic emerges
- 2020-2023: More cross-genre connections

### Visualization Approach

**Full Network (genre_network_full.png):**
- All 957 nodes displayed
- FR layout with 3.5x center scaling
- Collision detection prevents node overlap
- Top 15% nodes labeled with wrapped text
- Dark gray labels (#333333) for readability

**Yearly Snapshots (genre_snapshots_yearly/):**
- FR layout calculated per year
- "pop" always anchored at center (coordinates shifted post-layout)
- Top 30% nodes labeled per year
- Consistent seed (42) for reproducible layouts
- Square output (12x12) optimized for flipbook animation

**Key Years Panel (genre_network_evolution_key_years.png):**
- 6 panels: 2000, 2005, 2010, 2015, 2020, 2023
- Same pop-centered layout as yearly snapshots
- 3x2 grid layout for comparison

---

## Limitations

1. Genre labels from Spotify, which are algorithmic
2. Artist-level aggregation, not song-level
3. Billboard data only (no underground)
4. Main network aggregates 24 years
5. Macro grouping loses subgenre nuance
6. Filtered to edges with ≥2 shared artists

---

## Output Files

| File | Description |
|------|-------------|
| genre_network_full.png | Main network (957 nodes, FR layout with collision detection, top 15% labeled) |
| genre_network_evolution_key_years.png | 6-panel evolution (2000, 2005, 2010, 2015, 2020, 2023) |
| genre_hubs.png | Top 25 hub genres by connection strength |
| genre_network_metrics.csv | Centrality metrics (degree, strength, betweenness) |
| genre_snapshots_yearly/ | 24 individual year networks (pop-centered, flipbook-ready) |
