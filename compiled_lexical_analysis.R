# Compiled Lexical Analysis
# Billboard Hot 100 Lyrics (2000-2023)
# Outputs: outputs/lexical_analysis/

# Packages
packages <- c(
  "tidyverse", "readr", "stringr", "tidytext",
  "ggplot2", "scales", "viridis", "patchwork", "corrplot"
)

for (pkg in packages) {
  if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
    install.packages(pkg)
    library(pkg, character.only = TRUE)
  }
}

theme_set(theme_minimal())

# --- Transformation ---

library(tidyverse)
library(tidytext)
library(stringr)
library(readr)

options(scipen = 999)

# load billboard (using improved/cleaned version from bigquery cleaning)
billboard <- read_csv('../../data/cleaned/billboard_24years_lyrics_spotify_bigquery.csv',
                      show_col_types = F)

# load musicoset genres
artists <- read_csv('../../data/cleaned/musicoset_artists_cleaned.csv', 
                    show_col_types = F)

sprintf("loaded %d songs, %d artists", nrow(billboard), nrow(artists))

# normalize names for matching
df <- billboard %>%
  mutate(artist_clean = str_to_lower(str_trim(band_singer))) %>%
  left_join(
    artists %>% 
      mutate(artist_clean = str_to_lower(str_trim(name))) %>%
      select(artist_clean, main_genre, genres),
    by = "artist_clean"
  ) %>%
  mutate(has_genre = !is.na(main_genre))

# check coverage
cat(sprintf("genre coverage: %d/%d songs (%.1f%%)\n", 
            sum(df$has_genre), nrow(df), mean(df$has_genre)*100))

# top genres
df %>% count(main_genre, sort=T) %>% head(10)

# --- NA Diagnostic ---
cat("=== NA Analysis ===\n\n")

# Genre matching failures
no_genre <- df %>% filter(!has_genre)
cat(sprintf("Songs without genre match: %d (%.1f%%)\n", nrow(no_genre), nrow(no_genre)/nrow(df)*100))

# Sample unmatched artists
cat("\nSample unmatched artists (first 10):\n")
no_genre %>% 
  distinct(band_singer) %>% 
  head(10) %>% 
  pull(band_singer) %>% 
  paste(collapse = ", ") %>% 
  cat()

# Many-to-many duplicates
dupes <- df %>% 
  group_by(song, band_singer, year) %>% 
  filter(n() > 1) %>% 
  ungroup()
cat(sprintf("\n\nDuplicate rows from many-to-many join: %d\n", nrow(dupes)))

# Lyrics status
cat(sprintf("\nSongs with missing lyrics: %d\n", sum(is.na(df$lyrics))))

cat("\n\n=== This explains the NA sources ===\n")
cat("- main_genre NA: Artist name not found in MusicoSet\n")
cat("- Duplicates: Same artist name matches multiple MusicoSet entries\n")

# === DYNAMIC GENRE MAPPING ===
# Extract all unique genres from MusicoSet and classify using regex patterns

# Get all unique main_genre values from the joined data
all_genres <- df %>%
  filter(!is.na(main_genre)) %>%
  distinct(main_genre) %>%
  pull(main_genre)

cat(sprintf("Found %d unique micro-genres to classify\n\n", length(all_genres)))

# Define regex patterns for each macro genre (order matters - first match wins)
genre_patterns <- list(
  # POP - broad pop category
  "POP" = c("pop(?!.*punk)", "teen", "boy band", "girl group", "bubblegum", "candy"),
  
  # HIP HOP - rap and hip hop variants
  "HIP HOP" = c("hip hop", "\\brap\\b", "trap", "crunk", "drill", "g funk", "gangster",
                "conscious hip", "battle rap", "boom bap", "chopped and screwed",
                "dirty south", "hyphy", "phonk", "grime", "uk hip hop"),
  
  # COUNTRY - country and americana
  "COUNTRY" = c("country", "americana", "bluegrass", "honky tonk", "outlaw",
                "red dirt", "texas music", "cowboy", "nashville"),
  
  # ROCK - rock and punk variants
  "ROCK" = c("rock(?!.*opera)", "punk(?!.*funk)", "grunge", "alternative(?!.*r&b|.*hip)",
             "indie(?!.*pop|.*folk|.*soul)", "emo(?!.*rap)", "screamo", "post-",
             "new wave", "britpop", "shoegaze", "garage", "psychedelic"),
  
  # METAL - heavy metal variants
  "METAL" = c("metal", "\\bcore\\b", "metalcore", "deathcore", "grindcore",
              "thrash", "death metal", "black metal", "doom", "sludge",
              "djent", "nu metal", "groove metal", "power metal"),
  
  # R&B - rhythm and blues, soul
  "R&B" = c("r&b", "\\bsoul\\b", "neo soul", "quiet storm", "new jack swing",
            "\\bfunk\\b(?!.*punk)", "motown", "doo-wop", "urban contemporary"),
  
  # LATIN - latin american music
  "LATIN" = c("latin", "reggaeton", "salsa", "bachata", "cumbia", "merengue",
              "banda", "norteno", "corrido", "ranchera", "mariachi", "tropical",
              "urbano", "dembow", "mexican", "colombian", "puerto rican",
              "spanish(?!.*guitar)", "cubano", "bolero", "tango", "bossa nova",
              "mpb", "brazilian", "sertanejo", "forro", "axe"),
  
  # ELECTRONIC - electronic dance music
  "ELECTRONIC" = c("edm", "house", "techno", "trance", "dubstep", "drum and bass",
                   "\\bdnb\\b", "breakbeat", "jungle", "ambient", "chillout",
                   "downtempo", "electronica", "\\bdisco\\b", "eurodance",
                   "synthwave", "synthpop", "industrial(?!.*metal)", "idm",
                   "glitch", "future bass", "moombahton", "uk garage",
                   "hardstyle", "gabber", "happy hardcore", "electro(?!.*swing)"),
  
  # JAZZ - jazz variants
  "JAZZ" = c("jazz", "bebop", "swing(?!.*house)", "big band", "cool jazz",
             "fusion(?!.*metal)", "smooth jazz", "acid jazz", "free jazz",
             "hard bop", "modal jazz", "vocal jazz"),
  
  # BLUES - blues variants
  "BLUES" = c("\\bblues\\b", "delta blues", "chicago blues", "electric blues",
              "rhythm and blues", "jump blues", "blues rock"),
  
  # FOLK - folk and acoustic
  "FOLK" = c("\\bfolk\\b", "singer-songwriter", "acoustic", "celtic",
             "traditional", "appalachian", "world music", "roots"),
  
  # CLASSICAL - classical music
  "CLASSICAL" = c("classical", "orchestra", "symphony", "opera(?!.*rock|.*metal)",
                  "chamber", "baroque", "romantic era", "minimalism",
                  "contemporary classical", "choral", "cantata", "concerto"),
  
  # REGGAE - reggae and caribbean
  "REGGAE" = c("reggae", "\\bska\\b", "\\bdub\\b(?!step)", "dancehall",
               "roots reggae", "lovers rock", "rocksteady", "calypso",
               "soca", "caribbean"),
  
  # NEW AGE - relaxation and meditation
  "NEW AGE" = c("new age", "meditation", "relaxation", "healing",
                "spa", "sleep", "nature sounds"),
  
  # AVANT-GARDE - experimental
  "AVANT-GARDE" = c("experimental", "avant-garde", "noise", "\\bdrone\\b",
                    "musique concrete", "sound art", "field recordings")
)

# Function to classify a genre
classify_genre <- function(genre) {
  genre_lower <- str_to_lower(genre)
  
  for (macro in names(genre_patterns)) {
    patterns <- genre_patterns[[macro]]
    for (pattern in patterns) {
      if (str_detect(genre_lower, pattern)) {
        return(macro)
      }
    }
  }
  return("OTHER")
}

# Apply classification to all genres
genre_map <- tibble(
  micro_genre = all_genres,
  macro_genre = sapply(all_genres, classify_genre)
)

# Show distribution
cat("Macro genre distribution from dynamic mapping:\n")
genre_map %>% count(macro_genre, sort = TRUE) %>% print(n = 20)

# Apply to main dataframe
df <- df %>%
  left_join(genre_map, by = c("main_genre" = "micro_genre")) %>%
  mutate(macro_genre = if_else(is.na(macro_genre) & has_genre, "OTHER", macro_genre))

# Show final distribution in songs
cat("\n\nSongs per macro genre:\n")
df %>% count(macro_genre, sort = TRUE)

# tokenize into words
tokens <- df %>%
  filter(!is.na(lyrics)) %>%
  select(song, band_singer, year, lyrics, ranking, macro_genre, main_genre) %>%
  unnest_tokens(word, lyrics) %>%
  mutate(
    word = str_replace_all(word, "\\d+", ""),
    word = str_replace_all(word, "'s$", ""),
    word = str_replace_all(word, "[^a-z]", "")
  ) %>%
  filter(word != "")

