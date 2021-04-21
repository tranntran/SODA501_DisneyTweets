rm(list = ls())
library(httr)
library(jsonlite)
library(data.table)
# TwitterDev sample code
# https://github.com/twitterdev/Twitter-API-v2-sample-code/blob/master/Full-Archive-Search/full-archive-search.r
# API ref 
# https://developer.twitter.com/en/docs/twitter-api/tweets/search/api-reference/get-tweets-search-all
# Query ref
# https://developer.twitter.com/en/docs/twitter-api/tweets/search/integrate/build-a-query

# Replace the bearer token below with your token
bearer_token = "xxx"

headers = c(
  `Authorization` = sprintf('Bearer %s', bearer_token)
)

# Set start time and end time
start_time = '2019-01-01T00:00:00Z'
end_time = '2020-01-01T00:00:00Z'

# List of tweet and user variables, used for renaming and data organization
tweet_vars = c('id', 'created_at', 'text', 'public_metrics', 'geo', 'context_annotations',
         'author_id', 'possibly_sensitive', 'lang')
user_vars = c("id", "username", "name", "location", "description", "public_metrics", "created_at")
final_vars = c("user_id", "id", "created_at", "text", "public_metrics.retweet_count", 
              "public_metrics.reply_count", "public_metrics.like_count", "public_metrics.quote_count",          
              "geo.place_id", "geo.coordinates.type", "context_annotations", 
              "possibly_sensitive", "lang", "user_username", "user_name",
              "user_location", "user_description","user_public_metrics.followers_count", 
              "user_public_metrics.following_count", "user_public_metrics.tweet_count",
              "user_public_metrics.listed_count", "user_created_at")
data = NULL

# Because max tweets return for each query is 500, a while loop is needed to mine
# all the tweets in the specified period. After each iteration, the end time is updated
# using the earliest tweet time. The while loop will end when end_time is earlier 
# than the start time

keyword = 'disney'

while (start_time < end_time){
  params = list(
    # search for tweets with disney in Orlando, FL, and exclude retweet
    `query` = paste(keyword, 'lang:en place:"Orlando, FL" -is:retweet'),
    #'disneyland lang:en place:"Orlando, FL" -is:retweet',
    `end_time` = end_time,
    `max_results` = '500',
    `expansions` = 'author_id',
    # list of tweet variables to include
    `tweet.fields` = 'created_at,geo,public_metrics,possibly_sensitive,author_id,lang,context_annotations',
    # list of user variables to include
    `user.fields` = 'created_at,description,id,location,name,public_metrics,username'
  )
  #note - possible tweet.fields
  #attachments, author_id, context_annotations, conversation_id, created_at,
  #entities, geo, id, in_reply_to_user_id, lang, public_metrics,
  #possibly_sensitive, referenced_tweets, reply_settings, source, text, withheld
  
  # mine tweets and parse it into list of df
  response <- httr::GET(url = 'https://api.twitter.com/2/tweets/search/all', 
                        httr::add_headers(.headers=headers), query = params)
  date_time<-Sys.time()
  fas_body <- content(response, as = 'parsed', type = 'application/json',
                      simplifyDataFrame = TRUE)
  
  # update end time
  end_time = min(fas_body$data$created_at)
  
  # save recently mined tweets and organize the order of the var columns
  temp_data = fas_body$data
  temp_data = temp_data[tweet_vars]
  
  # save info of users and organize the order and rename the columns
  user_data = fas_body$includes$users
  user_data = user_data[user_vars]
  colnames(user_data) = paste('user', user_vars, sep = '_')
  
  # merge tweets and users table by user_id
  temp_merge = merge(temp_data, user_data, by.x = c('author_id'), by.y = c('user_id'))
  temp_merge = as.data.table(temp_merge)
  setnames(temp_merge, 'author_id', 'user_id')
  
  # because geo.coordinates.coordinates is saved as a list, resave it into 2 columns lon lat instead
  if (!is.null(temp_merge$geo.coordinates.coordinates)){
    temp_coordinates = ifelse(!is.na(temp_merge$geo.coordinates.type), temp_merge$geo.coordinates.coordinates, NA)
    temp_coordinates = t(as.data.table(temp_coordinates))
  } else { # account for cases where there are no geo coordinates
    temp_merge$geo.coordinates.type = NA
    temp_merge$geo.coordinates.coordinates = NA
    setcolorder(temp_merge, final_vars)
    temp_coordinates = as.data.table(matrix(NA, ncol = 2, nrow = nrow(temp_merge)))
  }
  colnames(temp_coordinates) = c('tweet_lon', 'tweet_lat')
  temp_merge = cbind(temp_merge, temp_coordinates)
  temp_merge$geo.coordinates.coordinates = NULL

  # make sure the data is within the desired range of time
  temp_merge = temp_merge[created_at >= start_time]
  
  # bind them to the main data
  data = rbind(data, temp_merge)
  # make sure that there is at least 1 section between each query
  while((as.numeric(Sys.time()) - as.numeric(date_time))<1){}
}

# reorder data based on the date of the tweets
data1 = data[order(created_at)]

filename = paste('2019_disney_orlando_tweets_', 
                 paste(c(unlist(strsplit(keyword, " "))), collapse = "_"), 
                 sep = "")
# save as Rdata
#save(data1, file = paste0('./data/Rdata/',filename, '.RData'))

# context_annotations is saved as a list, so need to delete this column before
# saving as csv file
data1$context_annotations = NULL
# save as csv file
fwrite(data1, file = paste0('./data/csv/',filename, '.csv'))
