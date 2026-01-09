# =============================================================================
# Billboard Lyrics & Genre Analysis
# =============================================================================
# Compiled from project notebooks. Run sections independently or source all.
#
# Pipeline:
#   1. Exploration    - initial look at the data
#   2. Cleaning       - standardize formats, fix NAs
#   3. Transformation - compute lexical metrics
#   4. Analysis       - statistical analysis of lyrics
#   5. Genre Network  - co-occurrence network
# =============================================================================

# =============================================================================
# Packages
# =============================================================================

packages <- c(
  "tidyverse", "readr", "stringr",
  "tidytext",
  "ggplot2", "scales", "viridis", "gridExtra", "corrplot", "patchwork",
  "igraph", "ggraph", "GGally", "network", "sna", "intergraph",
  "naniar", "visdat",
  "gganimate", "gifski",
  "xml2", "ggalluvial"
)

new_packages <- packages[!(packages %in% installed.packages()[,"Package"])]
if(length(new_packages)) {
  cat("Installing:", paste(new_packages, collapse = ", "), "\n")
  install.packages(new_packages)
}

library(tidyverse)
library(ggplot2)
theme_set(theme_minimal())


# =============================================================================
# 1. Exploratory Analysis
# =============================================================================

run_exploratory_analysis <- function() {

  cat("\n", strrep("=", 60), "\n")
  cat("SECTION 1: EXPLORATORY ANALYSIS\n")
  cat(strrep("=", 60), "\n\n")

  library(tidytext)
  library(gridExtra)

  # Load data
  df <- read_csv('data/billboard_24years_lyrics_spotify.csv', show_col_types = FALSE)
  cat(sprintf("Loaded %d songs (%d-%d)\n", nrow(df), min(df$year), max(df$year)))

  # --- 1.1 Word Frequency ---
  cat("--- 1.1 Word Frequency Analysis ---\n")

  words_df <- df %>%
    select(year, ranking, lyrics) %>%
    filter(!is.na(lyrics), lyrics != "") %>%
    unnest_tokens(word, lyrics) %>%
    filter(!word %in% stop_words$word) %>%
    filter(nchar(word) > 2)

  word_counts <- words_df %>%
    count(word, sort = TRUE)

  cat(sprintf("Total words: %d, Unique: %d\n", nrow(words_df), nrow(word_counts)))
  cat("\nTop 20 words:\n")
  print(head(word_counts, 20))

  # --- 1.2 Lexical Complexity ---
  cat("\n--- 1.2 Lexical Complexity ---\n")

  calculate_metrics <- function(lyrics_text) {
    words <- lyrics_text %>%
      str_to_lower() %>%
      str_replace_all("[^a-z\\s]", "") %>%
      str_split("\\s+") %>%
      unlist()
    words <- words[words != ""]
    total <- length(words)
    unique_w <- length(unique(words))

    if (total > 0) {
      data.frame(
        total_words = total,
        unique_words = unique_w,
        lexical_diversity = unique_w / total,
        avg_word_length = mean(nchar(words))
      )
    } else {
      data.frame(total_words = 0, unique_words = 0, lexical_diversity = NA, avg_word_length = NA)
    }
  }

  df_lyrics <- df %>%
    filter(!is.na(lyrics), lyrics != "") %>%
    select(song, band_singer, year, ranking, lyrics)

  metrics_list <- lapply(df_lyrics$lyrics, calculate_metrics)
  metrics_df <- do.call(rbind, metrics_list)

  lyrics_metrics <- cbind(df_lyrics %>% select(-lyrics), metrics_df)

  cat("\nLexical Metrics Summary:\n")
  cat(sprintf("  Avg Total Words: %.0f\n", mean(lyrics_metrics$total_words, na.rm = TRUE)))
  cat(sprintf("  Avg Unique Words: %.0f\n", mean(lyrics_metrics$unique_words, na.rm = TRUE)))
  cat(sprintf("  Avg Lexical Diversity: %.3f\n", mean(lyrics_metrics$lexical_diversity, na.rm = TRUE)))
  cat(sprintf("  Avg Word Length: %.2f\n", mean(lyrics_metrics$avg_word_length, na.rm = TRUE)))

  # --- 1.3 Chart Performance Analysis ---
  cat("\n--- 1.3 Chart Performance Analysis ---\n")

  lyrics_by_rank <- lyrics_metrics %>%
    mutate(rank_group = case_when(
      ranking <= 10 ~ "Top 10",
      ranking <= 25 ~ "11-25",
      ranking <= 50 ~ "26-50",
      ranking <= 75 ~ "51-75",
      TRUE ~ "76-100"
    ))

  rank_comparison <- lyrics_by_rank %>%
    group_by(rank_group) %>%
    summarise(
      n = n(),
      avg_diversity = mean(lexical_diversity, na.rm = TRUE),
      avg_repetition = 1 - mean(lexical_diversity, na.rm = TRUE),
      .groups = 'drop'
    )

  cat("\nMetrics by Rank Group:\n")
  print(rank_comparison)

  # Statistical test
  top10 <- lyrics_by_rank %>% filter(rank_group == "Top 10")
  bottom50 <- lyrics_by_rank %>% filter(rank_group %in% c("51-75", "76-100"))

  t_result <- t.test(top10$lexical_diversity, bottom50$lexical_diversity)
  cat(sprintf("\nTop 10 vs Bottom 50 (lexical diversity):\n"))
  cat(sprintf("  Top 10 mean: %.4f\n", mean(top10$lexical_diversity, na.rm = TRUE)))
  cat(sprintf("  Bottom 50 mean: %.4f\n", mean(bottom50$lexical_diversity, na.rm = TRUE)))
  cat(sprintf("  p-value: %.4f %s\n", t_result$p.value,
              ifelse(t_result$p.value < 0.05, "(significant)", "")))

  cat("\nExploratory analysis complete.\n")

  return(lyrics_metrics)
}


