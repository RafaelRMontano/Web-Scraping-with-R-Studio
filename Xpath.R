library(rvest)
library(xml2)
library(jsonlite)
library(dplyr)


url <- "https://www.amazon.com/Apple-Generation-Cancelling-Transparency-Personalized/product-reviews/B0BDHWDR12/ref=cm_cr_dp_d_show_all_btm?ie=UTF8&reviewerType=all_reviews"
page <- read_html(url)

reviews_df = data.frame()



name = page %>% html_elements(xpath = "//div[starts-with(@class, 'a-section a-spacing-none reviews-content a-size-base')]") %>%
  html_elements(xpath = ".//span[@class= 'a-profile-name']") %>% html_text() 

text = page %>% html_elements(xpath = "//div[starts-with(@class, 'a-row a-spacing-small review-data')]") %>% html_text() 


star = page %>% html_elements(xpath = "//div[starts-with(@class, 'a-section a-spacing-none reviews-content a-size-base')]") %>%
  html_elements(xpath = ".//span[@class= 'a-icon-alt']") %>% html_text() 

# correct lengths
length(text) <- length(name)
length(star) <- length(name)

#bind name and ratings
reviews_df <- rbind(reviews_df, data.frame(name,star,text)) %>% distinct(name, .keep_all = TRUE)

#numeric rating
reviews_df[] <- lapply(reviews_df, gsub, pattern = " out of 5 stars", replacement ="")
reviews_df$star <- as.integer(reviews_df$star)




# just reviews only
#df <- data.frame(text) %>% distinct(text) %>% filter(text != "NA")
#bind text
#reviews_df <- cbind(reviews_df,df)


