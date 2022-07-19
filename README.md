# mGPS
**Microbiome biodiversity typifies fine-scale biogeography using a machine learning model**

*Leo McCarthy, Yali Zhang and Eran Elhaik*


This repository contains all code used for data cleaning, modelling and results contained in the Microbiome Geographic Population Structure (mGPS) analysis. Outlining the method used for developing our multi-output model for hierarchical location predictions i.e. (continent/country/city) and location co-ordinates(latitude + longitude) using bacterial abundance data as input. 

## Data

All data and geodata required to reproduce the analysis is contained within the `Data.zip`  and needs to be unzipped before running the analysis. 

- Metasub

  - `complete_metadata.csv` - MetaSUB environmental and geo data
  - `metasub_taxa_abundance.csv` - MetaSUB taxa abundance data
  - `MetaSUB City Metadata - Sheet1 new.csv` - MetaSUB city information data
  - `After_process_megares_amr_class_rpkmg.csv` - MetaSUB AMR data
- Soil

  - `Dataset_01_22_2018_enviro.csv` - Soil origin metadata

  - `Dataset_01_22_2018_taxa.csv` - Soil OTU taxa read data
- Marine

  - `marine_taxa.csv` - Marine taxa and metadata
- Geo: Geodata required for produce the analysis and figures



## Usage 

The interface of mGPS and its detailed description can be found in folder `mGPS_interface`。

In `mGPS.r`, there are two parts of scripts: 

* `species_select()` - function using random forest for selecting optimal Geographically Informative Taxa (GIT) that used to built the mGPS prediction model:
  - `x` -- prediction variables
  - `y` -- target variable 
  - `remove_correlated` -- should correlated predictor variables be removed (>98% correlation). 
  - `subsets` -- The variable subset sizes to try 
  - `cores` -- number of cores to utilize 
* `mGPS()` - a machine-learning-based function that utilizes microbial relative sequence abundances to yield a fine-scale source site for microorganisms
  * `training` -- Taxa data of samples used to train the model. 
  * `testing` -- taxa abundance data of samples for which predictions are to be generated  
  * `classTarget` -- granularity for geographic class prediction either country,city or transit station etc. 
  * `variables` -- a vector containing names of species or taxa to be used as variables for prediction. This needs defining even if all taxa/species in the training data frame are to be used, so that geographic information are not mistakenly used as predictors. 
  * `hierarchy` -- The geographic hierarchy for predictions i.e. continent –> city -> latitude -> longitude
  * `nthread` -- number of threads to utilize 
  * `coast` -- (optional) data.frame of co-ordinates for predictions to be bound by


If no test set is given then a trained model is returned that takes a test set as the input. 

For this implementation of mGPS, hyperparameter tuning is carried out at every level of the chained model using a small grid search applied to the training set provided, the same validation fold splits are used at every level. Predictions are then generated using the test data set provided. 

Example
```R
mGPS(training = train, 
     testing = test, 
     classTarget = "city",
     variables = optVars,
     nthread = 8,
     hierarchy = c('continent','city','latitude','longitude'), 
     coast=coastlines)
```

## Results and figures

Each data set used in the analysis has its own folder here. Each dataset has a `{dataset}_make.R` file for finding Geographically Informative Taxa and generating predictions using `mGPS` and cross validation the results are saved to the corresponding `outputs` folder. There is also a `{dataset}_plots.Rmd` file for each dataset in the analysis which when knit produces plots and tables found in the manuscript.

Each `make` and `plots` file for the corresponding datasets should be run in turn to reproduce the full analysis. After cloning the repo the `plots` files can be run without first running the corresponding `make` file as the predictions are stored in this repo. 

AMR analysis part is described in the `Metasub/Scripts/AMR` part.

## Dependencies

Required packages for mGPS algorithm can be found in `packages.r`. The packages used for mGPS interface an be found in `mGPS_interface/packages.r`