sprintf("%s words total", format(nrow(tokens), big.mark=","))

# tag stop words
data(stop_words)
tokens <- tokens %>%
  mutate(is_stop = word %in% stop_words$word)

sprintf("stop words: %.1f%%", mean(tokens$is_stop)*100)

# basic metrics
metrics <- tokens %>%
  group_by(song, band_singer, year) %>%
  summarise(
    total_words = n(),
    unique_words = n_distinct(word),
    ttr = unique_words / total_words,
    content_words = sum(!is_stop),
    lexical_density = content_words / total_words,
    repetition_rate = 1 - ttr,
    avg_word_length = mean(nchar(word)),
    .groups = "drop"
  )

# hapax (words used once)
hapax <- tokens %>%
  count(song, band_singer, year, word) %>%
  group_by(song, band_singer, year) %>%
  summarise(
    hapax_count = sum(n == 1),
    hapax_ratio = mean(n == 1),
    .groups = "drop"
  )

metrics <- metrics %>% left_join(hapax)

# --- Repetitiveness: Line-based analysis ---
# Split lyrics into lines and count repeated lines
line_metrics <- df %>%
  filter(!is.na(lyrics)) %>%
  select(song, band_singer, year, lyrics) %>%
  mutate(
    # Split into lines, clean whitespace
    lines = str_split(lyrics, "\\s{2,}|\\n"),
  ) %>%
  unnest(lines) %>%
  mutate(lines = str_trim(str_to_lower(lines))) %>%
  filter(lines != "") %>%
  group_by(song, band_singer, year) %>%
  summarise(
    total_lines = n(),
    unique_lines = n_distinct(lines),
    repeated_lines = total_lines - unique_lines,
    repeated_line_ratio = repeated_lines / total_lines,
    unique_line_ratio = unique_lines / total_lines,
    .groups = "drop"
  )

cat(sprintf("Line-based repetitiveness calculated for %d songs\n", nrow(line_metrics)))
cat(sprintf("Mean repeated line ratio: %.1f%%\n", mean(line_metrics$repeated_line_ratio) * 100))

# --- Compression ratio (Nature paper method) ---
# Lower compression ratio = more repetitive (compresses better)
compression_metrics <- df %>%
  filter(!is.na(lyrics)) %>%
  select(song, band_singer, year, lyrics) %>%
  rowwise() %>%
  mutate(
    original_size = nchar(lyrics),
    compressed_size = length(memCompress(charToRaw(lyrics), "gzip")),
    compression_ratio = compressed_size / original_size
  ) %>%
  ungroup() %>%
  select(song, band_singer, year, compression_ratio, original_size, compressed_size)

cat(sprintf("Compression ratio calculated for %d songs\n", nrow(compression_metrics)))
cat(sprintf("Mean compression ratio: %.3f\n", mean(compression_metrics$compression_ratio)))

metrics <- metrics %>%
  left_join(line_metrics %>% select(song, band_singer, year,
                                     total_lines, unique_lines,
                                     repeated_line_ratio, unique_line_ratio),
            by = c("song", "band_singer", "year")) %>%
  left_join(compression_metrics %>% select(song, band_singer, year, compression_ratio),
            by = c("song", "band_singer", "year"))

# --- Jaccard Similarity to Genre Vocabulary ---
# Build genre vocabulary (top 500 words per genre for efficiency)
genre_vocab <- tokens %>%
  filter(!is.na(macro_genre)) %>%
  count(macro_genre, word, sort = TRUE) %>%
  group_by(macro_genre) %>%
  slice_head(n = 500) %>%
  summarise(vocab = list(unique(word)), .groups = "drop")

# Get each song's unique words
song_vocab <- tokens %>%
  group_by(song, band_singer, year, macro_genre) %>%
  summarise(words = list(unique(word)), .groups = "drop")

# Calculate Jaccard similarity: |A ∩ B| / |A ∪ B|
jaccard_calc <- song_vocab %>%
  filter(!is.na(macro_genre)) %>%
  left_join(genre_vocab, by = "macro_genre") %>%
  rowwise() %>%
  mutate(
    intersection = length(intersect(words, vocab)),
    union = length(union(words, vocab)),
    jaccard_genre = intersection / union
  ) %>%
  ungroup() %>%
  select(song, band_singer, year, jaccard_genre)

# Jaccard to corpus (all songs)
corpus_vocab <- tokens %>%
  count(word, sort = TRUE) %>%
  slice_head(n = 1000) %>%
  pull(word)

jaccard_corpus <- song_vocab %>%
  rowwise() %>%
  mutate(
    intersection = length(intersect(words, corpus_vocab)),
    union = length(union(words, corpus_vocab)),
    jaccard_corpus = intersection / union
  ) %>%
  ungroup() %>%
  select(song, band_singer, year, jaccard_corpus)

# --- Vocabulary Uniqueness (vs 10k Common English Words) ---
# Load 10k most common English words
common_words <- read_csv('../../data/cleaned/common_english_words_10k.csv', show_col_types = F)
common_word_set <- common_words$word

cat(sprintf("Loaded %d common English words\n", length(common_word_set)))

# Calculate uniqueness metrics
vocab_uniqueness <- song_vocab %>%
  rowwise() %>%
  mutate(
    # How many words are in common 10k list?
    common_count = sum(words %in% common_word_set),
    # How many are NOT in common list (rare/unique)?
    rare_count = sum(!words %in% common_word_set),
    # Percentage of rare words
    rare_word_ratio = rare_count / length(words),
    # Jaccard similarity to common words (lower = more unique)
    intersection_common = length(intersect(words, common_word_set)),
    union_common = length(union(words, common_word_set)),
    jaccard_common = intersection_common / union_common,
    # Vocabulary uniqueness score (inverse of commonality)
    vocab_uniqueness = 1 - (common_count / length(words))
  ) %>%
  ungroup() %>%
  select(song, band_singer, year, rare_word_ratio, jaccard_common, vocab_uniqueness, rare_count, common_count)

# Join all metrics
metrics <- metrics %>%
  left_join(jaccard_calc, by = c("song", "band_singer", "year")) %>%
  left_join(jaccard_corpus, by = c("song", "band_singer", "year")) %>%
  left_join(vocab_uniqueness, by = c("song", "band_singer", "year"))

cat("\nMetrics summary:\n")
metrics %>% 
  select(total_words:hapax_ratio, repeated_line_ratio, unique_line_ratio, compression_ratio,
         jaccard_genre, jaccard_corpus, rare_word_ratio, jaccard_common, vocab_uniqueness) %>% 
  summary()

# join back with main data
df_final <- df %>%
  left_join(metrics) %>%
  mutate(
    # chart categories
    chart_tier = case_when(
      ranking <= 10 ~ "Top 10",
      ranking <= 25 ~ "11-25",
      ranking <= 50 ~ "26-50",
      ranking <= 75 ~ "51-75",
      ranking <= 100 ~ "76-100"
    ),
    is_top10 = ranking <= 10,
    is_top25 = ranking <= 25,
    chart_score = 101 - ranking,
    
    # time periods
    decade = case_when(
      year < 2010 ~ "2000s",
      year < 2020 ~ "2010s",
      TRUE ~ "2020s"
    ),
    era = case_when(
      year < 2008 ~ "Early",
      year < 2015 ~ "Middle",
      TRUE ~ "Late"
    ),
    years_since_2000 = year - 2000,
    
    # flags
    is_short = total_words < 100,
    is_long = total_words > 900,
    is_normal_length = total_words >= 100 & total_words <= 900,
    has_complete_data = !is.na(macro_genre) & is_normal_length & !is.na(ttr)
  )

# genre norms
genre_stats <- df_final %>%
  filter(!is.na(macro_genre) & !is.na(ttr)) %>%
  group_by(macro_genre) %>%
  summarise(m = mean(ttr), s = sd(ttr))

df_final <- df_final %>%
  left_join(genre_stats, by = "macro_genre") %>%
  mutate(ttr_z_genre = (ttr - m) / s) %>%
  select(-m, -s)

# year norms
year_stats <- df_final %>%
  filter(!is.na(ttr)) %>%
  group_by(year) %>%
  summarise(m = mean(ttr), s = sd(ttr))

df_final <- df_final %>%
  left_join(year_stats, by = "year") %>%
  mutate(ttr_z_year = (ttr - m) / s) %>%
  select(-m, -s)

# log transforms
df_final <- df_final %>%
  mutate(
    log_words = log(total_words + 1),
    log_unique = log(unique_words + 1)
  )

cat(sprintf("total: %d\n", nrow(df_final)))
cat(sprintf("complete data: %d (%.1f%%)\n", 
            sum(df_final$has_complete_data, na.rm=T),
            mean(df_final$has_complete_data, na.rm=T)*100))

