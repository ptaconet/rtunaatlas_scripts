######################################################################
##### 52North WPS annotations ##########
######################################################################
# wps.des: id = indian_ocean_effort_tunaatlasiotc_level0__surface, title = Harmonize data structure of IOTC Surface effort datasets, abstract = Harmonize the structure of IOTC catch-and-effort datasets: 'Surface' (pid of output file = indian_ocean_effort_tunaatlasiotc_level0__surface). The only mandatory field is the first one. The metadata must be filled-in only if the dataset will be loaded in the Tuna atlas database. ;
# wps.in: id = path_to_raw_dataset, type = String, title = Path to the input dataset to harmonize. Input file must be structured as follow: https://goo.gl/bSsmaK, value = "https://goo.gl/bSsmaK";
# wps.in: id = path_to_metadata_file, type = String, title = NULL or path to the csv of metadata. The template file can be found here: https://raw.githubusercontent.com/ptaconet/rtunaatlas_scripts/master/sardara_world/transform_trfmos_data_structure/metadata_source_datasets_to_database/metadata_source_datasets_to_database_template.csv . If NULL, no metadata will be outputted., value = "NULL";
# wps.out: id = zip_namefile, type = text/zip, title = Dataset with structure harmonized + File of metadata (for integration within the Tuna Atlas database) + File of code lists (for integration within the Tuna Atlas database) ; 

#' This script works with any dataset that has the first 12 columns named and ordered as follow: {Fleet|Gear|Year|MonthStart|MonthEnd|iGrid|Grid|Effort|EffortUnits|QualityCode|Source|CatchUnits} followed by a list of columns specifing the species codes with ".FS" for catches on free schools and ".LS" for catches for catches on log schools and ".UNCL" for catches on unclassied schools
#'
#' @author Paul Taconet, IRD \email{paul.taconet@ird.fr}
#' 
#' @keywords Indian Ocean Tuna Commission IOTC tuna RFMO Sardara Global database on tuna fishieries
#'
#' @seealso \code{\link{convertDSD_iotc_ce_LonglineCoastal}} to convert IOTC task 2 CECoastal and CELongline data structure, \code{\link{convertDSD_iotc_nc}} to convert IOTC nominal catch data structure

if(!require(rtunaatlas)){
  if(!require(devtools)){
    install.packages("devtools")
  }
  require(devtools)
  install_github("ptaconet/rtunaatlas")
}
if(!require(data.table)){
  install.packages("data.table")
}

require(rtunaatlas)
require(data.table)


