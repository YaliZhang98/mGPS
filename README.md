# mGPS
**A microbiome fine-scale biogeography tool maps the transfer of antimicrobial resistance genes**

*Yali Zhang, Leo McCarthy, S. Emil Ruff, and Eran Elhaik*


This repository contains all code used for data cleaning, modelling and results of the Microbiome Geographic Population Structure (mGPS). mGPS is a biogeographical tool that employs multi-output model for hierarchical location predictions (i.e., continent/country/city) and location coordinates (latitude + longitude) using bacterial abundance data as input.  
For the mGPS interface - the freely available public tool with a friendly user interface developed with the shiny package in R (version 4.0.3), please visit: [mGPS_interface](https://github.com/YaliZhang98/mGPS_interface)

## Data

All data and geographical cooridnates needed to reproduce the analyses are in the `Data.zip.`Unzip the file before running the analyses. 
Description of folders: 

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

The interface of mGPS and its detailed description can be found inthe  folder `mGPS_interface`。

The script `mGPS.r`, has two parts: 

* `species_select()` - function using random forest for selecting optimal Geographically Informative Taxa (GIT) that used to built the mGPS prediction model:
  - `x` -- prediction variables
  - `y` -- target variable 
  - `remove_correlated` -- should correlated predictor variables be removed (>98% correlation). 
  - `subsets` -- The variable subset sizes to try 
  - `cores` -- number of cores to utilize 

Example
```R
species_select(x = metasub_data[, taxa],
               y = metasub_data$city,
               remove_correlated = F,
               c(50,100,200,300,500),
               cores = 8)
```

* `mGPS()` - a machine-learning-based function that utilizes microbial relative sequence abundances to yield a fine-scale source site for microorganisms
  * `training` -- Taxa data of samples used to train the model. 
  * `testing` -- taxa abundance data of samples for which predictions are to be generated  
  * `classTarget` -- granularity for geographic class prediction either country,city or transit station etc. 
  * `variables` -- a vector containing names of species or taxa to be used as variables for prediction. This needs defining even if all taxa/species in the training data frame are to be used, so that geographic information are not mistakenly used as predictors. 
  * `hierarchy` -- The geographic hierarchy for predictions i.e. continent –> city -> latitude -> longitude
  * `nthread` -- number of threads to utilize 
  * `coast` -- (optional) data.frame of co-ordinates for predictions to be bound by


If no test set is given then a trained model is returned that takes a test set as the input. 

For this implementation of mGPS, hyperparameter tuning is carried out at every level of the chained model using a small grid search applied to the training set provided, the same validation fold splits are used at every level. Predictions are then generated using the provided test data set . 

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

Each dataset used in the analysis has its own folder. Each dataset has a `{dataset}_make.R` file for finding Geographically Informative Taxa and generating predictions using `mGPS` and cross validation the results are saved to the corresponding `outputs` folder. There is also a `{dataset}_plots.Rmd` file for each dataset in the analysis which when knit produces plots and tables found in the manuscript.

Each `make` and `plots` file for the corresponding datasets should be run in turn to reproduce the full analysis. After cloning the repo the `plots` files can be run without first running the corresponding `make` file as the predictions are stored in this repo. 

AMR analysis part is described in the `Metasub/Scripts/AMR` part.

## Dependencies

The required packages for mGPS  can be found in `packages.r`. The packages used for mGPS interface an be found in `mGPS_interface/packages.r`