cat("\nlength distribution:\n")
cat(sprintf("  short: %d\n", sum(df_final$is_short, na.rm=T)))
cat(sprintf("  normal: %d\n", sum(df_final$is_normal_length, na.rm=T)))
cat(sprintf("  long: %d\n", sum(df_final$is_long, na.rm=T)))

# select final columns (including repetitiveness and vocabulary uniqueness metrics)
final <- df_final %>%
  select(
    song, band_singer, year,
    main_genre, macro_genre,
    ranking, chart_tier, chart_score, is_top10, is_top25,
    decade, era, years_since_2000,
    total_words, unique_words, ttr, lexical_density, repetition_rate, avg_word_length,
    hapax_count, hapax_ratio,
    total_lines, unique_lines, repeated_line_ratio, unique_line_ratio, compression_ratio,
    jaccard_genre, jaccard_corpus, jaccard_common,
    rare_word_ratio, vocab_uniqueness, rare_count, common_count,
    ttr_z_genre, ttr_z_year, log_words, log_unique,
    is_short, is_long, is_normal_length, has_complete_data,
    lyrics
  )

write_csv(final, '../../data/cleaned/billboard_lexical_analysis_ready.csv')
write_csv(genre_map, '../../data/cleaned/genre_macro_mapping.csv')

cat("\nexported files:\n")
cat("  billboard_lexical_analysis_ready.csv\n")
cat("  genre_macro_mapping.csv\n")

# summary stats
tibble(
  metric = c("total_songs", "with_genre", "complete_data", "years", "macro_genres"),
  value = c(
    nrow(final),
    sum(!is.na(final$macro_genre)),
    sum(final$has_complete_data, na.rm=T),
    n_distinct(final$year),
    n_distinct(final$macro_genre, na.rm=T)
  )
)

# preview
final %>% 
  filter(has_complete_data) %>%
  select(song, band_singer, macro_genre, ranking, ttr, total_words) %>%
  head(10)

# --- Analysis & Visualization ---

# Libraries and setup
library(tidyverse)
library(ggplot2)
library(scales)
library(viridis)

options(scipen = 999)
theme_set(theme_minimal(base_size = 12))

# Color palette
genre_colors <- c(
  "POP" = "#FF6B6B",
  "HIP HOP" = "#4ECDC4",
  "COUNTRY" = "#FFD93D",
  "ROCK" = "#95E1D3",
  "R&B" = "#F38181",
  "ELECTRONIC" = "#AA96DA",
  "LATIN" = "#FCE77D",
  "OTHER" = "#C8C8C8"
)

# Load data
df <- read_csv('../../data/cleaned/billboard_lexical_analysis_ready.csv',
               show_col_types = FALSE)

df_analysis <- df %>%
  filter(has_complete_data == TRUE)

cat(sprintf("Total: %d songs, Analysis set: %d (%.1f%%)\n", 
            nrow(df), nrow(df_analysis), nrow(df_analysis)/nrow(df)*100))
cat(sprintf("Years: %d-%d, Genres: %d\n", 
            min(df$year), max(df$year), n_distinct(df_analysis$macro_genre)))

# Summary stats by genre
summary_stats <- df_analysis %>%
  group_by(macro_genre) %>%
  summarise(
    n = n(),
    mean_ttr = mean(ttr, na.rm = TRUE),
    median_ttr = median(ttr, na.rm = TRUE),
    sd_ttr = sd(ttr, na.rm = TRUE),
    mean_lexical_density = mean(lexical_density, na.rm = TRUE),
    mean_rare_word_ratio = mean(rare_word_ratio, na.rm = TRUE),
    .groups = 'drop'
  ) %>%
  arrange(desc(mean_ttr))

print(summary_stats)

# TTR by genre
ggplot(df_analysis, aes(x = reorder(macro_genre, ttr, median), 
                        y = ttr, 
                        fill = macro_genre)) +
  geom_violin(alpha = 0.7, draw_quantiles = c(0.25, 0.5, 0.75)) +
  geom_jitter(alpha = 0.1, width = 0.2, size = 0.5) +
  scale_fill_manual(values = genre_colors) +
  labs(title = "TTR Distribution by Genre", x = "Genre", y = "TTR") +
  coord_flip() +
  theme(legend.position = "none")

# ANOVA: TTR across genres
anova_ttr <- aov(ttr ~ macro_genre, data = df_analysis)
summary(anova_ttr)
TukeyHSD(anova_ttr)

# Genre rankings bar chart
genre_rankings <- df_analysis %>%
  group_by(macro_genre) %>%
  summarise(
    n = n(),
    mean_ttr = mean(ttr, na.rm = TRUE),
    .groups = 'drop'
  ) %>%
  arrange(desc(mean_ttr))

ggplot(genre_rankings, aes(x = reorder(macro_genre, mean_ttr), 
                           y = mean_ttr, 
                           fill = macro_genre)) +
  geom_col() +
  geom_text(aes(label = sprintf("%.3f", mean_ttr)), hjust = -0.2, size = 4) +
  scale_fill_manual(values = genre_colors) +
  labs(title = "Average TTR by Genre", x = "Genre", y = "TTR") +
  coord_flip() +
  theme(legend.position = "none")

# TTR vs chart position correlation
cor.test(df_analysis$ttr, df_analysis$ranking, method = "spearman")

# TTR vs ranking scatter by genre
# X-axis reversed: 1 (best) on left, 100 on right
ggplot(df_analysis, aes(x = ranking, y = ttr, color = macro_genre)) +
  geom_point(alpha = 0.3, size = 1.5) +
  geom_smooth(method = "lm", se = FALSE, linewidth = 0.8) +
  scale_color_manual(values = genre_colors) +
  scale_x_reverse(limits = c(100, 1)) +
  facet_wrap(~macro_genre, ncol = 3) +
  labs(title = "TTR vs Chart Position by Genre", 
       x = "Chart Position (1 = best)", 
       y = "TTR") +
  theme(legend.position = "none")

# Rare word ratio vs chart position (Creative Vocabulary vs Chart Position)
# X-axis reversed: 1 (best) on left, 100 on right
cor_rare <- cor.test(df_analysis$rare_word_ratio, df_analysis$ranking, method = "spearman")
cat(sprintf("Rare words vs Ranking: rho = %.3f, p = %.4f\n", cor_rare$estimate, cor_rare$p.value))

ggplot(df_analysis, aes(x = ranking, y = rare_word_ratio, color = macro_genre)) +
  geom_point(alpha = 0.3, size = 1.5) +
  geom_smooth(method = "lm", se = TRUE, linewidth = 1) +
  scale_color_manual(values = genre_colors) +
  scale_x_reverse(limits = c(100, 1)) +
  scale_y_continuous(labels = percent_format()) +
  facet_wrap(~macro_genre, ncol = 3) +
  labs(title = "Creative Vocabulary vs Chart Position", 
       x = "Chart Position (1 = best)", 
       y = "Rare Word Ratio") +
  theme(legend.position = "none")

# Compression ratio by genre
ggplot(df_analysis, aes(x = reorder(macro_genre, compression_ratio, median), 
                        y = compression_ratio, 
                        fill = macro_genre)) +
  geom_violin(alpha = 0.7) +
  geom_boxplot(width = 0.2, fill = "white", alpha = 0.5) +
  scale_fill_manual(values = genre_colors) +
  labs(
    title = "Compression Ratio by Genre",
    subtitle = "Lower = more repetitive",
    x = "Genre",
    y = "Compression Ratio"
  ) +
  theme_minimal() +
  theme(legend.position = "none")

# Compression ratio over time
compression_trends <- df_analysis %>%
  group_by(year) %>%
  summarise(
    mean_compression = mean(compression_ratio, na.rm = TRUE),
    .groups = "drop"
  )

ggplot(compression_trends, aes(x = year, y = mean_compression)) +
  geom_line(linewidth = 1, color = "steelblue") +
  geom_point(size = 2, color = "steelblue") +
  geom_smooth(method = "lm", se = TRUE, color = "red", linetype = "dashed") +
  labs(
    title = "Compression Ratio Over Time (2000-2023)",
    x = "Year",
    y = "Mean Compression Ratio"
  ) +
  theme_minimal()

cor_compression_year <- cor.test(df_analysis$compression_ratio, df_analysis$year, method = "spearman")
cat(sprintf("Compression vs Year: rho = %.3f, p = %.4f\n", 
            cor_compression_year$estimate, cor_compression_year$p.value))

# Jaccard similarity summary
cat("Jaccard Common (overlap with 10k English words):\n")
summary(df_analysis$jaccard_common)

cat("\nRare Word Ratio (words NOT in common 10k):\n")
summary(df_analysis$rare_word_ratio)

