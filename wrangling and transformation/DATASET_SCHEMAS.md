# Dataset Schemas Reference

Quick reference for all generated datasets from Billboard & MusicoSet data wrangling.

---

## Dataset 1: billboard_master.csv

**Purpose:** Song-level master dataset
**Rows:** 3,397 (one per Billboard song)
**Size:** 8.9 MB

### Schema

| Column | Type | Nulls | Description |
|--------|------|-------|-------------|
| `ranking` | int | 0% | Billboard chart position (1-100) |
| `song` | string | 0% | Song title |
| `band_singer` | string | 0% | Artist name(s) as listed on Billboard |
| `year` | int | 0% | Year song appeared on charts |
| `lyrics` | string | 0% | Full song lyrics |
| `main_genre` | string | 11% | Primary genre from MusicoSet |
| `genres` | string | 11% | Full genre list as string (e.g., "['pop', 'dance pop']") |
| `word_count` | float | 0% | Total words in lyrics |
| `unique_words` | float | 0% | Distinct words in lyrics |
| `ttr` | float | 0% | Type-token ratio (unique_words / word_count) |
| `artist_list` | string | 0% | Parsed artist list (Python list as string) |
| `num_artists` | int | 0% | Number of artists on song (1-5) |
| `is_collab` | bool | 0% | TRUE if multiple artists |

### Key Points
- **One row per song** (deduplicated from join)
- **100% lyrics coverage** - all songs have lyrics
- **89% genre coverage** - 11% couldn't match genres
- Collaborations identified but not split (see `song_artists.csv` for artist-level)

### Example Row
```python
{
    'ranking': 81,
    'song': '#Beautiful',
    'band_singer': 'Mariah Carey',
    'year': 2013,
    'word_count': 305,
    'unique_words': 89,
    'ttr': 0.292,
    'main_genre': 'dance pop',
    'num_artists': 1,
    'is_collab': False
}
```

---

## Dataset 2: song_artists.csv ⭐

**Purpose:** Artist-level dataset (exploded from collaborations)
**Rows:** 3,420 (one per artist appearance)
**Size:** 439 KB

### Schema

| Column | Type | Nulls | Description |
|--------|------|-------|-------------|
| `song_id` | int | 0% | Unique song identifier (row index from billboard_master) |
| `song_name` | string | 0% | Song title |
| `year` | int | 0% | Year |
| `ranking` | int | 0% | Billboard chart position |
| `artist_name` | string | 0% | Individual artist name (parsed from collaboration) |
| `artist_position` | int | 0% | Order in collaboration (1 = first, 2 = second, etc.) |
| `artist_role` | string | 0% | "primary", "featured", or "collaboration" |
| `word_count` | float | 0% | Song's word count (duplicated across artists) |
| `artist_genre` | string | 6% | This artist's genre from MusicoSet |
| `artist_genres` | string | 12% | This artist's full genre list |
| `match_method` | string | 0% | "artist_name" or "lyrics_0.XX" (similarity score) |

### Key Points
- **Artist-level granularity** - collaborations are split
- Song "A feat. B" creates 2 rows (one per artist)
- Each artist gets their own genre
- Enables cross-genre collaboration analysis
- **94% artist genre coverage** (6% null)

### Example Rows
```python
# Same song, two rows for collaboration
{'song_id': 1, 'song_name': 'Smooth', 'artist_name': 'Santana',
 'artist_position': 1, 'artist_role': 'primary', 'artist_genre': 'blues-rock'}

{'song_id': 1, 'song_name': 'Smooth', 'artist_name': 'Rob Thomas',
 'artist_position': 2, 'artist_role': 'featured', 'artist_genre': 'acoustic pop'}
```

### Cross-Genre Analysis Example
```python
# Find cross-genre collaborations
df = pd.read_csv('song_artists.csv')
collabs = df[df.duplicated('song_id', keep=False)]
cross_genre = collabs.groupby('song_id').filter(lambda x: x['artist_genre'].nunique() > 1)
```

---

## Dataset 3: temporal_trends.csv

**Purpose:** Year × Genre aggregations
**Rows:** 754 (year-genre combinations)
**Size:** 44 KB

### Schema

