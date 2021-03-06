######################################################################
##### 52North WPS annotations ##########
######################################################################
# wps.des: id = west_pacific_ocean_effort_5deg_1m_bb_tunaatlaswcpfc_level0, title = Harmonize data structure of WCPFC Pole-and-line effort datasets, abstract = Harmonize the structure of WCPFC catch-and-effort datasets: 'Pole-and-line' (pid of output file = west_pacific_ocean_effort_5deg_1m_bb_tunaatlaswcpfc_level0). The only mandatory field is the first one. The metadata must be filled-in only if the dataset will be loaded in the Tuna atlas database. ;
# wps.in: id = path_to_raw_dataset, type = String, title = Path to the input dataset to harmonize. Input file must be structured as follow: https://goo.gl/niIjsk, value = "https://goo.gl/niIjsk";
# wps.in: id = path_to_metadata_file, type = String, title = NULL or path to the csv of metadata. The template file can be found here: https://raw.githubusercontent.com/ptaconet/rtunaatlas_scripts/master/sardara_world/transform_trfmos_data_structure/metadata_source_datasets_to_database/metadata_source_datasets_to_database_template.csv . If NULL, no metadata will be outputted., value = "NULL";
# wps.out: id = zip_namefile, type = text/zip, title = Dataset with structure harmonized + File of metadata (for integration within the Tuna Atlas database) + File of code lists (for integration within the Tuna Atlas database) ; 

#' This script works with any dataset that has the first 5 columns named and ordered as follow: {YY|MM|LAT5|LON5|DAYS} followed by a list of columns specifing the species codes with "_N" for catches expressed in number and "_T" for catches expressed in tons
#' 
#' @author Paul Taconet, IRD \email{paul.taconet@ird.fr}
#' 
#' @keywords Western and Central Pacific Fisheries Commission WCPFC tuna RFMO Sardara Global database on tuna fishieries
#'
#' @seealso \code{\link{convertDSD_wcpfc_ce_Driftnet}} to convert WCPFC task 2 Drifnet data structure, \code{\link{convertDSD_wcpfc_ce_Longline}} to convert WCPFC task 2 Longline data structure, \code{\link{convertDSD_wcpfc_ce_Pole_and_line}} to convert WCPFC task 2 Pole-and-line data structure, \code{\link{convertDSD_wcpfc_ce_PurseSeine}} to convert WCPFC task 2 Purse seine data structure, \code{\link{convertDSD_wcpfc_nc}} to convert WCPFC task 1 data structure  


if(!require(rtunaatlas)){
  if(!require(devtools)){
    install.packages("devtools")
  }
  require(devtools)
  install_github("ptaconet/rtunaatlas")
}
if(!require(foreign)){
  install.packages("foreign")
}

require(rtunaatlas)
require(foreign)

wd<-getwd()
download.file(path_to_raw_dataset,destfile=paste(wd,"/dbf_file.DBF",sep=""), method='auto', quiet = FALSE, mode = "w",cacheOK = TRUE,extra = getOption("download.file.extra"))
path_to_raw_dataset=paste(wd,"/dbf_file.DBF",sep="")


  # Input data sample:
  # YY MM LAT5 LON5 DAYS SKJ_C YFT_C OTH_C
  # 1950  1  30N 135E    0     0     0     0
  # 1950  1  30N 140E    0     0     0     0
  # 1950  1  35N 140E    0     0     0     0
  # 1950  1  40N 140E    0     0     0     0
  # 1950  1  40N 145E    0     0     0     0
  # 1950  2  30N 135E    0     0     0     0
  
  # Effort: pivot data sample:
  # YY MM LAT5 LON5 Effort EffortUnits School Gear
  # 1950  1  30N 135E      0        DAYS    ALL    P
  # 1950  1  30N 140E      0        DAYS    ALL    P
  # 1950  1  35N 140E      0        DAYS    ALL    P
  # 1950  1  40N 140E      0        DAYS    ALL    P
  # 1950  1  40N 145E      0        DAYS    ALL    P
  # 1950  2  30N 135E      0        DAYS    ALL    P
  
  # Effort: final data sample:
  # Flag Gear time_start   time_end AreaName School EffortUnits Effort
  #  ALL    P 1970-03-01 1970-04-01  6200150    ALL        DAYS     82
  #  ALL    P 1970-04-01 1970-05-01  6200150    ALL        DAYS     74
  #  ALL    P 1970-05-01 1970-06-01  6200150    ALL        DAYS     82
  #  ALL    P 1970-06-01 1970-07-01  6200150    ALL        DAYS     81
  #  ALL    P 1970-07-01 1970-08-01  6200150    ALL        DAYS     75
  #  ALL    P 1970-12-01 1971-01-01  6200150    ALL        DAYS     56
  
  
##Efforts

# Reach the efforts pivot DSD using a function in WCPFC_functions.R
efforts_pivot_WCPFC<-FUN_efforts_WCPFC_CE (path_to_raw_dataset)
efforts_pivot_WCPFC$Gear<-"P"

# Reach the efforts harmonized DSD using a function in ICCAT_functions.R
colToKeep_efforts <- c("Flag","Gear","time_start","time_end","AreaName","School","EffortUnits","Effort")
efforts<-WCPFC_CE_efforts_pivotDSD_to_harmonizedDSD(efforts_pivot_WCPFC,colToKeep_efforts)

colnames(efforts)<-c("flag","gear","time_start","time_end","geographic_identifier","schooltype","unit","value")
efforts$source_authority<-"WCPFC"
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