# Rare word ratio by genre
ggplot(df_analysis, aes(x = reorder(macro_genre, rare_word_ratio, median), 
                        y = rare_word_ratio, 
                        fill = macro_genre)) +
  geom_violin(alpha = 0.7) +
  geom_boxplot(width = 0.15, alpha = 0.8, outlier.size = 0.5) +
  scale_fill_manual(values = genre_colors) +
  scale_y_continuous(labels = percent_format()) +
  labs(title = "Rare Word Usage by Genre", x = "Genre", y = "Rare Word Ratio") +
  theme(legend.position = "none")

# TTR vs rare word ratio by genre
ggplot(df_analysis, aes(x = ttr, y = rare_word_ratio, color = macro_genre)) +
  geom_point(alpha = 0.4, size = 1) +
  geom_smooth(method = "lm", se = FALSE, linewidth = 0.8) +
  scale_color_manual(values = genre_colors) +
  facet_wrap(~macro_genre, ncol = 3) +
  scale_y_continuous(labels = percent_format()) +
  labs(title = "TTR vs Rare Word Ratio by Genre", x = "TTR", y = "Rare Word Ratio") +
  theme(legend.position = "none")

# TTR vs rare word ratio correlation
ggplot(df_analysis, aes(x = ttr, y = rare_word_ratio, color = macro_genre)) +
  geom_point(alpha = 0.4, size = 2) +
  geom_smooth(method = "lm", se = TRUE, color = "black", linewidth = 1) +
  scale_color_manual(values = genre_colors) +
  scale_y_continuous(labels = percent_format()) +
  labs(title = "TTR vs Rare Word Ratio", x = "TTR", y = "Rare Word Ratio") +
  theme(legend.position = "right")

cor.test(df_analysis$ttr, df_analysis$rare_word_ratio, method = "spearman")

# TTR trends over time (overall)
yearly_trends <- df_analysis %>%
  group_by(year) %>%
  summarise(
    mean_ttr = mean(ttr, na.rm = TRUE),
    median_ttr = median(ttr, na.rm = TRUE),
    mean_rare = mean(rare_word_ratio, na.rm = TRUE),
    .groups = "drop"
  )

ggplot(yearly_trends, aes(x = year, y = mean_ttr)) +
  geom_line(linewidth = 1, color = "steelblue") +
  geom_point(size = 2, color = "steelblue") +
  geom_smooth(method = "lm", se = TRUE, color = "red", linetype = "dashed") +
  labs(title = "TTR Over Time (2000-2023) - All Genres", x = "Year", y = "Mean TTR") +
  theme_minimal()

cor_ttr_year <- cor.test(df_analysis$ttr, df_analysis$year, method = "spearman")
cat(sprintf("TTR vs Year (all genres): rho = %.3f, p = %.4f\n", cor_ttr_year$estimate, cor_ttr_year$p.value))

# TTR trends over time BY GENRE
yearly_trends_genre <- df_analysis %>%
  group_by(year, macro_genre) %>%
  summarise(
    mean_ttr = mean(ttr, na.rm = TRUE),
    n = n(),
    .groups = "drop"
  )

ggplot(yearly_trends_genre, aes(x = year, y = mean_ttr, color = macro_genre)) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 1.5) +
  geom_smooth(method = "lm", se = FALSE, linetype = "dashed", linewidth = 0.5) +
  scale_color_manual(values = genre_colors) +
  scale_x_continuous(breaks = seq(2000, 2023, by = 4)) +
  facet_wrap(~macro_genre, ncol = 3, scales = "free_x") +
  labs(title = "Are Songs Becoming More or Less Diverse? (By Genre)",
       subtitle = "TTR trends over time by genre",
       x = "Year",
       y = "Mean TTR") +
  theme_minimal() +
  theme(legend.position = "none",
        axis.text.x = element_text(angle = 45, hjust = 1))

# Rare word ratio over time (overall)
ggplot(yearly_trends, aes(x = year, y = mean_rare)) +
  geom_line(linewidth = 1, color = "steelblue") +
  geom_point(size = 2, color = "steelblue") +
  geom_smooth(method = "lm", se = TRUE, color = "red", linetype = "dashed") +
  scale_y_continuous(labels = percent_format()) +
  labs(title = "Rare Word Usage Over Time - All Genres", x = "Year", y = "Mean Rare Word Ratio") +
  theme_minimal()

cor_rare_year <- cor.test(df_analysis$rare_word_ratio, df_analysis$year, method = "spearman")
cat(sprintf("Rare words vs Year (all genres): rho = %.3f, p = %.4f\n", cor_rare_year$estimate, cor_rare_year$p.value))

# Rare word ratio over time BY GENRE
yearly_rare_genre <- df_analysis %>%
  group_by(year, macro_genre) %>%
  summarise(
    mean_rare = mean(rare_word_ratio, na.rm = TRUE),
    n = n(),
    .groups = "drop"
  )

ggplot(yearly_rare_genre, aes(x = year, y = mean_rare, color = macro_genre)) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 1.5) +
  geom_smooth(method = "lm", se = FALSE, linetype = "dashed", linewidth = 0.5) +
  scale_color_manual(values = genre_colors) +
  scale_y_continuous(labels = percent_format()) +
  facet_wrap(~macro_genre, ncol = 3) +
  labs(title = "Are Songs Becoming More or Less Creative? (By Genre)", 
       subtitle = "Rare word ratio trends over time by genre",
       x = "Year", 
       y = "Mean Rare Word Ratio") +
  theme_minimal() +
  theme(legend.position = "none")

# Most and least diverse songs
cat("=== HIGHEST TTR ===\n")
df_analysis %>%
  select(song, band_singer, year, macro_genre, ttr, total_words) %>%
  arrange(desc(ttr)) %>%
  head(10)

cat("\n=== LOWEST TTR ===\n")
df_analysis %>%
  select(song, band_singer, year, macro_genre, ttr, total_words) %>%
  arrange(ttr) %>%
  head(10)

# Artist vocabulary analysis
library(tidytext)

df_full <- read_csv('../../data/cleaned/billboard_lexical_analysis_ready.csv', show_col_types = FALSE)

tokens <- df_full %>%
  filter(!is.na(lyrics)) %>%
  select(song, band_singer, year, lyrics, macro_genre) %>%
  unnest_tokens(word, lyrics) %>%
  mutate(word = str_replace_all(word, "[^a-z]", "")) %>%
  filter(word != "")

artist_vocab <- tokens %>%
  group_by(band_singer) %>%
  summarise(
    total_words = n(),
    unique_words = n_distinct(word),
    songs = n_distinct(song),
    .groups = "drop"
  ) %>%
  filter(songs >= 5) %>%
  arrange(desc(unique_words))

cat(sprintf("Artists with 5+ songs: %d\n", nrow(artist_vocab)))
head(artist_vocab, 20)

# Artist vocabulary distribution
ggplot(artist_vocab, aes(x = 1, y = unique_words)) +
  geom_violin(fill = "steelblue", alpha = 0.5) +
  geom_boxplot(width = 0.1) +
  labs(title = "Artist Vocabulary Size Distribution", y = "Unique Words") +
  theme_minimal() +
  theme(axis.title.x = element_blank(), axis.text.x = element_blank())

# Drake vs other top artists
drake_stats <- artist_vocab %>%
  filter(str_detect(str_to_lower(band_singer), "drake"))

cat("Drake's vocabulary stats:\n")
print(drake_stats)

cat(sprintf("\nDrake's percentile: %.1f%%\n", 
            mean(artist_vocab$unique_words <= drake_stats$unique_words[1]) * 100))

# Lexical density overview
cat("Lexical Density Summary:\n")
summary(df_analysis$lexical_density)

cat(sprintf("\nCorrelation with TTR: %.3f\n", 
            cor(df_analysis$lexical_density, df_analysis$ttr, use = "complete.obs")))

# Lexical density by genre
ggplot(df_analysis, aes(x = reorder(macro_genre, lexical_density, median), 
                        y = lexical_density, 
                        fill = macro_genre)) +
  geom_violin(alpha = 0.7) +
  geom_boxplot(width = 0.15, alpha = 0.8) +
  scale_fill_manual(values = genre_colors) +
  labs(title = "Lexical Density by Genre", x = "Genre", y = "Lexical Density") +
  theme(legend.position = "none")

# Lexical density vs chart position
cor.test(df_analysis$lexical_density, df_analysis$ranking, method = "spearman")

# Lexical density over time
lex_trends <- df_analysis %>%
  group_by(year) %>%
  summarise(mean_lex = mean(lexical_density, na.rm = TRUE), .groups = "drop")

ggplot(lex_trends, aes(x = year, y = mean_lex)) +
  geom_line(linewidth = 1, color = "steelblue") +
  geom_point(size = 2, color = "steelblue") +
  geom_smooth(method = "lm", se = TRUE, color = "red", linetype = "dashed") +
  labs(title = "Lexical Density Over Time", x = "Year", y = "Mean Lexical Density") +
  theme_minimal()

