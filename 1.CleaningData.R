

##BLOQUE DE CARGA DE LIBRERÍAS

if(!require("readr")){
  install.packages("ggplot2")
  library("ggplot2")
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
if (!require("e1071")){
  install.packages("e1071")
  library("e1071")
}
if (!require("ROCR")){
  install.packages("ROCR")
  library("ROCR")
}
if (!require("glmnet")){
  install.packages("glmnet") 
  library("glmnet")
}
if (!require("caTools")){
  install.packages("caTools") 
  library(caTools)
}

if (!require("tidyverse")){
  install.packages("tidyverse") 
  library(tidyverse)
}

if (!require("reshape2")){
  install.packages("reshape2") 
  library(reshape2)
}
#path de archivos

read_imdb <- function(data_path) {
  path <- "~/Desktop/MASTER DATA SCIENCE/TFM//"
  read_tsv(paste0(path, data_path), na = "\\N", quote='', progress=F)
}


## Filtro por únicamente por Series desde el año 2000 y las features que nos interesan

df_ratings <- read_imdb("title.ratings.tsv")
df_basics <- read_imdb('title.basics.tsv') %>%  select (tconst, titleType, originalTitle, startYear, endYear, runtimeMinutes, genres) %>% 
  filter (titleType %in% c("tvSeries") & startYear >= 2000)

df_basics <- df_basics %>% left_join(df_ratings)

## Separar en filas los géneros, posteriormente nos quedamos solo con un género para simplificar

df_basics_unnest <- df_basics %>% unnest_tokens(genre, genres, token = str_split, pattern= ",")

df_basics_unnest <- df_basics_unnest[!duplicated(df_basics_unnest$tconst), ]

## Extraer el número de capítulos por serie

df_episode <- read_imdb("title.episode.tsv") %>% filter(!is.na(seasonNumber))

df_episode_count <- df_episode %>% group_by(parentTconst) %>% tally() %>% left_join(df_basics,  c("parentTconst" = "tconst"))
df_episode_count <- df_episode_count %>%  select (parentTconst, n)

## Extraemos los directores y formateamos para el posterior merge con df_Principals

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

#Cargamos la tabla de nombres de actores

df_actors <- read_imdb("name.basics.tsv") %>% select(nconst, primaryName)

df_Principals <-  df_Principals %>% left_join(df_actors)


#Joins de las tablas

Series <- df_basics_unnest %>% left_join(df_episode_count,  c("tconst" = "parentTconst"))
Series <- Series %>%  left_join(df_Principals)

# Reorganizamos las categorías por 'ordering' y basamos el reshape en este orden

Series <- Series %>%  
  mutate(ordering = ifelse(category =="actor", 1, ordering)) %>% 
  mutate(ordering = ifelse(category =="actress", 2, ordering)) %>%  
  mutate(ordering = ifelse(category =="director", 3, ordering)) %>% 
  mutate(ordering = ifelse(category =="writer", 4, ordering))

Series <- dcast(Series, tconst+titleType+originalTitle+startYear+endYear+runtimeMinutes+averageRating+numVotes+genre+n~ordering, value.var = "primaryName",
                fun.aggregate=function(x) paste(x, collapse = ", "))

#Renombramos columnas y separamos la crew en columnas

names(Series)[10] <- "numberOfEpisodes"
names(Series)[11] <- "actors"
names(Series)[12] <- "actress"
names(Series)[13] <- "director"
names(Series)[14] <- "writer"

Series <- Series %>%  separate(actors, into= c("actors1", "actors2", "actors3"), sep = ",")
Series <- Series %>%  separate(actress, into= c("actress1", "actress2", "actress3"), sep = ",")
Series <- Series %>%  separate(director, into= c("director1"), sep = ",")
Series <- Series %>%  separate(writer, into= c("writer1"), sep = ",")

# Transformar los NA a 0

Series$numVotes[is.na(Series$numVotes)] <- 0
Series$startYear[is.na(Series$startYear)] <- 0
Series$endYear[is.na(Series$endYear)] <- 0
Series$numberOfEpisodes[is.na(Series$numberOfEpisodes)] <- 0
Series$runtimeMinutes[is.na(Series$runtimeMinutes)] <- 0
Series$averageRating[is.na(Series$averageRating)] <- 0
Series$genre[is.na(Series$genre)] <- 0

# Añadimos la columna 'Finalization' para separar a la hora del modelo y entrenar solo con los finalizados

Series$Finalization <- ifelse(Series$endYear != 0, 1, 0)

#Guardamos en disco la bbdd en bruto

write.csv(Series, file= "Series_.csv")

