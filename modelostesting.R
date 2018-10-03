install.packages("drat", repos="https://cran.rstudio.com")
drat:::addRepo("dmlc")
install.packages("xgboost", repos="http://dmlc.ml/drat/", type = "source")

install.packages("xgboost")

require(xgboost)

data(b2.train, package='xgboost')
data(b2.test, package='xgboost')
train <- b2.train
test <- b2.test

train <- b2[1:97095, ]
test <- b2[97096:194191, ]

dim(train$originalTitle.x)
dim(test)

bstSparse <- xgboost(data = train, label = train$endYear.x, max_depth = 2, eta = 1, nthread = 2, nrounds = 2, objective = "binary:logistic")