# Jaccard similarity vs chart position
cor_genre <- cor.test(df_analysis$jaccard_genre, df_analysis$ranking, method = "spearman")
cat(sprintf("Jaccard genre vs Ranking: rho = %.3f, p = %.4f\n", cor_genre$estimate, cor_genre$p.value))

# Most and least substantive songs
cat("=== HIGHEST LEXICAL DENSITY ===\n")
df_analysis %>%
  select(song, band_singer, year, macro_genre, lexical_density) %>%
  arrange(desc(lexical_density)) %>%
  head(10)

cat("\n=== LOWEST LEXICAL DENSITY ===\n")
df_analysis %>%
  select(song, band_singer, year, macro_genre, lexical_density) %>%
  arrange(lexical_density) %>%
  head(10)

# Jaccard metrics by genre
jaccard_by_genre <- df_analysis %>%
  group_by(macro_genre) %>%
  summarise(
    mean_jaccard_genre = mean(jaccard_genre, na.rm = TRUE),
    mean_jaccard_corpus = mean(jaccard_corpus, na.rm = TRUE),
    .groups = "drop"
  )
print(jaccard_by_genre)

# Jaccard 2D space: genre-typical vs mainstream
ggplot(df_analysis, aes(x = jaccard_genre, y = jaccard_corpus, color = macro_genre)) +
  geom_point(alpha = 0.4, size = 2) +
  scale_color_manual(values = genre_colors) +
  labs(title = "Genre-Typical vs Mainstream Vocabulary", 
       x = "Jaccard Genre (genre-typical)", 
       y = "Jaccard Corpus (mainstream)") +
  theme_minimal()

# Jaccard corpus vs chart position
cor_corpus <- cor.test(df_analysis$jaccard_corpus, df_analysis$ranking, method = "spearman")
cat(sprintf("Jaccard corpus vs Ranking: rho = %.3f, p = %.4f\n", cor_corpus$estimate, cor_corpus$p.value))

# Jaccard trends over time
jaccard_trends <- df_analysis %>%
  group_by(year) %>%
  summarise(
    mean_genre = mean(jaccard_genre, na.rm = TRUE),
    mean_corpus = mean(jaccard_corpus, na.rm = TRUE),
    .groups = "drop"
  )

ggplot(jaccard_trends, aes(x = year)) +
  geom_line(aes(y = mean_genre, color = "Genre-typical"), linewidth = 1) +
  geom_line(aes(y = mean_corpus, color = "Mainstream"), linewidth = 1) +
  geom_smooth(aes(y = mean_genre), method = "lm", se = FALSE, linetype = "dashed", color = "red") +
  labs(title = "Vocabulary Homogeneity Over Time", x = "Year", y = "Mean Jaccard", color = "Metric") +
  theme_minimal()

# Genre outliers
cat("=== MOST GENRE-TYPICAL ===\n")
df_analysis %>%
  filter(!is.na(jaccard_genre)) %>%
  select(song, band_singer, macro_genre, jaccard_genre) %>%
  arrange(desc(jaccard_genre)) %>%
  head(10)

cat("\n=== LEAST GENRE-TYPICAL ===\n")
df_analysis %>%
  filter(!is.na(jaccard_genre)) %>%
  select(song, band_singer, macro_genre, jaccard_genre) %>%
  arrange(jaccard_genre) %>%
  head(10)

# Jaccard by genre faceted with median reference lines
jaccard_medians <- df_analysis %>%
  group_by(macro_genre) %>%
  summarise(
    median_jaccard_genre = median(jaccard_genre, na.rm = TRUE),
    median_jaccard_corpus = median(jaccard_corpus, na.rm = TRUE),
    .groups = "drop"
  )

ggplot(df_analysis, aes(x = jaccard_genre, y = jaccard_corpus)) +
  geom_vline(data = jaccard_medians, aes(xintercept = median_jaccard_genre),
             linetype = "dashed", color = "gray40", linewidth = 0.5) +
  geom_hline(data = jaccard_medians, aes(yintercept = median_jaccard_corpus),
             linetype = "dashed", color = "gray40", linewidth = 0.5) +
  geom_point(aes(color = macro_genre), alpha = 0.4, size = 1.5) +
  scale_color_manual(values = genre_colors) +
  facet_wrap(~macro_genre, ncol = 3) +
  labs(title = "Genre-Typical vs Mainstream by Genre",
       subtitle = "Dashed lines show genre medians",
       x = "Jaccard Genre", y = "Jaccard Corpus") +
  theme(legend.position = "none")

# Export all visualizations to outputs/lexical_analysis/
output_dir <- '../../outputs/lexical_analysis'
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

# 1. TTR Distribution by Genre
p1 <- ggplot(df_analysis, aes(x = reorder(macro_genre, ttr, median), y = ttr, fill = macro_genre)) +
  geom_violin(alpha = 0.7, draw_quantiles = c(0.25, 0.5, 0.75)) +
  geom_jitter(alpha = 0.1, width = 0.2, size = 0.5) +
  scale_fill_manual(values = genre_colors) +
  labs(title = "TTR Distribution by Genre", x = "Genre", y = "TTR") +
  coord_flip() +
  theme(legend.position = "none")
ggsave(file.path(output_dir, '01_ttr_by_genre.png'), p1, width = 10, height = 6, dpi = 300, bg = 'white')

# 2. Average TTR by Genre
p2 <- ggplot(genre_rankings, aes(x = reorder(macro_genre, mean_ttr), y = mean_ttr, fill = macro_genre)) +
  geom_col() +
  geom_text(aes(label = sprintf("%.3f", mean_ttr)), hjust = -0.2, size = 4) +
  scale_fill_manual(values = genre_colors) +
  labs(title = "Average TTR by Genre", x = "Genre", y = "TTR") +
  coord_flip() +
  theme(legend.position = "none")
ggsave(file.path(output_dir, '02_avg_ttr_by_genre.png'), p2, width = 10, height = 6, dpi = 300, bg = 'white')

# 3. TTR vs Chart Position by Genre
p3 <- ggplot(df_analysis, aes(x = ranking, y = ttr, color = macro_genre)) +
  geom_point(alpha = 0.3, size = 1.5) +
  geom_smooth(method = "lm", se = FALSE, linewidth = 0.8) +
  scale_color_manual(values = genre_colors) +
  scale_x_reverse(limits = c(100, 1)) +
  facet_wrap(~macro_genre, ncol = 3) +
  labs(title = "TTR vs Chart Position by Genre", x = "Chart Position (1 = best)", y = "TTR") +
  theme(legend.position = "none")
ggsave(file.path(output_dir, '03_ttr_vs_chart_position.png'), p3, width = 12, height = 8, dpi = 300, bg = 'white')

# 4. Creative Vocabulary vs Chart Position
p4 <- ggplot(df_analysis, aes(x = ranking, y = rare_word_ratio, color = macro_genre)) +
  geom_point(alpha = 0.3, size = 1.5) +
  geom_smooth(method = "lm", se = TRUE, linewidth = 1) +
  scale_color_manual(values = genre_colors) +
  scale_x_reverse(limits = c(100, 1)) +
  scale_y_continuous(labels = percent_format()) +
  facet_wrap(~macro_genre, ncol = 3) +
  labs(title = "Creative Vocabulary vs Chart Position", x = "Chart Position (1 = best)", y = "Rare Word Ratio") +
  theme(legend.position = "none")
ggsave(file.path(output_dir, '04_creative_vocab_vs_chart.png'), p4, width = 12, height = 8, dpi = 300, bg = 'white')

# 5. Compression Ratio by Genre
p5 <- ggplot(df_analysis, aes(x = reorder(macro_genre, compression_ratio, median), y = compression_ratio, fill = macro_genre)) +
  geom_violin(alpha = 0.7) +
  geom_boxplot(width = 0.2, fill = "white", alpha = 0.5) +
  scale_fill_manual(values = genre_colors) +
  labs(title = "Compression Ratio by Genre", subtitle = "Lower = more repetitive", x = "Genre", y = "Compression Ratio") +
  theme_minimal() +
  theme(legend.position = "none")
ggsave(file.path(output_dir, '05_compression_by_genre.png'), p5, width = 10, height = 6, dpi = 300, bg = 'white')

# 6. Compression Ratio Over Time
p6 <- ggplot(compression_trends, aes(x = year, y = mean_compression)) +
  geom_line(linewidth = 1, color = "steelblue") +
  geom_point(size = 2, color = "steelblue") +
  geom_smooth(method = "lm", se = TRUE, color = "red", linetype = "dashed") +
  labs(title = "Compression Ratio Over Time (2000-2023)", x = "Year", y = "Mean Compression Ratio") +
  theme_minimal()