# Input data sample:
# Fleet Gear Year MonthStart MonthEnd      iGrid    Grid Effort EffortUnits QualityCode Source CatchUnits YFT.FS YFT.LS YFT.UNCL BET.FS BET.LS BET.UNCL SKJ.FS SKJ.LS SKJ.UNCL ALB.FS ALB.LS ALB.UNCL SBF.FS SBF.LS
# EUESP     PS 1996          9        9 5100043    5100043   36.2      FHOURS           3     LO         MT     NA  13.36       NA     NA   5.58       NA     NA  20.26       NA     NA     NA       NA     NA     NA
# EUESP     PS 2004          8        8 5100043    5100043   12.1      FHOURS           3     LO         MT     NA   8.74       NA     NA   2.66       NA     NA  32.97       NA     NA     NA       NA     NA     NA
# NEIPS     PS 1992         10       10 5100043    5100043   12.1      FHOURS           3   RFRI         MT     NA   4.53       NA     NA   3.00       NA     NA  37.47       NA     NA     NA       NA     NA     NA
# EUESP     PS 1991          8        8 5100044    5100044   12.1      FHOURS           3     LO         MT  76.26     NA       NA   9.95     NA       NA  68.14     NA       NA     NA     NA       NA     NA     NA
# EUESP     PS 1995          6        6 5100044    5100044   12.1      FHOURS           3     LO         MT     NA   0.79       NA     NA   0.68       NA     NA   4.93       NA     NA     NA       NA     NA     NA
# EUESP     PS 1995          9        9 5100044    5100044   12.1      FHOURS           3     LO                NA     NA       NA     NA     NA       NA     NA     NA       NA     NA     NA       NA     NA     NA
# SBF.UNCL LOT.FS LOT.LS LOT.UNCL FRZ.FS FRZ.LS FRZ.UNCL KAW.FS KAW.LS KAW.UNCL COM.FS COM.LS COM.UNCL TUX.FS TUX.LS TUX.UNCL FAL.FS FAL.LS FAL.UNCL OCS.FS OCS.LS OCS.UNCL SKH.FS SKH.LS SKH.UNCL NTAD.FS NTAD.LS
#       NA     NA     NA       NA     NA     NA       NA     NA     NA       NA     NA     NA       NA     NA     NA       NA     NA     NA       NA     NA     NA       NA     NA     NA       NA      NA      NA
#       NA     NA     NA       NA     NA     NA       NA     NA     NA       NA     NA     NA       NA     NA     NA       NA     NA     NA       NA     NA     NA       NA     NA     NA       NA      NA      NA
#       NA     NA     NA       NA     NA     NA       NA     NA     NA       NA     NA     NA       NA     NA     NA       NA     NA     NA       NA     NA     NA       NA     NA     NA       NA      NA      NA
#       NA     NA     NA       NA     NA     NA       NA     NA     NA       NA     NA     NA       NA     NA     NA       NA     NA     NA       NA     NA     NA       NA     NA     NA       NA      NA      NA
#       NA     NA     NA       NA     NA     NA       NA     NA     NA       NA     NA     NA       NA     NA     NA       NA     NA     NA       NA     NA     NA       NA     NA     NA       NA      NA      NA
#       NA     NA     NA       NA     NA     NA       NA     NA     NA       NA     NA     NA       NA     NA     NA       NA     NA     NA       NA     NA     NA       NA     NA     NA       NA      NA      NA
# NTAD.UNCL
#        NA
#        NA
#        NA
#        NA
#        NA
#        NA


# Effort: final data sample:
# Flag Gear time_start   time_end AreaName School EffortUnits Effort
#  AUS   BB 1992-01-01 1992-02-01  6230130    IND       HRSRH    403
#  AUS   BB 1992-02-01 1992-03-01  6230130    IND       HRSRH    366
#  AUS   BB 1992-02-01 1992-03-01  6230135    IND       HRSRH     30
#  AUS   BB 1992-02-01 1992-03-01  6235115    IND       HRSRH     23
#  AUS   BB 1992-03-01 1992-04-01  6230130    IND       HRSRH    221
#  AUS   BB 1992-03-01 1992-04-01  6235130    IND       HRSRH     68

##Efforts

# Reach the efforts pivot DSD using a function in ICCAT_functions.R
efforts_pivot_IOTC<-FUN_efforts_IOTC_CE(path_to_raw_dataset,12)
efforts_pivot_IOTC$CatchUnits<-NULL
efforts_pivot_IOTC$Source<-NULL

# Reach the efforts harmonized DSD using a function in ICCAT_functions.R
colToKeep_efforts <- c("Flag","Gear","time_start","time_end","AreaName","School","EffortUnits","Effort")
efforts<-IOTC_CE_effort_pivotDSD_to_harmonizedDSD(efforts_pivot_IOTC,colToKeep_efforts)


colnames(efforts)<-c("flag","gear","time_start","time_end","geographic_identifier","schooltype","unit","value")
efforts$source_authority<-"IOTC"
dataset<-efforts

### Compute metadata
#if (path_to_metadata_file!="NULL"){
#  source("https://raw.githubusercontent.com/ptaconet/rtunaatlas_scripts/master/tunaatlas_world/transform/compute_metadata.R")
#} else {
#  df_metadata<-NULL
#  df_codelists<-NULL
#}

## To check the outputs:
# str(dataset)
# str(df_metadata)
# str(df_codelists)

