
cat("Converting units of georef_dataset...\n")

cat("Reading the conversion factors dataset\n")

df_conversion_factor=read.csv(unit_conversion_csv_conversion_factor_url,stringsAsFactors = F,colClasses="character")

## If we have not mapped the code lists (i.e. if mapping_map_code_lists==FALSE), we need to map the source gear coding system with ISSCFG coding system. In fact, the conversion factors dataset is expressed with ISSCFG coding system for gears, while the primary tRFMOs datasets are expressed with their own gear coding system.
if (mapping_map_code_lists==FALSE){
  source_authority<-c("IOTC","ICCAT","IATTC","WCPFC","CCSBT")
  db_mapping_dataset_name<-c("codelist_mapping_gear_iotc_isscfg_revision_1","codelist_mapping_gear_iccat_isscfg_revision_1","codelist_mapping_gear_iattc_isscfg_revision_1","codelist_mapping_gear_wcpfc_isscfg_revision_1","codelist_mapping_gear_ccsbt_isscfg_revision_1")
  mapping_dataset<-data.frame(source_authority,db_mapping_dataset_name)
  df_mapping_final_this_dimension<-NULL
  for (j in 1:nrow(mapping_dataset)){ 
    df_mapping<-rtunaatlas::extract_dataset(con,list_metadata_datasets(con,dataset_name=mapping_dataset$db_mapping_dataset_name[j]))  # Extract the code list mapping dataset from the DB
    df_mapping$source_authority<-as.character(mapping_dataset$source_authority[j])  # Add the dimension "source_authority" to the mapping dataset. That dimension is not included in the code list mapping datasets. However, it is necessary to map the code list.
    df_mapping_final_this_dimension<-rbind(df_mapping_final_this_dimension,df_mapping)
  }
  #georef_dataset with source coding system for gears mapped with isscfg codes:
  georef_dataset<-rtunaatlas::map_codelist(georef_dataset,df_mapping_final_this_dimension,"gear",TRUE)$df
  
  # change column names before the conversion of units
  colnames(georef_dataset)[colnames(georef_dataset) == 'gear'] <- 'gear_original_codes'
  colnames(georef_dataset)[colnames(georef_dataset) == 'gear_mapping'] <- 'gear'
  
}

## Convert MTNO to MT and remove NOMT (we do not keep the data that were expressed in number with corresponding value in weight)
georef_dataset$unit[which(georef_dataset$unit == "MTNO")]<-"MT"
georef_dataset<-georef_dataset[!(georef_dataset$unit=="NOMT"),]

georef_dataset<-rtunaatlas::convert_units(con = con,
                                 df_input = georef_dataset,
                                 df_conversion_factor = df_conversion_factor,
                                 codelist_geoidentifiers_df_input = "areas_tuna_rfmos_task2",
                                 codelist_geoidentifiers_conversion_factors = unit_conversion_codelist_geoidentifiers_conversion_factors
)

# to get stats on the process (useful for metadata)
# georef_dataset$stats

georef_dataset<-georef_dataset$df

if (mapping_map_code_lists==FALSE){
  # resetting gear coding system to primary gear coding system
  georef_dataset$gear<-NULL
  colnames(georef_dataset)[colnames(georef_dataset) == 'gear_original_codes'] <- 'gear'
}

cat("Converting units of georef_dataset OK\n")