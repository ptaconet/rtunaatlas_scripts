
cat("Retrieving RFMOs nominal catch...\n")

include_rfmo<-c(include_IOTC,include_IATTC,include_WCPFC,include_CCSBT,include_ICCAT)

# There are 2 ICCAT datasets for nominal catch: one that provides the stratification by Sampling areas, and one that provides the stratification by Stock areas. For nominal catch, the user decides as input parameter which one he wants to keep.
if (exists("iccat_nominal_catch_spatial_stratification")){
  if (iccat_nominal_catch_spatial_stratification=="sampling_area"){
    iccat_nominal_catch_dataset_permanent_identifier<-"atlantic_ocean_nominal_catch_tunaatlasiccat_level0__bysamplingarea"
  } else if (iccat_nominal_catch_spatial_stratification=="stock_area"){
    iccat_nominal_catch_dataset_permanent_identifier<-"atlantic_ocean_nominal_catch_tunaatlasiccat_level0__bystockarea"
  }
} else { iccat_nominal_catch_dataset_permanent_identifier<-"atlantic_ocean_nominal_catch_tunaatlasiccat_level0__bysamplingarea" }

rfmo<-c("IOTC","IATTC","WCPFC","CCSBT","ICCAT")
nominal_catch_datasets_permanent_identifiers<-c("indian_ocean_nominal_catch_tunaatlasiotc_level0","east_pacific_ocean_nominal_catch_tunaatlasiattc_level0","west_pacific_ocean_nominal_catch_tunaatlaswcpfc_level0","southern_hemisphere_oceans_nominal_catch_tunaatlasccsbt_level0__bygear",iccat_nominal_catch_dataset_permanent_identifier)
nominal_catch_contact_originators<-c("fabio.fiorellato@iotc.org","nvogel@iattc.org","PeterW@spc.int","CMillar@ccsbt.org","carlos.palma@iccat.int")
nominal_catch_datasets_permanent_identifiers_to_keep<-NULL
for (i in 1:length(include_rfmo)){
  if (include_rfmo[i]=="TRUE"){
    nominal_catch_datasets_permanent_identifiers_to_keep<-paste0(nominal_catch_datasets_permanent_identifiers_to_keep,",'",nominal_catch_datasets_permanent_identifiers[i],"'")
    
    # fill metadata elements
    metadata$contact_originator<-paste(metadata$contact_originator,nominal_catch_contact_originators[i],sep=";")
    metadata$lineage<-c(metadata$lineage,paste0("Public domain datasets from ",rfmo[i]," were collated through the RFMO website. Their structure (i.e. column organization and names) was harmonized and they were loaded in the Tuna atlas database."))
    }
}
nominal_catch_datasets_permanent_identifiers_to_keep<-substring(nominal_catch_datasets_permanent_identifiers_to_keep, 2)

rfmo_nominal_catch_metadata<-dbGetQuery(con,paste0("SELECT * from metadata.metadata where persistent_identifier IN (",nominal_catch_datasets_permanent_identifiers_to_keep,") and identifier LIKE '%__",datasets_year_release,"%'"))
nominal_catch<-rtunaatlas::extract_and_merge_multiple_datasets(con,rfmo_nominal_catch_metadata,columns_to_keep=c("source_authority","species","gear","flag","time_start","time_end","geographic_identifier","unit","value"))

# For ICCAT Nominal catch, we need to map flag code list, because flag code list used in nominal catch dataset is different from flag code list used in ICCAT task2; however we have to use the same flag code list for data raising. In other words, we express all ICCAT datasets following ICCAT task2 flag code list.
if (include_ICCAT=="TRUE"){
  # extract mapping
  df_mapping<-rtunaatlas::extract_dataset(con,list_metadata_datasets(con,identifier="codelist_mapping_flag_iccat_from_ncandcas_flag_iccat"))
  df_mapping$source_authority<-"ICCAT"
  
  nominal_catch_iccat<-nominal_catch %>% filter (source_authority=="ICCAT")
  nominal_catch_other_rfmos<-nominal_catch %>% filter (source_authority!="ICCAT")
  
  nominal_catch_iccat<-rtunaatlas::map_codelist(nominal_catch_iccat,df_mapping,"flag")$df 
  
  nominal_catch<-rbind(nominal_catch_other_rfmos,nominal_catch_iccat)
  # fill metadata elements
  metadata$contact_originator<-paste(metadata$contact_originator,"carlos.palma@iccat.int",sep=";")
  metadata$lineage<-c(metadata$lineage,paste0("Public domain datasets from ICCAT were collated (through the RFMO website). Their structure (i.e. column organization and names) was harmonized and they were loaded in the Tuna atlas database."))
  
}

nominal_catch$time_start<-substr(as.character(nominal_catch$time_start), 1, 10)
nominal_catch$time_end<-substr(as.character(nominal_catch$time_end), 1, 10)

cat("Retrieving RFMOs nominal catch OK\n")