| Column | Type | Nulls | Description |
|--------|------|-------|-------------|
| `year` | int | 0% | Year (2000-2023) |
| `genre` | string | 0% | Genre name |
| `song_count` | int | 0% | Number of songs in this year/genre |
| `avg_words` | float | 0% | Average word count |
| `avg_ttr` | float | 0% | Average type-token ratio (lexical diversity) |
| `collab_count` | int | 0% | Number of collaborations |
| `avg_artists` | float | 0% | Average number of artists per song |
| `genre_pct` | float | 0% | Percentage of year's songs (within-year %) |
| `collab_rate` | float | 0% | Percentage of songs that are collaborations |

### Key Points
- **Grouped by year AND genre**
- Genre percentages sum to 100% within each year
- Songs without genres excluded from aggregation
- Genre "-" means unclassified in MusicoSet

### Example Row
```python
{
    'year': 2020,
    'genre': 'dance pop',
    'song_count': 45,
    'avg_words': 312.5,
    'avg_ttr': 0.285,
    'collab_count': 18,
    'genre_pct': 28.3,  # 28.3% of 2020 songs
    'collab_rate': 40.0  # 40% of dance pop songs are collabs
}
```

### Analysis Examples
```python
# Genre dominance over time
df.pivot(index='year', columns='genre', values='genre_pct')

# Collaboration trends
df.groupby('year')['collab_rate'].mean().plot()

# Lexical complexity by genre
df.groupby('genre')['avg_ttr'].mean().sort_values()
```

---

## Dataset 4: artist_profiles.csv

**Purpose:** MusicoSet artist metadata (reference data)
**Rows:** 11,518 (all MusicoSet artists)
**Size:** 1.9 MB

### Schema

| Column | Type | Nulls | Description |
|--------|------|-------|-------------|
| `artist_id` | string | 0% | Spotify artist ID |
| `name` | string | 0% | Artist name |
| `followers` | float | 0% | Spotify follower count |
| `popularity` | int | 0% | Spotify popularity score (0-100) |
| `artist_type` | string | 0% | "singer", "rapper", "band", etc. |
| `main_genre` | string | 0% | Primary genre |
| `genres` | string | 0% | Full genre list as string |
| `image_url` | string | 0% | Spotify artist image URL |

### Key Points
- **Reference data** from MusicoSet (not generated by our wrangling)
- Used for joining to get genre information
- Not all artists appear in Billboard dataset
- ~3,000 of these artists matched to Billboard songs

### Example Row
```python
{
    'artist_id': '66CXWjxzNUsdJxJ2JdwvnR',
    'name': 'Ariana Grande',
    'followers': 34554242.0,
    'popularity': 96,
    'artist_type': 'singer',
    'main_genre': 'dance pop',
    'genres': "['dance pop', 'pop', 'post-teen pop']"
}
```

---

## Dataset 5: genre_network.csv

**Purpose:** Genre co-occurrence patterns
**Rows:** 6,316 (unique genre pairs)
**Size:** 218 KB

### Schema

| Column | Type | Nulls | Description |
|--------|------|-------|-------------|
| `genre1` | string | 0% | First genre (alphabetically) |
| `genre2` | string | 0% | Second genre (alphabetically) |
| `years_together` | int | 0% | Number of years both genres appeared |
| `first_year` | int | 0% | First year of co-occurrence |
| `last_year` | int | 0% | Last year of co-occurrence |

### Key Points
- **Genre pairs only** - genres that appeared in same years
- Pairs are ordered alphabetically (no duplicates: A-B and B-A)
- Higher `years_together` = stronger relationship
- Used for network analysis and genre clustering

### Example Row
```python
{
    'genre1': 'dance pop',
    'genre2': 'pop',
    'years_together': 24,  # Appeared together all 24 years
    'first_year': 2000,
    'last_year': 2023
}
```

### Analysis Examples
```python
# Strongest genre relationships
df.sort_values('years_together', ascending=False).head(20)

# Emerging genre pairs (recent first_year)
df[df['first_year'] >= 2020]

# Genre clustering
# Create adjacency matrix for network graph
import networkx as nx
G = nx.from_pandas_edgelist(df, 'genre1', 'genre2', ['years_together'])
```

---

## Data Relationships

```
billboard_master (3,397 songs)
    ├─→ song_artists (3,420 artist appearances)
    │   └─→ artist_profiles (11,518 artists in MusicoSet)
    │
    ├─→ temporal_trends (754 year-genre combos)
    │
    └─→ genre_network (6,316 genre pairs)
```