# =============================================================================
# 2. Data Cleaning
# =============================================================================

run_data_cleaning <- function() {

  cat("\n", strrep("=", 60), "\n")
  cat("SECTION 2: DATA CLEANING\n")
  cat(strrep("=", 60), "\n\n")

  # --- 2.1 MusicoSet Cleaning ---
  cat("--- 2.1 MusicoSet Metadata Cleaning ---\n")

  artists_in <- 'data/musicoset_metadata/artists.csv'
  songs_in <- 'data/musicoset_metadata/songs.csv'
  artists_out <- 'data/cleaned/musicoset_artists_cleaned.csv'
  songs_out <- 'data/cleaned/musicoset_songs_cleaned.csv'

  # Helper to fix dashes and empty brackets
  fix_dash <- function(x) {
    if(is.character(x)) {
      x <- ifelse(str_detect(x, "^-$"), NA_character_, x)
      x <- ifelse(str_detect(x, "^\\[\\]$"), NA_character_, x)
      x
    } else x
  }

  # Load and clean artists
  artists <- read_delim(artists_in, delim="\t", na=c("", "NA", "-"), show_col_types = FALSE)
  artists2 <- artists %>%
    mutate(across(where(is.character), str_trim)) %>%
    mutate(across(where(is.character), fix_dash))
  cat(sprintf("Artists: %d loaded, cleaned\n", nrow(artists2)))

  # Load and clean songs
  songs <- read_delim(songs_in, delim="\t", na=c("", "NA", "-"), show_col_types = FALSE)
  songs2 <- songs %>%
    mutate(across(where(is.character), str_trim)) %>%
    mutate(across(where(is.character), fix_dash))
  cat(sprintf("Songs: %d loaded, cleaned\n", nrow(songs2)))

  # Export
  dir.create("data/cleaned", showWarnings=FALSE, recursive=TRUE)
  write_csv(artists2, artists_out, na="", quote="needed")
  write_csv(songs2, songs_out, na="", quote="needed")
  cat(sprintf("Exported to: %s, %s\n", artists_out, songs_out))

  # --- 2.2 Lyrics Cleaning ---
  cat("\n--- 2.2 Lyrics Cleaning ---\n")

  lyrics_in <- 'data/musicoset_songfeatures/lyrics.csv'
  lyrics_out <- 'data/cleaned/musicoset_lyrics_cleaned.csv'

  if (file.exists(lyrics_in)) {
    lyrics <- read_delim(lyrics_in, delim="\t", show_col_types = FALSE)
    lyrics2 <- lyrics %>%
      mutate(across(where(is.character), function(x) {
        x <- str_replace_all(x, "\\n", " ")
        x <- str_replace_all(x, "\\r", "")
        x <- str_replace_all(x, "\\s+", " ")
        str_trim(x)
      }))
    write_csv(lyrics2, lyrics_out, na="", quote="all", eol="\n")
    cat(sprintf("Lyrics: %d cleaned and exported\n", nrow(lyrics2)))
  }

  # --- 2.3 Missing Data Analysis ---
  cat("\n--- 2.3 Missing Data Summary ---\n")

  library(naniar)

  billboard_file <- 'data/cleaned/billboard_24years_lyrics_spotify_bigquery.csv'
  if (file.exists(billboard_file)) {
    billboard <- read_csv(billboard_file, show_col_types = FALSE)
    cat(sprintf("Billboard: %d rows, %.1f%% missing cells\n",
                nrow(billboard),
                sum(is.na(billboard)) / (nrow(billboard) * ncol(billboard)) * 100))

    # Spotify features missingness
    spotify_miss <- sum(is.na(billboard$danceability)) / nrow(billboard) * 100
    cat(sprintf("Spotify features missing: %.1f%%\n", spotify_miss))
  }

  cat(sprintf("\nArtists missing data: artist_type=%.1f%%, main_genre=%.1f%%\n",
              sum(is.na(artists2$artist_type)) / nrow(artists2) * 100,
              sum(is.na(artists2$main_genre)) / nrow(artists2) * 100))

  cat("\nData cleaning complete.\n")

  return(list(artists = artists2, songs = songs2))
}


