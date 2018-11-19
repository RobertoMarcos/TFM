# Prediction Finalization Series TV
### Master Data Science - K SCHOOL
### Author: Roberto Marcos Aparicio


## Introduction 

This project aims to predict the number of chapters that a television series will have by estimating through machine learning based on a series of variables (number of votes, ratings, average runtime minutes of chapters, among others) provided by the database from the [IMDB] page (https://datasets.imdbws.com/).

The final tool is aimed at all users who are fans of television series so they can make the decision if they want to see a series based on the number of chapters that will have and therefore, know in what episode will end.

## Technology

```
Python 3.6.5
+ jupyter notebook
+ pandas 0.23.0
+ numpy 1.12.1
+ matplotlib 3.0.0
+ sklearn 0.20.0
+ xgboost 0.80

R 3.5.1 
+ RStudio 
+ reshape2 1.4.3
+ readr 1.1.1
+ dplyr 0.7.6
+ tidyverse 1.2.1

Apache Superset

Amazon Web Services


AWS
```

## Description of dataset fields

* **numberOfEpisodes**. Number of episodes in the series (from 6 to 100)
* **Finalization**. 1 if it has ended 0 if not
* **startYear**. Year of the beginning of the series
* **endYear**. Year of finished of the series.
* **runtimeMinutes**. Average duration chapters of the serie.
* **averageRating**. Average rating of the series according to IMDB users.
* **numVotes**. Number of votes obtained according to IMB users.
* **genre**. Gender of the series.
* **genderMale**. Number of male actors in the series.
* **genderFemale**. Number of female actresses in the series.

## Methodology

### 0. Download data

The data can be downloaded in [IMDB](https://datasets.imdbws.com/) and the description of the fields in the following [documentation](https://www.imdb.com/interfaces/).


### [1. Cleaning Data](https://github.com/RobertoMarcos/TFM-PredictionFinalizationTVSeries/blob/master/1.%20CleaningData.R).

* Programming language: R*
  
  After downloading the data and assigning the path, the series data are filtered since 1990 to obtain a greater volume of data. The objective is to gather in the same dataset the information aggregated by series of the number of chapters, rating, year of beginning, year of end, average runtime minutes of the episodes, number of votes, the gender to which it belongs and the actors, actresses, directors and writers that compose it. No other relevant information is available in this dataset, such as audiences to include it.

In addition, by not having a field to know if the series has ended, it is concluded that the endyear NA field is transformed to 0 and therefore a new one is created to know if it has finished or not.

After a series of previous visualizations, it is decided due to the bias of the data, increase the minimum number of chapters to 6 to try to minimize the negative bias and a maximum of 100 since there is no more volume from this number.

For its part, the rating for votes to start at 0.1 and the duration of the series is between 10 and 80 minutes since the data are indications that can be feature films (> 80) and short films (<10)

Finally, all those series that are of genres not associated with television series are eliminated, keeping the dataset in two parts for the subsequent treatment in two models.

### [2.	Data_Visualizations](https://github.com/RobertoMarcos/TFM-PredictionFinalizationTVSeries/blob/master/2.%20Data_Visualizations.ipynb)

* Programming language: Python*
  
  Observations on each variable and its corresponding correlation (or not as in this case)

### [3. Data_Modeling](https://github.com/RobertoMarcos/TFM-PredictionFinalizationTVSeries/blob/master/3.%20Data_Modeling.ipynb)

* Programming language: Python*
  
  In this notebook the 'goldsmith' data.

'Featuring engineering' transforming the numerical variables of the X by sklearn MinMaxScaler so that the range of variables is between 0 and 1 (later genderMale and genderFemale) and dummies for the genre categories of each film.

At first, choose to categorize the distribution using the h2o library, which opens a cluster distributed on the machine itself and with categorical_encoding = 'one_hot_explicit', transforms the variable when training with H2OXGBoostEstimator as well as normalizing and regularizing it.

The result of the weight of each distribution variable was very low and did not give value to the model adding many columns and noise, for this reason I decided to count the number of actors and actresses that there are per series.

The project is a linear regression problem in which the number of final chapters had to be estimated and the variables available in the dataset had no correlation (sometimes negative) and many of the data were biased, such as the number of chapters of the majority of the series was below 15 episodes, number of votes below 5 has influenced the time of the result, being a pretty pessimistic model in terms of estimation.

At the time of training the first model without casting I did it with all those series that had already finished so I could learn from it. Later this same model should predict with the subset unfinished to estimate.

When looking for a regression, choose to regularize using Ridge, Lasso, ElasticNet and Bayesian as the first form of approximation.

Later I chose to use Gradient Boosted Trees, an algorithm under the XGBOOST library that optimizes the results.

In all the models, when validating with the set of not finished the metric 'r2' was very low, that is, the model did not have a good indicator to generalize based on the set of training provided.

The output of the model is indexed in the unfinished episodes dataset and the csv to sql is transformed to use Apache Superset.

### [3. Dashboad ApacheSuperSet](http://superset-1998162619.eu-west-1.elb.amazonaws.com/r/5)

The dashboard is hosted on AWS and the front-end on Apache Superset. 
The url and public access is as follows:
  
  [**How wrong are my predictions?**](http://superset-1998162619.eu-west-1.elb.amazonaws.com/r/5)

``` bash
user: kschool
password: kschool
```

In the dashboard you can choose in a drop-down the series that you want to know the number of predicted episodes or search for the name directly. We must remember that the dataset is filtered by the initial features and that there are famous series that are not found in it.

In addition, you can check how the predicts with current chapters around 30 are reasonable and that the largest number of the predicted number is lower than the current one due to the negative estimate motivated by the bias of the dataset