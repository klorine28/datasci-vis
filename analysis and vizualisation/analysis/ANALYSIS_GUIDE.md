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

**Layout:** Fruchterman-Reingold
- Force-directed algorithm with inverted weights (strong connections = closer)
- 3.5x center scaling to spread dense center
- Collision detection (factor 0.4) to prevent node overlap

**Animated Network (GIF):**
- Top 300 nodes by artist count
- Fresh Fruchterman-Reingold layout calculated for filtered nodes
- 5.5x spread scaling + collision detection (factor 0.55)
- Opacity filtering: active nodes bright (0.9), inactive faded (0.15)
- Labels on all nodes (shown only when active)
- 3 seconds per year, 2400x2000 resolution

**Yearly Snapshots:**
- Key years: 2000, 2005, 2010, 2015, 2020, 2023
- Fruchterman-Reingold layout per year
- "pop" genre anchored at center for stable focal point

**Gephi Export:**
- GEXF file with dynamic edges (appear/disappear by year)
- Nodes have fixed positions from R layout
- Timeline feature for temporal animation

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
- Fruchterman-Reingold layout with 3.5x center scaling
- Collision detection (factor 0.4) prevents node overlap
- Top 25% nodes labeled with wrapped text
- White labels for readability on colored nodes

**Animated GIF (genre_network_animated.gif):**
- Top 300 nodes by artist count (reduces clutter)
- Fresh layout calculated specifically for filtered nodes
- Opacity-based activity highlighting:
  - Bright (alpha 0.9): Node has collaborations that year
  - Faded (alpha 0.15): Node inactive that year
- All nodes labeled (labels only shown when active)
- 3 seconds per frame, 24 frames (2000-2023)
- Resolution: 2400x2000 pixels

**Key Years Panel (genre_network_evolution_key_years.png):**
- 6 panels: 2000, 2005, 2010, 2015, 2020, 2023
- Fruchterman-Reingold layout per year
- "pop" anchored at center for comparison
- 3x2 grid layout

### Genre Collaboration Analysis

**Total Collaborations (2000-2023):**
- Sum of all edge weights per genre across all 24 years
- No arbitrary period segmentation - complete picture
- Measures overall genre connectivity in Billboard ecosystem

**Top Genres by Category (top_genres_by_category.png):**
- Top 5 genres per macro genre by total collaborations
- Faceted bar chart for easy comparison across categories
- Shows which subgenres dominate within each macro genre

**Top 25 Overall (top_25_collaborative_genres.png):**
- Single ranked bar chart like hub genres
- Shows the most connected genres regardless of category
- Colored by macro genre for context

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

### Images
| File | Description |
|------|-------------|
| genre_network_full.png | Main network (957 nodes, FR layout, collision detection) |
| genre_network_animated.gif | Animated network (300 nodes, opacity filtering, 3 sec/year) |
| genre_network_evolution_key_years.png | 6-panel evolution (2000, 2005, 2010, 2015, 2020, 2023) |
| genre_hubs.png | Top 25 hub genres by connection strength |
| top_genres_by_category.png | Top 5 genres per macro genre by total collaborations |
| top_25_collaborative_genres.png | Top 25 most collaborative genres overall |

### Data (non_image/)
| File | Description |
|------|-------------|
| genre_network_dynamic.gexf | Gephi file with dynamic edges for timeline animation |
| genre_network_nodes_gephi.csv | Node data for Gephi import |
| genre_network_edges_gephi.csv | Edge data (all-time) for Gephi import |
| genre_network_edges_temporal_gephi.csv | Edge data with year column (sparse format) |

---

## Using Gephi for Dynamic Visualization

The notebook exports a GEXF file that enables dynamic edge visualization in Gephi. Here's how to use it:

### Step 1: Install Gephi

Download from [gephi.org](https://gephi.org/) (available for Windows, Mac, Linux).

### Step 2: Open the Dynamic Graph

1. Launch Gephi
2. **File > Open** → select `outputs/genre_network/genre_network_dynamic.gexf`
3. In the import dialog:
   - Graph Type: **Undirected**
   - Time Representation: **Interval**
   - Click **OK**

### Step 3: Enable the Timeline

1. Look at the **bottom toolbar** - you'll see a timeline panel
2. If not visible, go to **Window > Timeline**
3. Click the **Enable Timeline** button (clock icon)

### Step 4: Configure the View

1. **Overview tab** (left panel):
   - Nodes should already be positioned and colored from the R layout
   - If not, run **Layout > ForceAtlas 2** briefly, then stop

2. **Appearance panel** (right side):
   - Nodes > Color > Partition > `macro_genre` (should be pre-set)
   - Nodes > Size > Ranking > `artist_count`

### Step 5: Animate the Timeline

1. **Adjust the time window**: Drag the edges of the timeline slider to set a 1-year window
2. **Scrub through years**: Drag the slider from 2000 to 2023
3. **Watch edges appear/disappear**: Only edges active in that year will show
4. **Play animation**: Click the play button for automatic animation

### Step 6: Export Animation

Gephi doesn't export video directly. Options:
1. **Screen recording**: Use QuickTime (Mac) or OBS to record the animation
2. **Export frames**: Use the Timeline's frame export feature
3. **Sigma.js export**: File > Export > Sigma.js template (creates interactive web page)

### Tips

- **Lock node positions**: Right-click on graph > "Settle" to prevent nodes from moving
- **Filter by weight**: Use Filters > Edges > Edge Weight to show only strong connections
- **Adjust animation speed**: In Timeline settings, change the playback speed
- **Custom time window**: Set window size to 1 year for year-by-year view, or 5 years for smoother transitions

### Alternative: CSV Import

If you prefer to build the graph from scratch in Gephi:

1. **File > Import Spreadsheet**
2. Import `genre_network_nodes_gephi.csv` as **Nodes table**
3. Import `genre_network_edges_temporal_gephi.csv` as **Edges table**
4. Set `year` column as time interval
5. Merge into workspace

---

## References

- [Gephi documentation](https://gephi.org/users/)
- [GEXF file format](https://gexf.net/)
- [Gephi dynamic graph tutorial](https://seinecle.github.io/gephi-tutorials/generated-html/converting-a-network-with-dates-into-dynamic.html)
- [gganimate package](https://gganimate.com/) - Animated ggplot2 visualizations