# =============================================================================
# 3. Lexical Transformation
# =============================================================================

run_lexical_transformation <- function() {

  cat("\n", strrep("=", 60), "\n")
  cat("SECTION 3: LEXICAL TRANSFORMATION\n")
  cat(strrep("=", 60), "\n\n")

  library(tidytext)

  # Load data
  df <- read_csv('data/cleaned/billboard_24years_lyrics_spotify_bigquery.csv', show_col_types = FALSE)
  cat(sprintf("Loaded %d songs\n", nrow(df)))

  # --- 3.1 Tokenization ---
  cat("--- 3.1 Tokenizing lyrics ---\n")

  tokens <- df %>%
    filter(!is.na(lyrics), lyrics != "") %>%
    select(song, band_singer, year, ranking, lyrics) %>%
    unnest_tokens(word, lyrics) %>%
    mutate(
      word = str_replace_all(word, "\\d+", ""),
      word = str_replace_all(word, "'s$", ""),
      word = str_replace_all(word, "[^a-z]", "")
    ) %>%
    filter(word != "", nchar(word) > 1)

  # Mark stop words
  data(stop_words)
  tokens <- tokens %>%
    mutate(is_stop = word %in% stop_words$word)

  cat(sprintf("Tokenized: %d words from %d songs\n",
              nrow(tokens), n_distinct(paste(tokens$song, tokens$band_singer))))

  # --- 3.2 Calculate Metrics ---
  cat("--- 3.2 Calculating lexical metrics ---\n")

  song_metrics <- tokens %>%
    group_by(song, band_singer, year, ranking) %>%
    summarise(
      total_words = n(),
      unique_words = n_distinct(word),
      content_words = sum(!is_stop),
      hapax = sum(table(word) == 1),
      .groups = 'drop'
    ) %>%
    mutate(
      ttr = unique_words / total_words,
      lexical_density = content_words / total_words,
      hapax_ratio = hapax / unique_words
    )

  cat(sprintf("Metrics calculated for %d songs\n", nrow(song_metrics)))

  # --- 3.3 Compression Ratio ---
  cat("--- 3.3 Calculating compression ratio ---\n")

  df_with_compression <- df %>%
    filter(!is.na(lyrics), lyrics != "") %>%
    rowwise() %>%
    mutate(
      original_size = nchar(lyrics),
      compressed_size = length(memCompress(charToRaw(lyrics), "gzip")),
      compression_ratio = compressed_size / original_size
    ) %>%
    ungroup() %>%
    select(song, band_singer, compression_ratio)

  song_metrics <- song_metrics %>%
    left_join(df_with_compression, by = c("song", "band_singer"))

  # --- 3.4 Add Genre Mapping ---
  cat("--- 3.4 Mapping genres ---\n")

  # Load genre mapping if exists
  mapping_file <- 'data/cleaned/genre_macro_mapping.csv'
  if (file.exists(mapping_file)) {
    genre_mapping <- read_csv(mapping_file, show_col_types = FALSE)

    # Join with main data
    df_full <- df %>%
      left_join(song_metrics, by = c("song", "band_singer", "year", "ranking"))

    cat(sprintf("Genre mapping loaded: %d genres\n", nrow(genre_mapping)))
  } else {
    df_full <- df %>%
      left_join(song_metrics, by = c("song", "band_singer", "year", "ranking"))
  }

  # --- 3.5 Summary ---
  cat("\n--- 3.5 Summary Statistics ---\n")
  cat(sprintf("TTR: mean=%.3f, median=%.3f\n",
              mean(song_metrics$ttr, na.rm=TRUE),
              median(song_metrics$ttr, na.rm=TRUE)))
  cat(sprintf("Lexical Density: mean=%.3f, median=%.3f\n",
              mean(song_metrics$lexical_density, na.rm=TRUE),
              median(song_metrics$lexical_density, na.rm=TRUE)))
  cat(sprintf("Compression Ratio: mean=%.3f, median=%.3f\n",
              mean(song_metrics$compression_ratio, na.rm=TRUE),
              median(song_metrics$compression_ratio, na.rm=TRUE)))

  cat("\nLexical transformation complete.\n")

  return(song_metrics)
}