ggsave(file.path(output_dir, '06_compression_over_time.png'), p6, width = 10, height = 6, dpi = 300, bg = 'white')

# 7. Rare Word Usage by Genre
p7 <- ggplot(df_analysis, aes(x = reorder(macro_genre, rare_word_ratio, median), y = rare_word_ratio, fill = macro_genre)) +
  geom_violin(alpha = 0.7) +
  geom_boxplot(width = 0.15, alpha = 0.8, outlier.size = 0.5) +
  scale_fill_manual(values = genre_colors) +
  scale_y_continuous(labels = percent_format()) +
  labs(title = "Rare Word Usage by Genre", x = "Genre", y = "Rare Word Ratio") +
  theme(legend.position = "none")
ggsave(file.path(output_dir, '07_rare_words_by_genre.png'), p7, width = 10, height = 6, dpi = 300, bg = 'white')

# 8. TTR vs Rare Word Ratio
p8 <- ggplot(df_analysis, aes(x = ttr, y = rare_word_ratio, color = macro_genre)) +
  geom_point(alpha = 0.4, size = 2) +
  geom_smooth(method = "lm", se = TRUE, color = "black", linewidth = 1) +
  scale_color_manual(values = genre_colors) +
  scale_y_continuous(labels = percent_format()) +
  labs(title = "TTR vs Rare Word Ratio", x = "TTR", y = "Rare Word Ratio") +
  theme(legend.position = "right")
ggsave(file.path(output_dir, '08_ttr_vs_rare_words.png'), p8, width = 10, height = 6, dpi = 300, bg = 'white')

# 9. TTR Over Time - All Genres
p9 <- ggplot(yearly_trends, aes(x = year, y = mean_ttr)) +
  geom_line(linewidth = 1, color = "steelblue") +
  geom_point(size = 2, color = "steelblue") +
  geom_smooth(method = "lm", se = TRUE, color = "red", linetype = "dashed") +
  labs(title = "TTR Over Time (2000-2023) - All Genres", x = "Year", y = "Mean TTR") +
  theme_minimal()
ggsave(file.path(output_dir, '09_ttr_over_time.png'), p9, width = 10, height = 6, dpi = 300, bg = 'white')

# 10. TTR Over Time BY GENRE
p10 <- ggplot(yearly_trends_genre, aes(x = year, y = mean_ttr, color = macro_genre)) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 1.5) +
  geom_smooth(method = "lm", se = FALSE, linetype = "dashed", linewidth = 0.5) +
  scale_color_manual(values = genre_colors) +
  scale_x_continuous(breaks = seq(2000, 2023, by = 4)) +
  facet_wrap(~macro_genre, ncol = 3, scales = "free_x") +
  labs(title = "Are Songs Becoming More or Less Diverse? (By Genre)", subtitle = "TTR trends over time by genre", x = "Year", y = "Mean TTR") +
  theme_minimal() +
  theme(legend.position = "none",
        axis.text.x = element_text(angle = 45, hjust = 1))
ggsave(file.path(output_dir, '10_ttr_over_time_by_genre.png'), p10, width = 12, height = 8, dpi = 300, bg = 'white')

# 11. Rare Word Ratio Over Time - All Genres
p11 <- ggplot(yearly_trends, aes(x = year, y = mean_rare)) +
  geom_line(linewidth = 1, color = "steelblue") +
  geom_point(size = 2, color = "steelblue") +
  geom_smooth(method = "lm", se = TRUE, color = "red", linetype = "dashed") +
  scale_y_continuous(labels = percent_format()) +
  labs(title = "Rare Word Usage Over Time - All Genres", x = "Year", y = "Mean Rare Word Ratio") +
  theme_minimal()
ggsave(file.path(output_dir, '11_rare_words_over_time.png'), p11, width = 10, height = 6, dpi = 300, bg = 'white')

# 12. Rare Word Ratio Over Time BY GENRE
p12 <- ggplot(yearly_rare_genre, aes(x = year, y = mean_rare, color = macro_genre)) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 1.5) +
  geom_smooth(method = "lm", se = FALSE, linetype = "dashed", linewidth = 0.5) +
  scale_color_manual(values = genre_colors) +
  scale_y_continuous(labels = percent_format()) +
  facet_wrap(~macro_genre, ncol = 3) +
  labs(title = "Are Songs Becoming More or Less Creative? (By Genre)", subtitle = "Rare word ratio trends over time by genre", x = "Year", y = "Mean Rare Word Ratio") +
  theme_minimal() +
  theme(legend.position = "none")
ggsave(file.path(output_dir, '12_rare_words_over_time_by_genre.png'), p12, width = 12, height = 8, dpi = 300, bg = 'white')

# 13. Artist Vocabulary Distribution
p13 <- ggplot(artist_vocab, aes(x = 1, y = unique_words)) +
  geom_violin(fill = "steelblue", alpha = 0.5) +
  geom_boxplot(width = 0.1) +
  labs(title = "Artist Vocabulary Size Distribution", y = "Unique Words") +
  theme_minimal() +
  theme(axis.title.x = element_blank(), axis.text.x = element_blank())
ggsave(file.path(output_dir, '13_artist_vocab_distribution.png'), p13, width = 8, height = 6, dpi = 300, bg = 'white')

# 14. Lexical Density by Genre
p14 <- ggplot(df_analysis, aes(x = reorder(macro_genre, lexical_density, median), y = lexical_density, fill = macro_genre)) +
  geom_violin(alpha = 0.7) +
  geom_boxplot(width = 0.15, alpha = 0.8) +
  scale_fill_manual(values = genre_colors) +
  labs(title = "Lexical Density by Genre", x = "Genre", y = "Lexical Density") +
  theme(legend.position = "none")
ggsave(file.path(output_dir, '14_lexical_density_by_genre.png'), p14, width = 10, height = 6, dpi = 300, bg = 'white')

# 15. Lexical Density Over Time
p15 <- ggplot(lex_trends, aes(x = year, y = mean_lex)) +
  geom_line(linewidth = 1, color = "steelblue") +
  geom_point(size = 2, color = "steelblue") +
  geom_smooth(method = "lm", se = TRUE, color = "red", linetype = "dashed") +
  labs(title = "Lexical Density Over Time", x = "Year", y = "Mean Lexical Density") +
  theme_minimal()
ggsave(file.path(output_dir, '15_lexical_density_over_time.png'), p15, width = 10, height = 6, dpi = 300, bg = 'white')

# 16. Genre-Typical vs Mainstream Vocabulary
p16 <- ggplot(df_analysis, aes(x = jaccard_genre, y = jaccard_corpus, color = macro_genre)) +
  geom_point(alpha = 0.4, size = 2) +
  scale_color_manual(values = genre_colors) +
  labs(title = "Genre-Typical vs Mainstream Vocabulary", x = "Jaccard Genre (genre-typical)", y = "Jaccard Corpus (mainstream)") +
  theme_minimal()
ggsave(file.path(output_dir, '16_genre_vs_mainstream.png'), p16, width = 10, height = 6, dpi = 300, bg = 'white')

# 17. Vocabulary Homogeneity Over Time
p17 <- ggplot(jaccard_trends, aes(x = year)) +
  geom_line(aes(y = mean_genre, color = "Genre-typical"), linewidth = 1) +
  geom_line(aes(y = mean_corpus, color = "Mainstream"), linewidth = 1) +
  geom_smooth(aes(y = mean_genre), method = "lm", se = FALSE, linetype = "dashed", color = "red") +
  labs(title = "Vocabulary Homogeneity Over Time", x = "Year", y = "Mean Jaccard", color = "Metric") +
  theme_minimal()
ggsave(file.path(output_dir, '17_vocab_homogeneity_over_time.png'), p17, width = 10, height = 6, dpi = 300, bg = 'white')

# 18. Genre-Typical vs Mainstream by Genre (with median reference lines)
p18 <- ggplot(df_analysis, aes(x = jaccard_genre, y = jaccard_corpus)) +
  geom_vline(data = jaccard_medians, aes(xintercept = median_jaccard_genre),
             linetype = "dashed", color = "gray40", linewidth = 0.5) +
  geom_hline(data = jaccard_medians, aes(yintercept = median_jaccard_corpus),
             linetype = "dashed", color = "gray40", linewidth = 0.5) +
  geom_point(aes(color = macro_genre), alpha = 0.4, size = 1.5) +
  scale_color_manual(values = genre_colors) +
  facet_wrap(~macro_genre, ncol = 3) +
  labs(title = "Genre-Typical vs Mainstream by Genre",
       subtitle = "Dashed lines show genre medians",
       x = "Jaccard Genre", y = "Jaccard Corpus") +
  theme(legend.position = "none")
ggsave(file.path(output_dir, '18_jaccard_by_genre.png'), p18, width = 12, height = 8, dpi = 300, bg = 'white')

