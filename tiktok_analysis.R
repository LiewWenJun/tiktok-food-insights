library(tidyverse)
library(scales)
# To read an excel file
library(readxl)
# To convert ISO 8601 time format to POSIXct format
library(lubridate)

# Importing data
dataset <- read_excel("tiktok_dataset.xlsx")

# Selecting useful columns
dataset <- dataset %>%
  select(
    `authorMeta/digg`,
    `authorMeta/fans`,
    `authorMeta/verified`,
    `authorMeta/video`,
    `authorMeta/id`,
    `videoMeta/duration`,
    text,
    commentCount,
    diggCount,
    playCount,
    shareCount,
    createTimeISO,
    `musicMeta/musicOriginal`,
    `hashtags/0/name`,
    `hashtags/1/name`,
    `searchHashtag/name`,
    `searchHashtag/views`
  )

# Renaming the columns

dataset <- dataset %>%
  rename(
    total_likes = `authorMeta/digg`,
    total_followers = `authorMeta/fans`,
    verification = `authorMeta/verified`,
    total_videos = `authorMeta/video`,
    author_id = `authorMeta/id`,
    video_duration = `videoMeta/duration`,
    caption = text,
    comment_count = commentCount,
    likes_count = diggCount,
    plays_count = playCount,
    shares_count = shareCount,
    time_posted = createTimeISO,
    original_music = `musicMeta/musicOriginal`,
    first_hashtag = `hashtags/0/name`,
    second_hashtag = `hashtags/1/name`,
    search_hashtag = `searchHashtag/name`
  )

# Cleaning of data
dataset <- dataset %>%
  mutate(
    hashtag_count = str_count(caption, "#"),
    verification = case_when(
      verification == "true"  ~ "Verified",
      verification == "false" ~ "Not Verified",
      TRUE ~ NA_character_
    ),
    verification = factor(verification, levels = c("Not Verified", "Verified")),
    time_posted = ymd_hms(time_posted)
  ) %>%
  drop_na() %>%
  filter(
    # - video_duration <= 100 sec to exclude unusually long videos
    # - likes_count >= 100000 to focus on popular videos with meaningful stats
    # - hashtag_count <= 25 to avoid posts overloaded with hashtags which might skew analysis
    video_duration <= 100,
    likes_count >= 100000,
    hashtag_count <= 25
    )

# New column to show weekday/weekend
dataset <- dataset %>%
  mutate(
    weekday = wday(time_posted, label = TRUE),
    hour_posted = hour(time_posted),
    )


#Testing reliability of likes, plays, share counts by seeing if theres a linear rs

# ---------------- Plot: Likes Count VS Plays Count ----------------------
ggplot(dataset, aes(x = likes_count, y = plays_count)) +
  geom_point(alpha = 0.5, colour = "darkgrey") +
  scale_y_log10(labels = label_comma()) +
  scale_x_log10(labels = label_comma()) +
  labs(title = "Likes Count VS Plays Count", x = "Likes Count", y = "Plays Count" )

ggsave("images/likes_vs_plays.png", width = 8, height = 6, dpi = 300)


# ---------------- Plot: Likes Count VS Shares Count ---------------------
ggplot(dataset, aes(x = likes_count, y = shares_count)) +
  geom_point(alpha = 0.5, colour = "black") +
  scale_y_log10(labels = label_comma()) +
  scale_x_log10(labels = label_comma()) +
  labs(title = "Likes Count VS Shares Count", x = "Likes Count", y = "Shares Count")

ggsave("images/likes_vs_shares.png", width = 8, height = 6, dpi = 300)



# ---------------- Plot: Verification VS Likes Count ---------------------

ggplot(dataset, aes(x = verification, y = likes_count)) +
  geom_boxplot(fill = "skyblue") +
  scale_y_log10(labels = label_comma()) +
  labs(title = "Verification VS Likes Count", x = "Verification", y = "Likes Count")

