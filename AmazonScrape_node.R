
library(rvest)
library(dplyr)

reviews_df = data.frame()
for (page_result in seq(from = 1, to = 3, by = 1)) {
  
  link = paste0("https://www.amazon.com/Apple-Generation-Cancelling-Transparency-Personalized/product-reviews/B0BDHWDR12/ref=cm_cr_getr_d_paging_btm_prev_",
                page_result,"?ie=UTF8&reviewerType=all_reviews&pageNumber=",page_result)

  page = read_html(link)
  name = page %>% html_nodes(".a-profile-name") %>% html_text()
  rating = page %>% html_nodes(".review-star-rating") %>% html_text()
  review = page %>% html_nodes(".review-text-content span , .a-spacing-top-mini .a-size-base") %>% html_text()
  
  length(review) <- length(name)
  length(rating) <- length(name)
  
  
  reviews_df <- rbind(reviews_df, data.frame(name,rating,review)) %>% distinct(name,.keep_all = TRUE)
  #reviews_df <- reviews_df %>% distinct(name, .keep_all= TRUE)
  

  
  # show page number its scraping from
  print(paste("Page:", page_result))
}



#numeric rating
reviews_df[] <- lapply(reviews_df, gsub, pattern = " out of 5 stars", replacement ="")
reviews_df$rating <- as.integer(reviews_df$rating)



#Word clouds and Sentiment analysis


library("textdata")
library(tidyverse)
library(tidytext)
library(widyr)
library(wordcloud)


get_sentiments("afinn")
get_sentiments("bing")


review_words <- reviews_df %>%
  unnest_tokens(output = word, input = review) %>%
  anti_join(stop_words, by = "word") %>%
  filter(str_detect(word, "[:alpha:]")) %>%
  distinct()

#negative
review_words <- review_words %>%
  filter(rating <=2)

library(igraph)
library(ggraph)

#words frequency
users_who_mention = review_words %>%
  dplyr::count(word, name = "users_n", sort = TRUE) %>%
  filter(users_n > 4)



#word corrrelation
word_correlation <- review_words %>%
  semi_join(users_who_mention, by = "word") %>%
  pairwise_cor(item = word, feature = name) %>%
  filter(correlation > 0.6)
  
  

graph_from_data_frame(d= word_correlation,
                      vertices = users_who_mention %>%
                        semi_join(word_correlation, by = c("word" = "item1"))) %>%
  ggraph(layout = "fr") +
  geom_edge_link() +
  geom_node_point() +
  geom_node_text(aes(color = users_n, label = name), repel = TRUE)


library(RColorBrewer)
review_words %>%
  filter(word != "rt", word != "https", word != "t.co") %>%
  dplyr::count(word, sort = TRUE) %>%
  with(wordcloud(word,n, scale = c(4,1), min.freq = 10, max.words = 50,colors=brewer.pal(8, "Dark2")))



library("reshape2")
review_words %>%
  inner_join(get_sentiments("afinn")) %>%
  inner_join(get_sentiments("bing")) %>%
  dplyr::count(word, sentiment, sort = TRUE) %>%
  acast(word ~ sentiment, value.var = 'n', fill = 0) %>%
  comparison.cloud( scale = c(4,1), colors = c("red", "blue"), min.freq = 500, max.words = 70)