cat(sprintf("\nExported 18 visualizations to %s\n", output_dir))
list.files(output_dir)

# ============================================
# SUMMARY STATISTICS TABLES
# ============================================

# --- 1. OVERALL DATASET STATISTICS ---
overall_stats <- tibble(
  Metric = c(
    "Total Songs in Dataset",
    "Songs with Complete Data (Analysis Set)",
    "Coverage Rate (%)",
    "Year Range",
    "Number of Genres",
    "Number of Unique Artists (Analysis Set)"
  ),
  Value = c(
    nrow(df),
    nrow(df_analysis),
    round(nrow(df_analysis) / nrow(df) * 100, 1),
    paste(min(df$year), "-", max(df$year)),
    n_distinct(df_analysis$macro_genre),
    n_distinct(df_analysis$band_singer)
  )
)

cat(paste(rep("=", 51), collapse=""), "\n")
cat("OVERALL DATASET STATISTICS\n")
cat(paste(rep("=", 51), collapse=""), "\n\n")
print(overall_stats, n = Inf)

# --- 2. OVERALL LEXICAL METRICS (All Songs) ---
overall_metrics <- df_analysis %>%
  summarise(
    n_songs = n(),
    # TTR
    ttr_mean = mean(ttr, na.rm = TRUE),
    ttr_median = median(ttr, na.rm = TRUE),
    ttr_sd = sd(ttr, na.rm = TRUE),
    ttr_min = min(ttr, na.rm = TRUE),
    ttr_max = max(ttr, na.rm = TRUE),
    ttr_q25 = quantile(ttr, 0.25, na.rm = TRUE),
    ttr_q75 = quantile(ttr, 0.75, na.rm = TRUE),
    # Lexical Density
    ld_mean = mean(lexical_density, na.rm = TRUE),
    ld_median = median(lexical_density, na.rm = TRUE),
    ld_sd = sd(lexical_density, na.rm = TRUE),
    ld_min = min(lexical_density, na.rm = TRUE),
    ld_max = max(lexical_density, na.rm = TRUE),
    # Rare Word Ratio
    rwr_mean = mean(rare_word_ratio, na.rm = TRUE),
    rwr_median = median(rare_word_ratio, na.rm = TRUE),
    rwr_sd = sd(rare_word_ratio, na.rm = TRUE),
    rwr_min = min(rare_word_ratio, na.rm = TRUE),
    rwr_max = max(rare_word_ratio, na.rm = TRUE),
    # Compression Ratio
    cr_mean = mean(compression_ratio, na.rm = TRUE),
    cr_median = median(compression_ratio, na.rm = TRUE),
    cr_sd = sd(compression_ratio, na.rm = TRUE),
    cr_min = min(compression_ratio, na.rm = TRUE),
    cr_max = max(compression_ratio, na.rm = TRUE),
    # Total Words
    tw_mean = mean(total_words, na.rm = TRUE),
    tw_median = median(total_words, na.rm = TRUE),
    tw_sd = sd(total_words, na.rm = TRUE),
    tw_min = min(total_words, na.rm = TRUE),
    tw_max = max(total_words, na.rm = TRUE)
  )

# Reshape to readable format
overall_summary <- tibble(
  Metric = c("Type-Token Ratio (TTR)", "Lexical Density", "Rare Word Ratio", 
             "Compression Ratio", "Total Words"),
  N = rep(overall_metrics$n_songs, 5),
  Mean = c(overall_metrics$ttr_mean, overall_metrics$ld_mean, overall_metrics$rwr_mean,
           overall_metrics$cr_mean, overall_metrics$tw_mean),
  Median = c(overall_metrics$ttr_median, overall_metrics$ld_median, overall_metrics$rwr_median,
             overall_metrics$cr_median, overall_metrics$tw_median),
  SD = c(overall_metrics$ttr_sd, overall_metrics$ld_sd, overall_metrics$rwr_sd,
         overall_metrics$cr_sd, overall_metrics$tw_sd),
  Min = c(overall_metrics$ttr_min, overall_metrics$ld_min, overall_metrics$rwr_min,
          overall_metrics$cr_min, overall_metrics$tw_min),
  Max = c(overall_metrics$ttr_max, overall_metrics$ld_max, overall_metrics$rwr_max,
          overall_metrics$cr_max, overall_metrics$tw_max)
) %>%
  mutate(across(where(is.numeric) & !matches("N"), ~round(., 4)))

cat("\n\n")
cat(paste(rep("=", 51), collapse=""), "\n")
cat("OVERALL LEXICAL METRICS (All Songs)\n")
cat(paste(rep("=", 51), collapse=""), "\n\n")
print(overall_summary, n = Inf, width = Inf)

# --- 3. LEXICAL METRICS BY GENRE ---
genre_detailed_stats <- df_analysis %>%
  group_by(macro_genre) %>%
  summarise(
    n_songs = n(),
    n_artists = n_distinct(band_singer),
    # TTR
    ttr_mean = round(mean(ttr, na.rm = TRUE), 4),
    ttr_median = round(median(ttr, na.rm = TRUE), 4),
    ttr_sd = round(sd(ttr, na.rm = TRUE), 4),
    ttr_min = round(min(ttr, na.rm = TRUE), 4),
    ttr_max = round(max(ttr, na.rm = TRUE), 4),
    # Lexical Density
    lex_density_mean = round(mean(lexical_density, na.rm = TRUE), 4),
    lex_density_median = round(median(lexical_density, na.rm = TRUE), 4),
    lex_density_sd = round(sd(lexical_density, na.rm = TRUE), 4),
    # Rare Word Ratio
    rare_word_mean = round(mean(rare_word_ratio, na.rm = TRUE), 4),
    rare_word_median = round(median(rare_word_ratio, na.rm = TRUE), 4),
    rare_word_sd = round(sd(rare_word_ratio, na.rm = TRUE), 4),
    # Compression Ratio
    compression_mean = round(mean(compression_ratio, na.rm = TRUE), 4),
    compression_median = round(median(compression_ratio, na.rm = TRUE), 4),
    compression_sd = round(sd(compression_ratio, na.rm = TRUE), 4),
    # Total Words
    total_words_mean = round(mean(total_words, na.rm = TRUE), 1),
    total_words_median = round(median(total_words, na.rm = TRUE), 1),
    total_words_sd = round(sd(total_words, na.rm = TRUE), 1),
    # Jaccard metrics
    jaccard_genre_mean = round(mean(jaccard_genre, na.rm = TRUE), 4),
    jaccard_corpus_mean = round(mean(jaccard_corpus, na.rm = TRUE), 4),
    .groups = 'drop'
  ) %>%
  arrange(desc(n_songs))

cat("\n\n")
cat(paste(rep("=", 51), collapse=""), "\n")
cat("DETAILED STATISTICS BY GENRE\n")
cat(paste(rep("=", 51), collapse=""), "\n\n")

# Display in sections for readability
cat("--- Song Counts ---\n")
print(genre_detailed_stats %>% select(macro_genre, n_songs, n_artists), n = Inf)

cat("\n--- TTR Statistics ---\n")
print(genre_detailed_stats %>% select(macro_genre, n_songs, ttr_mean, ttr_median, ttr_sd, ttr_min, ttr_max), n = Inf)

cat("\n--- Lexical Density Statistics ---\n")
print(genre_detailed_stats %>% select(macro_genre, n_songs, lex_density_mean, lex_density_median, lex_density_sd), n = Inf)

cat("\n--- Rare Word Ratio Statistics ---\n")
print(genre_detailed_stats %>% select(macro_genre, n_songs, rare_word_mean, rare_word_median, rare_word_sd), n = Inf)

cat("\n--- Compression Ratio Statistics ---\n")
print(genre_detailed_stats %>% select(macro_genre, n_songs, compression_mean, compression_median, compression_sd), n = Inf)

cat("\n--- Total Words Statistics ---\n")
print(genre_detailed_stats %>% select(macro_genre, n_songs, total_words_mean, total_words_median, total_words_sd), n = Inf)

cat("\n--- Jaccard Similarity Metrics ---\n")
print(genre_detailed_stats %>% select(macro_genre, n_songs, jaccard_genre_mean, jaccard_corpus_mean), n = Inf)

# --- 4. STATISTICAL TEST RESULTS ---
cat("\n\n")
cat(paste(rep("=", 51), collapse=""), "\n")
cat("STATISTICAL TEST RESULTS\n")
cat(paste(rep("=", 51), collapse=""), "\n\n")

# ANOVA results
anova_result <- aov(ttr ~ macro_genre, data = df_analysis)
anova_summary <- summary(anova_result)