ggsave("images/verification_vs_likes.png", width = 8, height = 6, dpi = 300)



# ---------------- Plot: Video Duration VS Likes Count -------------------
ggplot(dataset, aes(x = video_duration, y = likes_count)) +
  geom_point(alpha = 0.3, colour = "purple") +
  scale_y_log10(labels = label_comma()) +
  labs(title = "Video Duration VS Likes Count", x = "Video Duration", y = "Likes Count")

ggsave("images/duration_vs_likes.png", width = 8, height = 6, dpi = 300)



# ---------------- Plot: Weekday VS Likes Count --------------------------
dataset %>%
  group_by(weekday) %>%
  summarise(median_likes = median(likes_count, na.rm = TRUE)) %>%
  ggplot(aes(x = weekday, y = median_likes)) +
  geom_col(fill = "tomato") +
  scale_y_continuous(labels = label_comma()) +
  labs(title = "Median Likes by Weekday", x = "Day of Week", y = "Median Likes") +
  theme_minimal()

ggsave("images/weekday_vs_likes.png", width = 8, height = 6, dpi = 300)


# --------------- Plot: Time Posted VS Likes Count -----------------------
dataset %>%
  group_by(hour_posted) %>%
  summarise(median_likes = median(likes_count, na.rm = TRUE)) %>%
  ggplot(aes(x = hour_posted, y = median_likes)) +
  geom_col(fill = "goldenrod") +
  scale_y_continuous(labels = label_comma()) +
  labs(title = "Hour Posted VS Likes Count", x = "Hour Posted", y = "Median Likes")

ggsave("images/timeposted_vs_likes.png", width = 8, height = 6, dpi = 300)



# ---------------- Plot: Number of Hashtags VS Likes Count -----------------
dataset %>%
  ggplot(aes(x = hashtag_count, y = likes_count)) +
  geom_point(alpha = 0.5, colour = "blue") +
  scale_y_log10(labels = label_comma()) +
  labs(title = "Number of Hashtags VS Likes Count", x = "Number of Hashtags", y = "Likes Count")

ggsave("images/numberofhashtags_vs_likes.png", width = 8, height = 6, dpi = 300)




# ---------------- Plot: Comments Count VS Likes Count -----------------------
ggplot(dataset, aes(x = comment_count, y = likes_count)) +
  geom_point(alpha = 0.5, colour = "grey") +
  scale_y_log10(labels = label_comma()) +
  scale_x_log10(labels = label_comma()) +
  labs(title = "Comments Count VS Likes Count", x = "Number of Comments", y = "Likes Count")

ggsave("images/comments_vs_likes.png", width = 8, height = 6, dpi = 300)



# ---------------- Plot: Original Music VS Likes Count ---------------------
ggplot(dataset, aes(x = original_music, y = likes_count)) +
  geom_boxplot(fill = "lightgreen") +
  scale_y_log10(labels = label_comma()) +
  labs(title = "Original Music VS Likes Count", x = "Original Music Used", y = "Likes Count")

ggsave("images/originalmusic_vs_likes.png", width = 8, height = 6, dpi = 300)



# First Hashtag: Top 10
top_first_hashtags_views <- dataset %>%
  filter(!is.na(first_hashtag)) %>%
  group_by(first_hashtag) %>%
  summarise(median_views = median(plays_count, na.rm = TRUE)) %>%
  arrange(desc(median_views)) %>%
  slice_head(n = 10)

# ---------------- Plot: Top 10 hashtags VS Median Views ---------------------
top_first_hashtags_views %>%
  ggplot(aes(x = reorder(first_hashtag, median_views), y = median_views)) +
  geom_col(fill = "steelblue") +
  coord_flip() +
  scale_y_continuous(labels = label_comma()) +
  labs(title = "Top 10 First Hashtags by Median Views", x = "First Hashtag", y = "Median Views")

ggsave("images/top10hashtag_vs_views.png", width = 8, height = 6, dpi = 300)