# =============================================================================
# 4. Lexical Analysis
# =============================================================================

run_lexical_analysis <- function() {

  cat("\n", strrep("=", 60), "\n")
  cat("SECTION 4: LEXICAL ANALYSIS\n")
  cat(strrep("=", 60), "\n\n")

  library(scales)
  library(viridis)

  # Load analysis-ready data
  df <- read_csv('data/cleaned/billboard_lexical_analysis_ready.csv', show_col_types = FALSE)
  df_analysis <- df %>% filter(has_complete_data == TRUE)

  cat(sprintf("Total songs: %d\n", nrow(df)))
  cat(sprintf("Analysis set: %d (%.1f%%)\n", nrow(df_analysis), nrow(df_analysis)/nrow(df)*100))
  cat(sprintf("Years: %d-%d\n", min(df$year), max(df$year)))
  cat(sprintf("Genres: %d\n", n_distinct(df_analysis$macro_genre)))

  output_dir <- 'outputs/lexical_analysis'
  dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

  # --- 4.1 TTR Distribution ---
  cat("\n--- 4.1 TTR Distribution ---\n")

  p_ttr <- ggplot(df_analysis, aes(x = ttr)) +
    geom_histogram(bins = 40, fill = "steelblue", color = "white", alpha = 0.8) +
    geom_vline(xintercept = mean(df_analysis$ttr, na.rm = TRUE),
               color = "red", linetype = "dashed", linewidth = 1) +
    labs(title = "Distribution of Type-Token Ratio (TTR)",
         subtitle = sprintf("Mean = %.3f (red line)", mean(df_analysis$ttr, na.rm = TRUE)),
         x = "TTR", y = "Count") +
    theme_minimal()

  ggsave(file.path(output_dir, 'ttr_distribution.png'), p_ttr, width = 10, height = 6, dpi = 300)

  # --- 4.2 TTR by Genre ---
  cat("--- 4.2 TTR by Genre ---\n")

  genre_stats <- df_analysis %>%
    group_by(macro_genre) %>%
    summarise(
      n = n(),
      ttr_mean = mean(ttr, na.rm = TRUE),
      ttr_median = median(ttr, na.rm = TRUE),
      .groups = 'drop'
    ) %>%
    arrange(desc(ttr_mean))

  print(genre_stats)

  p_genre <- ggplot(df_analysis, aes(x = reorder(macro_genre, ttr, FUN = median), y = ttr, fill = macro_genre)) +
    geom_boxplot(alpha = 0.7, outlier.alpha = 0.3) +
    coord_flip() +
    scale_fill_viridis_d() +
    labs(title = "TTR Distribution by Genre",
         x = NULL, y = "Type-Token Ratio") +
    theme_minimal() +
    theme(legend.position = "none")

  ggsave(file.path(output_dir, 'ttr_by_genre.png'), p_genre, width = 10, height = 8, dpi = 300)

  # --- 4.3 Temporal Trends ---
  cat("--- 4.3 Temporal Trends ---\n")

  yearly_stats <- df_analysis %>%
    group_by(year) %>%
    summarise(
      n = n(),
      ttr_mean = mean(ttr, na.rm = TRUE),
      lexical_density_mean = mean(lexical_density, na.rm = TRUE),
      .groups = 'drop'
    )

  p_trend <- ggplot(yearly_stats, aes(x = year, y = ttr_mean)) +
    geom_line(color = "steelblue", linewidth = 1.2) +
    geom_point(color = "steelblue", size = 3) +
    geom_smooth(method = "lm", se = TRUE, color = "red", linetype = "dashed") +
    labs(title = "Lexical Diversity Over Time",
         x = "Year", y = "Mean TTR") +
    theme_minimal()

  ggsave(file.path(output_dir, 'ttr_over_time.png'), p_trend, width = 12, height = 6, dpi = 300)

  # Correlation with time
  cor_time <- cor.test(yearly_stats$year, yearly_stats$ttr_mean)
  cat(sprintf("TTR vs Year: r = %.3f, p = %.4f\n", cor_time$estimate, cor_time$p.value))

  # --- 4.4 Lexical Density vs TTR ---
  cat("--- 4.4 Lexical Density vs Diversity ---\n")

  p_scatter <- ggplot(df_analysis, aes(x = ttr, y = lexical_density, color = macro_genre)) +
    geom_point(alpha = 0.4, size = 1.5) +
    scale_color_viridis_d() +
    labs(title = "Lexical Density vs Type-Token Ratio",
         x = "TTR (Diversity)", y = "Lexical Density",
         color = "Genre") +
    theme_minimal()

  ggsave(file.path(output_dir, 'lexical_diversity_vs_density.png'), p_scatter, width = 12, height = 8, dpi = 300)

  # --- 4.5 Export Summary Tables ---
  cat("--- 4.5 Exporting Summary Tables ---\n")

  genre_summary <- df_analysis %>%
    group_by(macro_genre) %>%
    summarise(
      n_songs = n(),
      n_artists = n_distinct(band_singer),
      ttr_mean = round(mean(ttr, na.rm = TRUE), 4),
      ttr_median = round(median(ttr, na.rm = TRUE), 4),
      ttr_sd = round(sd(ttr, na.rm = TRUE), 4),
      lexical_density_mean = round(mean(lexical_density, na.rm = TRUE), 4),
      rare_word_ratio_mean = round(mean(rare_word_ratio, na.rm = TRUE), 4),
      compression_ratio_mean = round(mean(compression_ratio, na.rm = TRUE), 4),
      total_words_mean = round(mean(total_words, na.rm = TRUE), 1),
      .groups = 'drop'
    ) %>%
    arrange(desc(n_songs))

  write_csv(genre_summary, file.path(output_dir, 'lexical_analysis_summary_by_genre.csv'))
  cat(sprintf("Exported summary to: %s\n", file.path(output_dir, 'lexical_analysis_summary_by_genre.csv')))

  cat("\nLexical analysis complete.\n")

  return(list(df_analysis = df_analysis, genre_summary = genre_summary))
}


