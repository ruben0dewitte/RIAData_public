# SETUP -------------------------------------------------------------------

# Load libraries
library(here) #easy file referencing, root is set at project root
library(dplyr)
library(dtplyr) # use data.table syntax with dplyr for large and heavy datasets
library(tidyr)
library(haven) # to import foreign statistical formats (for instance, .dta from stata) into R
library(httr) # to download files where the server requires some more information
library(readr)
library(vroom)

# Download USITC ITPD-E Release 2 (small version) -----------------------------------------

# Download the data to the temp folder
# download.file("https://www.usitc.gov/data/gravity/itpd_e/itpd_e_r02.zip", here("temp","temp.zip")) 
# Download.file does not work because the server requests some additional information to download, use httr instead (see https://stackoverflow.com/questions/71644658/r-cannot-download-a-file-from-the-web)
url <- "https://www.usitc.gov/data/gravity/itpd_e/itpd_e_r02_no_names.zip"
UA <- paste('Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:98.0)',
            'Gecko/20100101 Firefox/98.0')
res <- GET(url, add_headers(`User-Agent` = UA, Connection = 'keep-alive'))
writeBin(res$content, here("temp","temp.zip"))
rm(res,UA,url) #clean up
unzip( here("temp","temp.zip"),exdir=here("temp"))  # unzip your file 

# download the metadata
url <- "https://www.usitc.gov/publications/332/working_papers/itpd_e_r02_usitc_wp.pdf"
UA <- paste('Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:98.0)',
            'Gecko/20100101 Firefox/98.0')
res <- GET(url, add_headers(`User-Agent` = UA, Connection = 'keep-alive'))
writeBin(res$content, here("input","data","usitc_itpd_e_r02_metadata.pdf"))
rm(res,UA,url) #clean up


# Read and prepare the data 
x = vroom(here("temp","ITPD_E_R02_no_names.csv"),col_names = TRUE)
gc()

x = lazy_dt(x) %>%
  mutate(broad_sector = case_when(
    industry_id %in% c(1:28) ~ "Agriculture",
    industry_id %in% c(29:35) ~ "Mining and Energy",
    industry_id %in% c(36:153) ~ "Manufacturing",
    industry_id %in% c(154:170) ~ "Services")) %>%
  mutate(flag_zero = ifelse(flag_zero=="u",1,0)) %>%
  group_by(exporter_iso3,exporter_dynamic_code,importer_iso3,importer_dynamic_code,broad_sector,year) %>%
  summarise(trade = sum(trade), flag_mirror = mean(flag_mirror), flag_zero = mean(flag_zero)) %>%
  ungroup() %>%
  as_tibble()

saveRDS(x,file=here("input","data","usitc_itpd_e_r02.rds"))
gc() # clean up
unlink(here("temp","*")) # remove all files in temp folder


# Download USITC DGD dataset -----------------------------------------

# Download the 2000-2019 data to the temp folder
url <- "https://www.usitc.gov/data/gravity/dgd_docs/release_2.1_2000_2019.zip"
UA <- paste('Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:98.0)',
            'Gecko/20100101 Firefox/98.0')
res <- GET(url, add_headers(`User-Agent` = UA, Connection = 'keep-alive'))
writeBin(res$content, here("temp","temp.zip"))
rm(res,UA,url) #clean up
unzip( here("temp","temp.zip"),exdir=here("temp"))  # unzip your file 
unlink(here("temp","temp.zip")) # remove all files in temp folder

# Download the 1948-1999 data to the temp folder
url <- "https://www.usitc.gov/data/gravity/dgd_docs/release_2.1_1948_1999.zip"
UA <- paste('Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:98.0)',
            'Gecko/20100101 Firefox/98.0')
res <- GET(url, add_headers(`User-Agent` = UA, Connection = 'keep-alive'))
writeBin(res$content, here("temp","temp.zip"))
rm(res,UA,url) #clean up
unzip( here("temp","temp.zip"),exdir=here("temp"))  # unzip your file 
unlink(here("temp","temp.zip")) # remove the zip file from the temp folder


# download the metadata
url <- "https://www.usitc.gov/data/gravity/gravity_dataset_documentation_version_2_1.pdf"
UA <- paste('Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:98.0)',
            'Gecko/20100101 Firefox/98.0')
res <- GET(url, add_headers(`User-Agent` = UA, Connection = 'keep-alive'))
writeBin(res$content, here("input","data","usitc_dgd_metadata.pdf"))
rm(res,UA,url) #clean up


# Loop over and append source files across all years
files = list.files(here("temp"),full.names = TRUE) 
chunks_out = lapply(files,function(f){
  return(vroom(f))
})
x = do.call(rbind.data.frame,chunks_out)
rm(chunks_out)

saveRDS(x,file=here("input","data","usitc_dgd.rds"))
rm(x,files) #clean up
gc() #clean up
unlink(here("temp","*")) # remove all files in temp folder

# Download Justine Miller's RIA database -----------------------------------------

# Download the combined data
# Data is in a onedrive folder that is difficult to access through R, so we will download it by hand and then load it into R
# https://onlineunu-my.sharepoint.com/:t:/r/personal/jmiller_cris_unu_edu/Documents/RIA%20Database/Combined%20Data.txt?csf=1&web=1&e=PR2GKB
# save it into the temp as temp.txt folder and then load it into R

# Download the metadata
download.file("https://cris.unu.edu/sites/cris.unu.edu/files/UNU-CRIS_Working-Paper_Miller_and_Standaert_23.02.pdf",here("input","data","jm_ria_metadata.pdf"), mode="wb")

# Load the data and write it to the input folder in RDS and in excel format
x = vroom(here("temp","temp.txt"),col_names = TRUE)
saveRDS(x,file=here("input","data","jm_ria_combined.rds"))
write_csv(x, here("input","data","jm_ria_combined.csv"))
gc() #clean up
unlink(here("temp","*")) # remove all files in temp folder
