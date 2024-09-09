### Data load ###
source("mGPS.R")
library(caret)
setwd( rprojroot::find_rstudio_root_file())
environmental <- read.csv(file="Data/Soil/Dataset_01_22_2018_enviro.csv",header=TRUE)
taxa <- read.csv(file="Data/Soil/Dataset_01_22_2018_taxa.csv",header=TRUE)
SoilData <- merge(environmental,taxa,by.x="ID_Environmental",by.y="ID_Environmental")


### Data clean ###
SoilData$country <- maps::map.where(database="world", SoilData$Longitude, SoilData$Latitude)
SoilData[234:237,]$country <- "Chile"
SoilData[c(2,6,9,15,22,67,34),]$country <- "USA"

SoilData$country <- factor(make.names(SoilData$country))

#rename columns
colnames(SoilData)[3:5] <- c("longitude","latitude","continent")

#Remove countries with insufficient samples
keep <- levels(SoilData$country)[table(SoilData$country) > 2]
SoilData <- droplevels(SoilData[SoilData$country%in% keep, ])

#concert read data to relative abundance.
for (i in 28:538){
  SoilData[,i] <- (SoilData[,i]/10000)
}

### Get GIT's ###
featureElim <- species_select(x = SoilData[,c(28:538)],y = SoilData$country,remove_correlated = F,subsets = c(20,30,50,100,200),cores = 8)
optVars <- featureElim$optVariables

v <- varImp(featureElim$fit, type = 1, scale = F)
v[,"taxa"] <- row.names(v)
v <- v[order(v$Overall,decreasing = T),]
dir.create('Soil/Outputs', showWarnings = FALSE)
write.csv(v, file = "Soil/Outputs/soil_git.csv")


### Make predictions (without SMOTE) ###
coastlines <- cbind("x"  = maps::SpatialLines2map(rworldmap::coastsCoarse)$x ,"y" =maps::SpatialLines2map(rworldmap::coastsCoarse)$y)
coastlines <- coastlines[complete.cases(coastlines),]
coastlines <- coastlines[coastlines[,1] < 180 ,]
#5 fold cross validation
set.seed(18)
trainFolds <-  createFolds(SoilData$country, k = 5, returnTrain = T)

GeoPredsSoil <- list()
registerDoParallel(7) 

for (i in 1:5){
  
  train <- SoilData[trainFolds[[i]],]
  test <- SoilData[-trainFolds[[i]],]
  
  testPreds <- mGPS(training = train, testing = test, classTarget = "country",variables = optVars,nthread = 8,hierarchy = c('continent','country','latitude','longitude'), coast=coastlines)
  GeoPredsSoil[[i]] <- testPreds
  
}

add_preds <- list()
for (i in 1:5){
  
  add_preds[[i]] <- cbind(SoilData[-trainFolds[[i]],] , 
                          "countryPred"= GeoPredsSoil[[i]][[1]], 
                          "latPred" = GeoPredsSoil[[i]][[2]], 
                          "longPred" = GeoPredsSoil[[i]][[3]] )
}

SoilDataPreds <- rbind.fill(add_preds)
write.csv(SoilDataPreds,"Soil/Outputs/soil_results.csv")



### Make predictions (with SMOTE) ###
library(smotefamily)
library(dplyr)

SoilData$country <- as.character(SoilData$country)
SoilData[SoilData$latitude > 60,'country'] <- 'USA_AK'

SoilData[SoilData$longitude < -150,'country'] <- 'USA_HI'

SoilData_smote <- SoilData[,c(optVars,'latitude','longitude','country','continent')]
SoilData_smote$original <- 1
SoilData_smote$country <- factor(SoilData_smote$country)

for (c in levels(SoilData_smote$country)){
  continent_c <- unique(SoilData_smote[SoilData_smote$country == c,'continent'])
  for (j in 1:nrow(SoilData_smote)){
    SoilData_smote$target[j] <- ifelse(SoilData_smote$country[j] == c,1,0)
  }

  # oversampling by SMOTE for countries/sites with less than 4 samples
  c_samp <- sum(SoilData_smote$country == c)
    if (c_samp < 4){
      k = c_samp-1
    }else{
      k = 3
    }
    
    dup_size = round(10/c_samp)
    
    smote_result.T2 = SMOTE(SoilData_smote[,c(optVars,'latitude','longitude')],target = SoilData_smote$target, K = k, dup_size = dup_size)

    TS2<- smote_result.T2[["syn_data"]]
    TS2$country <- c
    TS2$continent <- continent_c
    TS2$original <- 0
    TS2_sample <- TS2[sample(nrow(TS2),(10-c_samp)),]
    
    SoilData_smote <- rbind(SoilData_smote[,1:(ncol(SoilData_smote)-1)],TS2_sample[,colnames(SoilData_smote)[1:(ncol(SoilData_smote)-1)]])
}

table(SoilData_smote$country,SoilData_smote$original)

set.seed(18)
trainFolds <-  createFolds(SoilData_smote$country, k = 5, returnTrain = T)
GeoPredsSoil <- list()

for (i in 1:5){
  
  train <- SoilData_smote[trainFolds[[i]],]
  test <- SoilData_smote[-trainFolds[[i]],]
  
  testPreds <- mGPS(training = train, testing = test, classTarget = "country",variables = optVars,nthread = 8,hierarchy = c('continent','country','latitude','longitude'), coast=coastlines)
  GeoPredsSoil[[i]] <- testPreds
}

add_preds <- list()
for (i in 1:5){
  
  add_preds[[i]] <- cbind(SoilData_smote[-trainFolds[[i]],] , 
                          "countryPred"= GeoPredsSoil[[i]][[1]], 
                          "latPred" = GeoPredsSoil[[i]][[2]], 
                          "longPred" = GeoPredsSoil[[i]][[3]])
}

SoilDataPreds_smote <- rbind.fill(add_preds)
write.csv(SoilDataPreds_smote,"soil_results_SMOTE.csv")
# original samples are labelled as (SoilDataPreds_smote$original == 1)