cat("--- ANOVA: TTR across Genres ---\n")
cat(sprintf("F-value: %.2f\n", anova_summary[[1]]$`F value`[1]))
cat(sprintf("p-value: %.2e\n", anova_summary[[1]]$`Pr(>F)`[1]))
cat(sprintf("df (between): %d\n", anova_summary[[1]]$Df[1]))
cat(sprintf("df (within): %d\n", anova_summary[[1]]$Df[2]))

# Correlations table
correlations <- tibble(
  Variables = c(
    "TTR vs Chart Position",
    "Rare Word Ratio vs Chart Position",
    "Lexical Density vs Chart Position",
    "Jaccard Genre vs Chart Position",
    "Jaccard Corpus vs Chart Position",
    "TTR vs Year",
    "Rare Word Ratio vs Year",
    "Compression Ratio vs Year",
    "TTR vs Rare Word Ratio"
  ),
  Spearman_rho = c(
    cor(df_analysis$ttr, df_analysis$ranking, method = "spearman", use = "complete.obs"),
    cor(df_analysis$rare_word_ratio, df_analysis$ranking, method = "spearman", use = "complete.obs"),
    cor(df_analysis$lexical_density, df_analysis$ranking, method = "spearman", use = "complete.obs"),
    cor(df_analysis$jaccard_genre, df_analysis$ranking, method = "spearman", use = "complete.obs"),
    cor(df_analysis$jaccard_corpus, df_analysis$ranking, method = "spearman", use = "complete.obs"),
    cor(df_analysis$ttr, df_analysis$year, method = "spearman", use = "complete.obs"),
    cor(df_analysis$rare_word_ratio, df_analysis$year, method = "spearman", use = "complete.obs"),
    cor(df_analysis$compression_ratio, df_analysis$year, method = "spearman", use = "complete.obs"),
    cor(df_analysis$ttr, df_analysis$rare_word_ratio, method = "spearman", use = "complete.obs")
  )
) %>%
  mutate(Spearman_rho = round(Spearman_rho, 4))

cat("\n--- Spearman Correlation Results ---\n")
print(correlations, n = Inf, width = Inf)

# --- 5. EXPORT SUMMARY TABLES TO CSV ---

# Create comprehensive summary table combining all metrics by genre
genre_summary_export <- df_analysis %>%
  group_by(macro_genre) %>%
  summarise(
    n_songs = n(),
    n_unique_artists = n_distinct(band_singer),
    # TTR
    ttr_mean = round(mean(ttr, na.rm = TRUE), 4),
    ttr_median = round(median(ttr, na.rm = TRUE), 4),
    ttr_sd = round(sd(ttr, na.rm = TRUE), 4),
    ttr_min = round(min(ttr, na.rm = TRUE), 4),
    ttr_max = round(max(ttr, na.rm = TRUE), 4),
    ttr_q25 = round(quantile(ttr, 0.25, na.rm = TRUE), 4),
    ttr_q75 = round(quantile(ttr, 0.75, na.rm = TRUE), 4),
    # Lexical Density
    lexical_density_mean = round(mean(lexical_density, na.rm = TRUE), 4),
    lexical_density_median = round(median(lexical_density, na.rm = TRUE), 4),
    lexical_density_sd = round(sd(lexical_density, na.rm = TRUE), 4),
    lexical_density_min = round(min(lexical_density, na.rm = TRUE), 4),
    lexical_density_max = round(max(lexical_density, na.rm = TRUE), 4),
    # Rare Word Ratio
    rare_word_ratio_mean = round(mean(rare_word_ratio, na.rm = TRUE), 4),
    rare_word_ratio_median = round(median(rare_word_ratio, na.rm = TRUE), 4),
    rare_word_ratio_sd = round(sd(rare_word_ratio, na.rm = TRUE), 4),
    rare_word_ratio_min = round(min(rare_word_ratio, na.rm = TRUE), 4),
    rare_word_ratio_max = round(max(rare_word_ratio, na.rm = TRUE), 4),
    # Compression Ratio
    compression_ratio_mean = round(mean(compression_ratio, na.rm = TRUE), 4),
    compression_ratio_median = round(median(compression_ratio, na.rm = TRUE), 4),
    compression_ratio_sd = round(sd(compression_ratio, na.rm = TRUE), 4),
    compression_ratio_min = round(min(compression_ratio, na.rm = TRUE), 4),
    compression_ratio_max = round(max(compression_ratio, na.rm = TRUE), 4),
    # Total Words
    total_words_mean = round(mean(total_words, na.rm = TRUE), 1),
    total_words_median = round(median(total_words, na.rm = TRUE), 1),
    total_words_sd = round(sd(total_words, na.rm = TRUE), 1),
    total_words_min = min(total_words, na.rm = TRUE),
    total_words_max = max(total_words, na.rm = TRUE),
    # Jaccard Metrics
    jaccard_genre_mean = round(mean(jaccard_genre, na.rm = TRUE), 4),
    jaccard_corpus_mean = round(mean(jaccard_corpus, na.rm = TRUE), 4),
    jaccard_common_mean = round(mean(jaccard_common, na.rm = TRUE), 4),
    .groups = 'drop'
  ) %>%
  arrange(desc(n_songs))

# Add totals row
totals_row <- df_analysis %>%
  summarise(
    macro_genre = "ALL GENRES",
    n_songs = n(),
    n_unique_artists = n_distinct(band_singer),
    ttr_mean = round(mean(ttr, na.rm = TRUE), 4),
    ttr_median = round(median(ttr, na.rm = TRUE), 4),
    ttr_sd = round(sd(ttr, na.rm = TRUE), 4),
    ttr_min = round(min(ttr, na.rm = TRUE), 4),
    ttr_max = round(max(ttr, na.rm = TRUE), 4),
    ttr_q25 = round(quantile(ttr, 0.25, na.rm = TRUE), 4),
    ttr_q75 = round(quantile(ttr, 0.75, na.rm = TRUE), 4),
    lexical_density_mean = round(mean(lexical_density, na.rm = TRUE), 4),
    lexical_density_median = round(median(lexical_density, na.rm = TRUE), 4),
    lexical_density_sd = round(sd(lexical_density, na.rm = TRUE), 4),
    lexical_density_min = round(min(lexical_density, na.rm = TRUE), 4),
    lexical_density_max = round(max(lexical_density, na.rm = TRUE), 4),
    rare_word_ratio_mean = round(mean(rare_word_ratio, na.rm = TRUE), 4),
    rare_word_ratio_median = round(median(rare_word_ratio, na.rm = TRUE), 4),
    rare_word_ratio_sd = round(sd(rare_word_ratio, na.rm = TRUE), 4),
    rare_word_ratio_min = round(min(rare_word_ratio, na.rm = TRUE), 4),
    rare_word_ratio_max = round(max(rare_word_ratio, na.rm = TRUE), 4),
    compression_ratio_mean = round(mean(compression_ratio, na.rm = TRUE), 4),
    compression_ratio_median = round(median(compression_ratio, na.rm = TRUE), 4),
    compression_ratio_sd = round(sd(compression_ratio, na.rm = TRUE), 4),
    compression_ratio_min = round(min(compression_ratio, na.rm = TRUE), 4),
    compression_ratio_max = round(max(compression_ratio, na.rm = TRUE), 4),
    total_words_mean = round(mean(total_words, na.rm = TRUE), 1),
    total_words_median = round(median(total_words, na.rm = TRUE), 1),
    total_words_sd = round(sd(total_words, na.rm = TRUE), 1),
    total_words_min = min(total_words, na.rm = TRUE),
    total_words_max = max(total_words, na.rm = TRUE),
    jaccard_genre_mean = round(mean(jaccard_genre, na.rm = TRUE), 4),
    jaccard_corpus_mean = round(mean(jaccard_corpus, na.rm = TRUE), 4),
    jaccard_common_mean = round(mean(jaccard_common, na.rm = TRUE), 4)
  )

genre_summary_export <- bind_rows(genre_summary_export, totals_row)

# Export to CSV
write_csv(genre_summary_export, file.path(output_dir, 'lexical_analysis_summary_by_genre.csv'))
cat(sprintf("Exported genre summary to: %s/lexical_analysis_summary_by_genre.csv\n", output_dir))

# Export correlations table
write_csv(correlations, file.path(output_dir, 'lexical_analysis_correlations.csv'))
cat(sprintf("Exported correlations to: %s/lexical_analysis_correlations.csv\n", output_dir))

# Display final summary table
cat("\n\n")
cat(paste(rep("=", 51), collapse=""), "\n")
cat("EXPORTED SUMMARY TABLE (Genre Statistics)\n")
cat(paste(rep("=", 51), collapse=""), "\n\n")
print(genre_summary_export %>% select(macro_genre, n_songs, n_unique_artists, 
                                       ttr_mean, ttr_median, ttr_sd,
                                       lexical_density_mean, rare_word_ratio_mean,
                                       compression_ratio_mean, total_words_mean), 
      n = Inf, width = Inf)

