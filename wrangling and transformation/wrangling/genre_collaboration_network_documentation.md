# Genre Co-Occurrence Network: Matrix Multiplication Approach

## Table of Contents
1. [Introduction](#introduction)
2. [Network Structure](#network-structure)
3. [Graph Theory Background](#graph-theory-background)
4. [Matrix Representation](#matrix-representation)
5. [Matrix Multiplication Logic](#matrix-multiplication-logic)
6. [Why No Collaboration Matrix Is Needed](#why-no-collaboration-matrix-is-needed)
7. [SQL Implementation](#sql-implementation)
8. [Yearly Evolution (2000-2023)](#yearly-evolution-2000-2023)
9. [Main Genre Clustering and Coloring](#main-genre-clustering-and-coloring)
10. [References](#references)

---

## Introduction

This document explains the mathematical framework for constructing a **genre co-occurrence network** from music artist data. The goal is to understand how different music genres are related through multi-genre artists—artists who are tagged with multiple genres simultaneously.

### Problem Statement
Given:
- A set of artists with associated genres (both main genres and sub-genres)
- Billboard chart data indicating which artists were popular each year (2000-2023)

We want to create:
- A network where **nodes** represent music sub-genres
- **Edges** (weighted) represent the number of artists who have BOTH genres in their profile
- **23 yearly networks** showing genre evolution from 2000 to 2023
- **Node coloring** based on main genre categories

### Inspiration

This approach is inspired by network visualizations of music genre relationships, such as:

> "Network visualization of music genres and subgenres. Note: Nodes represent subgenres and edges represent the co-listing by the same musicians. More musicians sharing genres, thicker line. Nodal colors indicate major genres."

**Key insight**: Edges represent **genre co-occurrence within artists' profiles**, NOT collaborations between artists of different genres.

---

## Network Structure

### Nodes
**Nodes** in our network represent **music sub-genres**. These include:
- Main genres (e.g., "pop", "rock", "hip hop")
- Sub-genres (e.g., "dance pop", "indie rock", "trap", "emo rap")

Each unique genre in our dataset becomes a node in the network.

### Edges
**Edges** connect two genre nodes and represent **co-occurrence within artist profiles**.

**Edge weight** = Number of artists who have BOTH genre A and genre B in their profile

#### Example:
If:
- **Post Malone** has genres: ["pop", "hip hop", "rap"]
- **Ariana Grande** has genres: ["pop", "dance pop"]
- **The Weeknd** has genres: ["pop", "r&b"]

Then edges are created:
- **"pop" ↔ "hip hop"**: weight = 1 (from Post Malone)
- **"pop" ↔ "rap"**: weight = 1 (from Post Malone)
- **"hip hop" ↔ "rap"**: weight = 1 (from Post Malone)
- **"pop" ↔ "dance pop"**: weight = 1 (from Ariana Grande)
- **"pop" ↔ "r&b"**: weight = 1 (from The Weeknd)

Note: "pop" appears frequently because many artists combine it with other genres.

### Network Properties
- **Undirected**: An edge from genre A to genre B is the same as B to A
- **Weighted**: Edge weights represent the number of multi-genre artists
- **Self-loops possible**: A genre can connect to itself (diagonal of matrix) if we count how many artists have that genre
- **Temporal**: We create 23 separate networks (one per year, 2000-2023)
- **Colored clusters**: Nodes are colored by main genre category

---

## Graph Theory Background

### Basic Definitions

#### Graph
A graph G = (V, E) consists of:
- **V**: Set of vertices (nodes)
- **E**: Set of edges connecting vertices

#### Weighted Graph
A weighted graph assigns a numerical value (weight) to each edge, representing the strength of the connection.

#### Adjacency Matrix
An **adjacency matrix** G is a square matrix used to represent a graph:
- Rows and columns represent nodes (genres)
- Entry G[i,j] represents the weight of the edge between genre i and genre j
- For our case: G[i,j] = number of artists who have both genre i and genre j

### One-Mode Projection (Simplified)

Our problem involves a **one-mode projection** of a bipartite network:

1. **Bipartite Graph**: Has two disjoint sets of nodes
   - Set 1: Artists
   - Set 2: Genres
   - Edges: Artist ↔ Genre (if artist has that genre)

2. **Projection**: We project onto the genre space ONLY
   - Result: A unipartite network of genres
   - Edges represent **shared membership** (artists who have both genres)

This is a standard technique in network analysis, commonly used in:
- Co-authorship networks (authors sharing papers)
- Board interlocks (companies sharing board members)
- Genre networks (genres sharing artists) [1, 2, 3]

**Crucially**: We do NOT need artist-artist collaborations for this network. We only need to know which genres each artist has.

---

## Matrix Representation

We use only ONE matrix to represent our data:

### Matrix A: Artist-Genre Matrix
**Dimensions**: n_artists × n_genres

A binary matrix where:
- **Rows** = Artists
- **Columns** = Genres (all sub-genres and main genres)
- **A[i,j]** = 1 if artist i has genre j, 0 otherwise

**Example**:
```
                 pop   hip_hop   rap   dance_pop   r&b   trap
Post Malone       1      1       1        0        0      0
Ariana Grande     1      0       0        1        0      0
The Weeknd        1      0       0        0        1      0
Travis Scott      0      1       1        0        0      1
```

### Matrix G: Genre-Genre Co-Occurrence Matrix (Output)
**Dimensions**: n_genres × n_genres

Our goal matrix where:
- **Rows** = Genres
- **Columns** = Genres
- **G[i,j]** = Number of artists who have BOTH genre i and genre j

**Example Output**:
```
           pop   hip_hop   rap   dance_pop   r&b   trap
pop         3      1       1        1        1      0
hip_hop     1      2       2        0        0      1
rap         1      2       2        0        0      1
dance_pop   1      0       0        1        0      0
r&b         1      0       0        0        1      0
trap        0      1       1        0        0      1
```

Interpretation:
- **G[pop, hip_hop] = 1**: One artist (Post Malone) has both "pop" and "hip hop"
- **G[hip_hop, rap] = 2**: Two artists (Post Malone, Travis Scott) have both "hip hop" and "rap"
- **G[pop, pop] = 3**: Three artists (Post Malone, Ariana Grande, The Weeknd) have "pop"

---

## Matrix Multiplication Logic

### The Formula

To compute the genre co-occurrence matrix:

**G = A^T × A**

Where:
- **A**: Artist-Genre matrix (n_artists × n_genres)
- **A^T**: Transpose of A (n_genres × n_artists)
- **G**: Genre-Genre co-occurrence matrix (n_genres × n_genres)

### Step-by-Step Breakdown

#### Understanding A^T (Transpose)
When we transpose A, we flip rows and columns:

**Original A** (4 artists × 6 genres):
```
                 pop   hip_hop   rap   dance_pop   r&b   trap
Post Malone       1      1       1        0        0      0
Ariana Grande     1      0       0        1        0      0
The Weeknd        1      0       0        0        1      0
Travis Scott      0      1       1        0        0      1
```

**A^T** (6 genres × 4 artists):
```
           Post_Malone   Ariana_Grande   The_Weeknd   Travis_Scott
pop             1              1             1             0
hip_hop         1              0             0             1
rap             1              0             0             1
dance_pop       0              1             0             0
r&b             0              0             1             0
trap            0              0             0             1
```

#### Computing G = A^T × A

**Result dimensions**: (n_genres × n_artists) × (n_artists × n_genres) = **n_genres × n_genres**

For entry G[i,j], we compute:
```
G[i,j] = Σ (A^T[i, k] × A[k, j])
       k=1 to n_artists

     = Σ (A[k, i] × A[k, j])
       k=1 to n_artists
```

**Translation**: Sum over all artists k. For each artist, if they have BOTH genre i (A[k,i] = 1) AND genre j (A[k,j] = 1), add 1 to the count.

#### Example Calculation

Let's compute **G["pop", "hip_hop"]**:

```
G["pop", "hip_hop"] = Σ (A[artist, "pop"] × A[artist, "hip_hop"])
                      all artists

= (1 × 1)  [Post Malone: has both]
+ (1 × 0)  [Ariana Grande: has pop but not hip hop]
+ (1 × 0)  [The Weeknd: has pop but not hip hop]
+ (0 × 1)  [Travis Scott: has hip hop but not pop]

= 1
```

**Result**: 1 artist (Post Malone) has both "pop" and "hip hop".

Let's compute **G["hip_hop", "rap"]**:

```
G["hip_hop", "rap"] = Σ (A[artist, "hip_hop"] × A[artist, "rap"])
                      all artists

= (1 × 1)  [Post Malone: has both]
+ (0 × 0)  [Ariana Grande: has neither]
+ (0 × 0)  [The Weeknd: has neither]
+ (1 × 1)  [Travis Scott: has both]

= 2
```

**Result**: 2 artists (Post Malone, Travis Scott) have both "hip hop" and "rap".

### Mathematical Proof

For genres g₁ and g₂, the entry G[g₁, g₂] counts:

```
G[g₁, g₂] = Σ A^T[g₁, a] × A[a, g₂]
            a=1 to n_artists

          = Σ A[a, g₁] × A[a, g₂]
            a=1 to n_artists
```

Since A is binary (0 or 1):
- A[a, g₁] × A[a, g₂] = 1 **only if** artist a has BOTH genre g₁ AND genre g₂
- Otherwise it equals 0

Therefore:
**G[g₁, g₂] = count of artists who have both genre g₁ and genre g₂**

This is exactly what we want!

---

## Why No Collaboration Matrix Is Needed

### The Key Difference

**Previous (incorrect) approach**: G = A^T × **C** × A
- Required: Artist collaboration data (who collaborated with whom)
- Measured: Cross-genre collaborations (artist from genre A collaborating with artist from genre B)
- Problem: Not what the reference visualization shows

**Correct approach**: G = A^T × A
- Required: ONLY artist genre data (who has which genres)
- Measured: Genre co-occurrence (artists who have multiple genres simultaneously)
- Result: Matches the reference visualization

### Why C (Collaboration Matrix) Would Be Wrong

If we included the collaboration matrix C, we would be asking:
> "How many times did artists from genre A collaborate with artists from genre B?"

But that's **not** what we want. We want:
> "How many artists are tagged with BOTH genre A and genre B?"

These are fundamentally different questions:

#### Example Illustrating the Difference

**Scenario**:
- Post Malone: ["pop", "hip hop"]
- Swae Lee: ["hip hop", "trap"]
- They collaborate on "Sunflower"

**With C (collaboration approach)**:
- Creates edge: "pop" ↔ "trap" (weight +1, because Post has pop and Swae has trap)
- Creates edge: "pop" ↔ "hip hop" (weight +1, because Post has both)
- Creates edge: "hip hop" ↔ "trap" (weight +1, because Swae has both)

**Without C (co-occurrence approach)**:
- Creates edge: "pop" ↔ "hip hop" (weight +1, because Post has both)
- Creates edge: "hip hop" ↔ "trap" (weight +1, because Swae has both)
- Does **NOT** create edge: "pop" ↔ "trap" (no single artist has both)

### The Correct Interpretation

The **co-occurrence approach (A^T × A)** tells us about:
1. **Genre hybridization**: Which genres commonly appear together in the same artist's profile
2. **Artist versatility**: How many artists span multiple genres
3. **Genre proximity**: Which genres are conceptually close (often combined)

This is what the reference visualization shows: "edges represent the co-listing by the same musicians."

### Why This Matters

Genre co-occurrence reveals:
- **Natural genre boundaries**: Genres that are never combined are conceptually distant
- **Emerging hybrid genres**: New combinations that appear over time (e.g., "emo rap")
- **Genre evolution**: How genres merge, split, or cross-pollinate through multi-genre artists

We don't need collaboration data because we're studying **genre definitions** (how artists self-identify or are categorized), not **artist interactions**.

---

## SQL Implementation

Since BigQuery doesn't support explicit matrix multiplication, we implement G = A^T × A using JOINs and aggregations.

### Query: Genre Co-Occurrence Network (All Time)

```sql
-- Step 1: Extract artist-genre relationships (Matrix A)
WITH artist_genres AS (
  SELECT
    a.name AS artist,
    genre,
    a.main_genre
  FROM `your-project-id.your-dataset.musicoset_artists_cleaned` a
  CROSS JOIN UNNEST(
    ARRAY_CONCAT(
      REGEXP_EXTRACT_ALL(a.genres, r"'([^']+)'"),
      [a.main_genre]
    )
  ) AS genre
),

-- Step 2: Self-join to create genre pairs (A^T × A)
-- For each artist, create all pairs of their genres
genre_pairs AS (
  SELECT
    ag1.genre AS genre_1,
    ag2.genre AS genre_2,
    ag1.artist
  FROM artist_genres ag1
  INNER JOIN artist_genres ag2
    ON ag1.artist = ag2.artist
  WHERE ag1.genre <= ag2.genre  -- Avoid duplicate pairs and maintain consistency
)

-- Step 3: Count co-occurrences (result is Matrix G)
SELECT
  genre_1,
  genre_2,
  COUNT(DISTINCT artist) AS co_occurrence_count
FROM genre_pairs
GROUP BY genre_1, genre_2
ORDER BY co_occurrence_count DESC;
```

### How SQL Implements A^T × A

**Step 1: Create Matrix A**
- `artist_genres` CTE extracts all artist-genre relationships
- Each row represents A[artist, genre] = 1

**Step 2: Self-Join (Implements Multiplication)**
- We join `artist_genres` with itself on the same artist
- For each artist, this creates all pairs of genres they have
- This is equivalent to computing A[artist, genre_1] × A[artist, genre_2]
- When both are 1 (artist has both genres), we get a pair

**Step 3: Aggregation**
- `COUNT(DISTINCT artist)` sums across all artists
- This gives us G[genre_1, genre_2]

### Query Optimization Notes

- **WHERE ag1.genre <= ag2.genre**: Ensures we only get each pair once (and includes diagonal)
  - "pop" ↔ "hip hop" (included)
  - "hip hop" ↔ "pop" (excluded, it's the same pair)
  - "pop" ↔ "pop" (included, shows how many artists have pop)

- **DISTINCT artist**: Ensures each artist is counted only once per genre pair

- **Time Complexity**: O(n_artists × avg_genres_per_artist²)

---

## Yearly Evolution (2000-2023)

To track genre evolution, we create **23 separate networks**, one for each year from 2000 to 2023.

### Approach

For each year:
1. Filter to artists who appeared on Billboard charts that year
2. Compute the genre co-occurrence matrix for those artists
3. Export as a separate network graph

This shows:
- Which genres were popular each year
- How genre combinations changed over time
- Emerging vs. declining genre pairings

### SQL Query: Yearly Genre Networks

```sql
-- Step 1: Get artists who appeared on Billboard each year
WITH artists_per_year AS (
  SELECT DISTINCT
    band_singer AS artist,
    year
  FROM `your-project-id.your-dataset.billboard_24years_lyrics_spotify_bigquery`
),

-- Step 2: Extract genre data for all artists
artist_genres AS (
  SELECT
    a.name AS artist,
    genre,
    a.main_genre
  FROM `your-project-id.your-dataset.musicoset_artists_cleaned` a
  CROSS JOIN UNNEST(
    ARRAY_CONCAT(
      REGEXP_EXTRACT_ALL(a.genres, r"'([^']+)'"),
      [a.main_genre]
    )
  ) AS genre
),

-- Step 3: Join to get genres for artists active each year
artist_genres_by_year AS (
  SELECT
    y.year,
    ag.artist,
    ag.genre,
    ag.main_genre
  FROM artists_per_year y
  INNER JOIN artist_genres ag
    ON TRIM(LOWER(y.artist)) = TRIM(LOWER(ag.artist))
),

-- Step 4: Create genre pairs per year
genre_pairs_by_year AS (
  SELECT
    ag1.year,
    ag1.genre AS genre_1,
    ag2.genre AS genre_2,
    ag1.artist
  FROM artist_genres_by_year ag1
  INNER JOIN artist_genres_by_year ag2
    ON ag1.artist = ag2.artist
    AND ag1.year = ag2.year
  WHERE ag1.genre <= ag2.genre
)

-- Step 5: Count co-occurrences per year
SELECT
  year,
  genre_1,
  genre_2,
  COUNT(DISTINCT artist) AS co_occurrence_count
FROM genre_pairs_by_year
GROUP BY year, genre_1, genre_2
ORDER BY year, co_occurrence_count DESC;
```

### Analyzing Temporal Trends

**Export one file per year**:
```sql
-- For year 2000
SELECT genre_1, genre_2, co_occurrence_count
FROM (... above query ...)
WHERE year = 2000;

-- For year 2001
SELECT genre_1, genre_2, co_occurrence_count
FROM (... above query ...)
WHERE year = 2001;

-- ... repeat for 2002-2023
```

**Or export all years and filter in visualization tool**:
- Export the full result with year column
- Use Gephi, NetworkX, or D3.js to create animated visualizations
- Show network evolution over time

### Insights from Yearly Networks

By comparing networks year-over-year, you can observe:

1. **Genre emergence**: New genres appearing (e.g., "emo rap" in 2017-2018)
2. **Genre fusion**: Increasing connections between previously separate genres
3. **Mainstream shifts**: Changes in which genres dominate the Billboard charts
4. **Cultural moments**: Spikes in specific genre pairings during cultural movements

---

## Main Genre Clustering and Coloring

### Purpose

In the reference visualization, "nodal colors indicate major genres." This helps identify:
- **Genre families**: Sub-genres that belong to the same main genre (e.g., "dance pop", "electropop" → "pop")
- **Cross-family connections**: Edges between sub-genres of different main genres
- **Dominant families**: Which main genre families have the most sub-genres

### Approach

Each sub-genre can be associated with one or more **main genre categories**. We use the `main_genre` field from the artist data to assign colors.

### Mapping Sub-Genres to Main Genres

**Challenge**: A sub-genre might not have a direct main genre in our data.

**Solution**: Use the `main_genre` field from artists:
- For each sub-genre, identify which main genres the artists with that sub-genre have
- Assign the most common main genre as the color

### SQL Query: Genre to Main Genre Mapping

```sql
WITH artist_genres AS (
  SELECT
    a.name AS artist,
    a.main_genre,
    genre AS sub_genre
  FROM `your-project-id.your-dataset.musicoset_artists_cleaned` a
  CROSS JOIN UNNEST(
    ARRAY_CONCAT(
      REGEXP_EXTRACT_ALL(a.genres, r"'([^']+)'"),
      [a.main_genre]
    )
  ) AS genre
),

-- For each sub-genre, find the most common main genre
genre_main_genre_mapping AS (
  SELECT
    sub_genre,
    main_genre,
    COUNT(DISTINCT artist) AS artist_count
  FROM artist_genres
  GROUP BY sub_genre, main_genre
),

ranked_mappings AS (
  SELECT
    sub_genre,
    main_genre,
    artist_count,
    ROW_NUMBER() OVER (PARTITION BY sub_genre ORDER BY artist_count DESC) AS rank
  FROM genre_main_genre_mapping
)

-- Get the primary main genre for each sub-genre
SELECT
  sub_genre,
  main_genre AS primary_main_genre,
  artist_count
FROM ranked_mappings
WHERE rank = 1
ORDER BY sub_genre;
```

### Color Palette Recommendations

Based on common music genre families:

| Main Genre | Color | Hex Code |
|-----------|-------|----------|
| pop | Pink/Magenta | #E91E63 |
| rock | Red/Burgundy | #C62828 |
| hip hop | Blue | #1976D2 |
| r&b | Purple | #7B1FA2 |
| electronic | Cyan | #00BCD4 |
| country | Orange | #F57C00 |
| latin | Yellow | #FBC02D |
| metal | Dark Gray | #424242 |
| jazz | Green | #388E3C |
| folk | Brown | #795548 |
| indie | Teal | #00897B |

### Visualization Workflow

1. **Export genre network** (genre_1, genre_2, co_occurrence_count)
2. **Export genre-color mapping** (sub_genre, primary_main_genre)
3. **In visualization tool** (Gephi, NetworkX, D3.js):
   - Load network as graph
   - Join color mapping to nodes
   - Apply color palette based on primary_main_genre
   - Optionally: size nodes by degree or betweenness centrality

### Example: Gephi Workflow

```python
import pandas as pd
import networkx as nx

# Load data
edges = pd.read_csv('genre_network_2023.csv')  # genre_1, genre_2, co_occurrence_count
colors = pd.read_csv('genre_colors.csv')       # sub_genre, primary_main_genre

# Create graph
G = nx.Graph()
for _, row in edges.iterrows():
    G.add_edge(row['genre_1'], row['genre_2'], weight=row['co_occurrence_count'])

# Add node colors
color_map = {
    'pop': '#E91E63',
    'rock': '#C62828',
    'hip hop': '#1976D2',
    # ... etc
}

for node in G.nodes():
    main_genre = colors[colors['sub_genre'] == node]['primary_main_genre'].values[0]
    G.nodes[node]['color'] = color_map.get(main_genre, '#9E9E9E')  # Gray as default

# Export to Gephi format
nx.write_gexf(G, 'genre_network_2023.gexf')
```

### Interpretation

**Clusters of same color** indicate:
- Sub-genres within the same main genre family
- Strong internal connections (many artists combine these sub-genres)

**Edges between different colors** indicate:
- Cross-genre influence
- Artists who blend multiple main genre families
- Potential for genre fusion and innovation

---

## References

[1] Newman, M. E. J. (2001). "Scientific collaboration networks. I. Network construction and fundamental results." *Physical Review E*, 64(1), 016131. https://doi.org/10.1103/PhysRevE.64.016131

[2] Borgatti, S. P., & Everett, M. G. (1997). "Network analysis of 2-mode data." *Social Networks*, 19(3), 243-269. https://doi.org/10.1016/S0378-8733(96)00301-2

[3] Latapy, M., Magnien, C., & Del Vecchio, N. (2008). "Basic notions for the analysis of large two-mode networks." *Social Networks*, 30(1), 31-48. https://doi.org/10.1016/j.socnet.2007.04.006

[4] Wasserman, S., & Faust, K. (1994). *Social Network Analysis: Methods and Applications*. Cambridge University Press.

[5] Barabási, A. L. (2016). *Network Science*. Cambridge University Press. Available online: http://networksciencebook.com/

[6] Park, M., Thom, J., Mennicken, S., Cramer, H., & Macy, M. (2019). "Global music streaming data reveal cross-cultural correlations." *Frontiers in Psychology*, 10, 1873. https://doi.org/10.3389/fpsyg.2019.01873

[7] Interiano, M., Kazemi, K., Wang, L., Yang, J., Yu, Z., & Komarova, N. L. (2018). "Musical trends and predictability of success in contemporary songs in and out of the top charts." *Royal Society Open Science*, 5(5), 171274. https://doi.org/10.1098/rsos.171274

[8] Csardi, G., & Nepusz, T. (2006). "The igraph software package for complex network research." *InterJournal, Complex Systems*, 1695. https://igraph.org

[9] Hagberg, A., Swart, P., & S Chult, D. (2008). "Exploring network structure, dynamics, and function using NetworkX." *Proceedings of the 7th Python in Science Conference (SciPy2008)*, 11-15.

---

## Additional Resources

### Visualization Tools
- **NetworkX** (Python): https://networkx.org/
- **Gephi**: https://gephi.org/ (recommended for network visualization)
- **D3.js Force-Directed Graphs**: https://d3js.org/
- **Cytoscape**: https://cytoscape.org/
- **igraph** (R): https://igraph.org/r/

### Further Reading
- Network Science textbook: http://networksciencebook.com/
- Stanford CS224W (Network Analysis): http://web.stanford.edu/class/cs224w/
- "Networks, Crowds, and Markets" by Easley & Kleinberg: https://www.cs.cornell.edu/home/kleinber/networks-book/
- Music Genre Networks research: https://arxiv.org/abs/1502.07715

### Color Palettes
- Material Design Colors: https://materialui.co/colors
- ColorBrewer (for categorical data): https://colorbrewer2.org/
- Color Oracle (colorblind-safe): https://colororacle.org/

---

*Document updated: 2025-01-20*
*Project: Music Genre Co-Occurrence Network Analysis*
*Corrected approach: G = A^T × A (genre co-occurrence, not collaboration)*
