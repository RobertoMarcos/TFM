
# CLEANING_DATA

if(!require("readr")){
  install.packages("readr")
  library("readr")
}
if(!require("ggplot2")){
  install.packages("ggplot2")
  library("ggplot2")
}
if(!require("dplyr")){
  install.packages("dplyr")
  library("dplyr")  
}
if(!require("tidytext")){
  install.packages("tidytext")
  library("tidytext")
}
if (!require("tidyverse")){
  install.packages("tidyverse") 
  library(tidyverse)
}

if (!require("reshape2")){
  install.packages("reshape2") 
  library(reshape2)
}

if (!require("stringr")){
  install.packages("stringr") 
  library(stringr)
}

#file path

read_imdb <- function(data_path) {
  path <- "~/Desktop/MASTER DATA SCIENCE/TFM//" #Escoge el path en el que están los archivos
  read_tsv(paste0(path, data_path), na = "\\N", quote='', progress=F)
}

## Filter by only by Series since 1990 and the features that interest us

df_ratings <- read_imdb("title.ratings.tsv")
df_basics <- read_imdb('title.basics.tsv') %>%  select (tconst, titleType, originalTitle, startYear, endYear, runtimeMinutes, genres) %>% 
  filter (titleType %in% c("tvSeries") & startYear >= 1990)

df_basics <- df_basics %>% left_join(df_ratings)

## Separate the genres in rows, later we are left with only one gender to simplify

df_basics_unnest <- df_basics %>% unnest_tokens(genre, genres, token = str_split, pattern= ",")

df_basics_unnest <- df_basics_unnest[!duplicated(df_basics_unnest$tconst), ]

## Extract the number of chapters series

df_episode <- read_imdb("title.episode.tsv") %>% filter(!is.na(seasonNumber))

df_episode_count <- df_episode %>% group_by(parentTconst) %>% tally() %>% left_join(df_basics,  c("parentTconst" = "tconst"))
df_episode_count <- df_episode_count %>%  select (parentTconst, n)

## We extract the directors and we format for the later merge with df_Principals

df_directorsWritters <- read_imdb("title.crew.tsv")
names(df_directorsWritters)[3] <- "writer"
names(df_directorsWritters)[2] <- "director"
df_directorsWritters <- df_directorsWritters %>%  gather ("director", "writer", key = category, value = function(x) paste(x, collapse = ","))
names(df_directorsWritters)[3] <- "nconst"
df_directorsWritters$ordering <- 0

df_directorsWritters <- df_directorsWritters %>%  
  mutate(ordering = ifelse(category =="director", 3, ordering)) %>% 
  mutate(ordering = ifelse(category =="writer", 4, ordering))

df_directorsWritters<- df_directorsWritters %>% separate(nconst, into = c("nconst1", "nconst2"), sep= "," )
names(df_directorsWritters)[3] <- "nconst"
df_directorsWritters <- df_directorsWritters %>% select (tconst, category, nconst, ordering)

df_Principals <-  read_imdb("title.principals.tsv") %>% 
  filter(ordering %in% c("1", "2", "3", "4", "5"))%>% 
  filter(str_detect(category, "actor|actress|director|writer")) %>%
  select (tconst, ordering,nconst, category) %>%
  group_by(tconst)

df_Principals <- df_Principals[ !duplicated(df_Principals) ,]

df_Principals <- rbind.data.frame(df_Principals, df_directorsWritters)

## We load the table of names of actors

df_actors <- read_imdb("name.basics.tsv") %>% select(nconst, primaryName)

df_Principals <-  df_Principals %>% left_join(df_actors)

## Joins of the tables

Series <- df_basics_unnest %>% left_join(df_episode_count,  c("tconst" = "parentTconst"))
Series <- Series %>%  left_join(df_Principals)

## We reorganized the categories by 'ordering' and based the reshape in this order

