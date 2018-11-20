# Prediction Finalization Series TV
### Master Data Science - K SCHOOL
### Author: Roberto Marcos Aparicio

[**HOW WRONG ARE MY PREDICTIONS?**](http://superset-1998162619.eu-west-1.elb.amazonaws.com/r/5)

<kbd><img title="Dashboard" src="https://github.com/RobertoMarcos/TFM-PredictionFinalizationTVSeries/blob/master/data/Images/dashboard_wrongs.png"></kbd><br/>

The dashboard is hosted on AWS and the front-end on Apache Superset. The url and public access is as follows:
  
http://superset-1998162619.eu-west-1.elb.amazonaws.com/r/5

``` bash
user: kschool
password: kschool
```

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
```
## Information

If you want more information about the data process, follow the [next document](https://github.com/RobertoMarcos/TFM-PredictionFinalizationTVSeries/blob/master/project_report.md).