### Join Keys

**billboard_master ↔ song_artists:**
```python
# song_artists.song_id references billboard_master row index
df_master = pd.read_csv('billboard_master.csv')
df_artists = pd.read_csv('song_artists.csv')
merged = df_artists.merge(df_master, left_on='song_id', right_index=True)
```

**song_artists ↔ artist_profiles:**
```python
# Join on artist name (case-insensitive)
df_artists = pd.read_csv('song_artists.csv')
df_profiles = pd.read_csv('artist_profiles.csv')
merged = df_artists.merge(
    df_profiles,
    left_on=df_artists['artist_name'].str.lower(),
    right_on=df_profiles['name'].str.lower()
)
```

---

## Common Data Issues

### 1. Genre Nulls
- **billboard_master:** 11% null (376 songs)
- **song_artists:** 6% null (205 artists)
- **Reason:** Artist name mismatch or not in MusicoSet
- **Handling:** Filter with `.notna()` when genre is required

### 2. Genre "-" (Dash)
- Means "unclassified" in MusicoSet
- Appears in temporal_trends and genre_network
- Can filter: `df[df['genre'] != '-']`

### 3. Genres as Strings
- `genres` column is a string representation of Python list
- Parse with: `import ast; ast.literal_eval(genre_string)`
- Example: `"['pop', 'dance pop']"` → `['pop', 'dance pop']`

### 4. Match Method
- In `song_artists.csv`, shows how genre was matched
- `"artist_name"` = matched by artist name (90% of cases)
- `"lyrics_0.XX"` = matched by lyrics with XX% similarity (10% of cases)
- Higher similarity score = more confident match

---

## Quick Stats

| Dataset | Rows | Avg Row Size | Coverage |
|---------|------|--------------|----------|
| billboard_master | 3,397 | 2.6 KB | 100% of Billboard songs |
| song_artists | 3,420 | 128 bytes | 94% have genres |
| temporal_trends | 754 | 58 bytes | 100% (nulls filtered) |
| artist_profiles | 11,518 | 165 bytes | MusicoSet reference |
| genre_network | 6,316 | 35 bytes | 100% (nulls filtered) |

---

## Usage Examples

### Find cross-genre collaborations
```python
df = pd.read_csv('song_artists.csv')
collabs = df.groupby('song_id').filter(lambda x: len(x) > 1 and x['artist_genre'].nunique() > 1)
print(f"Cross-genre collaborations: {collabs['song_id'].nunique()}")
```

### Genre dominance timeline
```python
df = pd.read_csv('temporal_trends.csv')
pivot = df.pivot_table(index='year', columns='genre', values='genre_pct', fill_value=0)
pivot.plot(kind='area', stacked=True, figsize=(12,6))
```

### Artist collaboration network
```python
df_songs = pd.read_csv('song_artists.csv')
collabs = df_songs[df_songs.duplicated('song_id', keep=False)]
pairs = collabs.groupby('song_id').apply(
    lambda x: list(combinations(x['artist_name'], 2))
).explode().value_counts()
```

### Lexical complexity vs chart position
```python
df = pd.read_csv('billboard_master.csv')
df.plot.scatter(x='ranking', y='ttr', alpha=0.5)
```

---

## Data Lineage

```
Source: billboard_24years_lyrics_spotify.csv (3,397 songs)
        musicoset_metadata/artists.csv (11,518 artists)

↓ SQL deduplication + Python parsing

Generated: billboard_master.csv (3,397 rows)
           └─→ Parse artists + Match genres
               └─→ song_artists.csv (3,420 rows)

↓ Aggregation (SQL GROUP BY)

Generated: temporal_trends.csv (754 rows)
           artist_profiles.csv (copied from source)
           genre_network.csv (6,316 rows)
```

**Processing:** ~30 seconds on standard laptop
**Total size:** 11.5 MB (all 5 CSVs)

---

## Notes

- **Dates:** All data spans 2000-2023 (24 years)
- **Genres:** ~120 unique genres across datasets
- **Update frequency:** Static snapshot (not live data)
- **Encoding:** UTF-8 with proper handling of special characters
- **Missing lyrics:** 0 (100% coverage in Billboard dataset)
- **Duplicates:** None (deduplicated during processing)