# =============================================================================
# 5. Genre Network Analysis
# =============================================================================

run_genre_analysis <- function() {

  cat("\n", strrep("=", 60), "\n")
  cat("SECTION 5: GENRE NETWORK ANALYSIS\n")
  cat(strrep("=", 60), "\n\n")

  library(igraph)
  library(ggraph)

  output_dir <- 'outputs/genre_network'
  dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
  dir.create(file.path(output_dir, 'non_image'), showWarnings = FALSE)

  # --- 5.1 Load Edge Data ---
  cat("--- 5.1 Loading network data ---\n")

  edges_file <- 'data/sql_query_out/QUERY 2_ Genre Co-Occurrence Network (All Time).csv'

  if (!file.exists(edges_file)) {
    cat("Edge file not found. Run BigQuery queries first.\n")
    return(NULL)
  }

  edges_all <- read_csv(edges_file, show_col_types = FALSE) %>%
    rename(from = genre_1, to = genre_2, weight = co_occurrence_count) %>%
    filter(from != to, weight >= 2)

  cat(sprintf("Loaded %d genre connections\n", nrow(edges_all)))

  # --- 5.2 Load Genre Mapping ---
  mapping_file <- 'data/sql_query_out/QUERY 5_ Genre to Main Genre Mapping (For Node Coloring).csv'

  if (file.exists(mapping_file)) {
    genre_mapping <- read_csv(mapping_file, show_col_types = FALSE) %>%
      mutate(primary_main_genre = tolower(trimws(primary_main_genre)))
    cat(sprintf("Loaded %d genre mappings\n", nrow(genre_mapping)))
  }

  # --- 5.3 Build Network ---
  cat("--- 5.3 Building network ---\n")

  all_genres <- unique(c(edges_all$from, edges_all$to))

  # Load macro mapping if available
  macro_mapping_file <- 'data/cleaned/genre_network_mapping.csv'
  if (file.exists(macro_mapping_file)) {
    macro_mapping <- read_csv(macro_mapping_file, show_col_types = FALSE)
  } else {
    macro_mapping <- tibble(micro_genre = all_genres, macro_genre = "OTHER")
  }

  nodes <- tibble(name = all_genres) %>%
    left_join(genre_mapping %>% select(sub_genre, artist_count),
              by = c('name' = 'sub_genre')) %>%
    left_join(macro_mapping, by = c('name' = 'micro_genre')) %>%
    mutate(
      artist_count = ifelse(is.na(artist_count), 1, artist_count),
      macro_genre = ifelse(is.na(macro_genre), 'OTHER', macro_genre)
    )

  cat(sprintf("Network: %d nodes, %d edges\n", nrow(nodes), nrow(edges_all)))

  # Create igraph
  g <- graph_from_data_frame(edges_all, directed = FALSE, vertices = nodes)

  # --- 5.4 Centrality Analysis ---
  cat("--- 5.4 Centrality analysis ---\n")

  hub_metrics <- tibble(
    genre = nodes$name,
    macro_genre = nodes$macro_genre,
    artists = nodes$artist_count,
    degree = degree(g),
    strength = strength(g),
    betweenness = betweenness(g, weights = 1/E(g)$weight)
  ) %>%
    arrange(desc(strength))

  cat("\nTop 15 Hub Genres:\n")
  print(head(hub_metrics, 15))

  # --- 5.5 Macro Genre Colors ---
  macro_genre_colors <- c(
    'POP' = '#f180a6ff',
    'ELECTRONIC' = '#d31f8eff',
    'R&B' = '#FF0800',
    'HIP HOP' = '#9D2A3A',
    'REGGAE' = '#FFB627',
    'LATIN' = '#E07B00',
    'BLUES' = '#1565C0',
    'JAZZ' = '#5C9CE6',
    'ROCK' = '#2832C2',
    'METAL' = '#1F456E',
    'FOLK' = '#6B8E4E',
    'COUNTRY' = '#7bac21ff',
    'CLASSICAL' = '#7B2D8E',
    'NEW AGE' = '#B57EDC',
    'AVANT-GARDE' = '#4A235A',
    'OTHER' = '#757575'
  )

  # --- 5.6 Hub Visualization ---
  cat("--- 5.6 Creating visualizations ---\n")

  p_hubs <- ggplot(head(hub_metrics, 25),
                   aes(x = reorder(genre, strength), y = strength, fill = macro_genre)) +
    geom_col() +
    coord_flip() +
    labs(title = 'Top 25 Hub Genres',
         x = NULL,
         y = 'Collaboration Strength',
         fill = 'Genre') +
    scale_fill_manual(values = macro_genre_colors) +
    theme_minimal()

  ggsave(file.path(output_dir, 'genre_hubs.png'), p_hubs, width = 12, height = 10, dpi = 300, bg = 'white')

  # --- 5.7 Export for Gephi ---
  cat("--- 5.7 Exporting for Gephi ---\n")

  edges_export <- edges_all %>% select(from, to, weight) %>% arrange(desc(weight))
  write_csv(edges_export, file.path(output_dir, 'non_image/genre_network_edges_gephi.csv'))

  nodes_export <- nodes %>%
    select(name, artist_count, macro_genre)
  write_csv(nodes_export, file.path(output_dir, 'non_image/genre_network_nodes_gephi.csv'))

  cat(sprintf("Exported: %d edges, %d nodes\n", nrow(edges_export), nrow(nodes_export)))

  cat("\nGenre network analysis complete.\n")

  return(list(graph = g, nodes = nodes, edges = edges_all, hubs = hub_metrics))
}


# =============================================================================
# Run
# =============================================================================

# run_exploratory_analysis()
# run_data_cleaning()
# run_lexical_transformation()
# run_lexical_analysis()
# run_genre_analysis()