Series <- Series %>%  
  mutate(ordering = ifelse(category =="actor", 1, ordering)) %>% 
  mutate(ordering = ifelse(category =="actress", 2, ordering)) %>%  
  mutate(ordering = ifelse(category =="director", 3, ordering)) %>% 
  mutate(ordering = ifelse(category =="writer", 4, ordering))

Series <- dcast(Series, tconst+titleType+originalTitle+startYear+endYear+runtimeMinutes+averageRating+numVotes+genre+n~ordering, value.var = "primaryName",
                fun.aggregate=function(x) paste(x, collapse = ", "))

## We rename columns and separate the crew into columns

names(Series)[10] <- "numberOfEpisodes"
names(Series)[11] <- "actors"
names(Series)[12] <- "actress"
names(Series)[13] <- "director"
names(Series)[14] <- "writer"


## Transform all blank cells into NA

is.na(Series) <- Series==''

## New columns counting the number of actors and actresses per series

library(stringr)
Series$GenderMale <- str_count(Series$actors, ',')+1
Series$GenderFeMale <- str_count(Series$actress, ',')+1

## We separate the actors by columns 

Series <- Series %>%  separate(actors, into= c("actors1", "actors2", "actors3"), sep = ",")
Series <- Series %>%  separate(actress, into= c("actress1", "actress2", "actress3"), sep = ",")
Series <- Series %>%  separate(director, into= c("director1"), sep = ",")
Series <- Series %>%  separate(writer, into= c("writer1"), sep = ",")

## Transform the NA to 0

Series$numVotes[is.na(Series$numVotes)] <- 0
Series$startYear[is.na(Series$startYear)] <- 0
Series$endYear[is.na(Series$endYear)] <- 0
Series$numberOfEpisodes[is.na(Series$numberOfEpisodes)] <- 0
Series$runtimeMinutes[is.na(Series$runtimeMinutes)] <- 0
Series$averageRating[is.na(Series$averageRating)] <- 0
Series$genre[is.na(Series$genre)] <- 0
Series$GenderMale[is.na(Series$GenderMale)] <- 0
Series$GenderFeMale[is.na(Series$GenderFeMale)] <- 0

## We add the column 'Finalization' to separate at the time of the model and train only with the finished ones

Series$Finalization <- ifelse(Series$endYear != 0, 1, 0)

## We save the raw bbdd on disk

write.csv(Series, file= "Series_2.csv")


## We remove all the genres that do not interest us since it is not a series

table(Series$genre)

Series<-Series[Series$genre!="music",]
Series<-Series[Series$genre!="0",]
Series<-Series[Series$genre!="short",]
Series<-Series[Series$genre!="game-show",]
Series<-Series[Series$genre!="reality-tv",]
Series<-Series[Series$genre!="sport",]


## In order to reach some conclusion we will filter by the following variables in a first model without crew

SeriesAll <- Series %>% filter (numberOfEpisodes  > 6 & averageRating > 0.1  & runtimeMinutes >10 ) %>% select (numberOfEpisodes, Finalization, originalTitle, startYear, endYear, runtimeMinutes, averageRating, 
                                                                                                                numVotes, genre)
SeriesAll <- SeriesAll %>% filter (numberOfEpisodes  < 100 & runtimeMinutes < 80 )

write.csv(SeriesAll, file= "SeriesModelo1.csv")

## We perform the same filter but adding now if the crew through the genre and overwrite

SeriesAll2 <- Series %>% filter (numberOfEpisodes  > 6 & averageRating > 0.1  & runtimeMinutes >10 ) %>% select (numberOfEpisodes, Finalization, originalTitle, startYear, endYear, runtimeMinutes, averageRating, 
                                                                                                                 numVotes, genre,GenderMale, GenderFeMale)
SeriesAll2 <- SeriesAll2 %>% filter (numberOfEpisodes  < 100 & runtimeMinutes < 80 )

write.csv(SeriesAll2, file= "SeriesModelo2.csv")

