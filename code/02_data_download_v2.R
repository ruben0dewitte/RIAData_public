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

# Download USITC ITPD-E Release 3 (small version) -----------------------------------------

# Download the data to the temp folder
# download.file("https://www.usitc.gov/data/gravity/itpd_e/r03/ITPDE_R03.zip", here("temp","temp.zip")) 
# Download.file does not work because the server requests some additional information to download, use httr instead (see https://stackoverflow.com/questions/71644658/r-cannot-download-a-file-from-the-web)
url <- "https://www.usitc.gov/data/gravity/itpd_e/r03/ITPDE_R03_no_names.zip"
download.file(url, destfile = here("temp","temp.zip"), mode = "wb", method = "libcurl",options = options(timeout = max(300, getOption("timeout"))))
unzip( here("temp","temp.zip"),exdir=here("temp"))  # unzip your file 

# download the metadata
url <- "https://www.usitc.gov/publications/332/working_papers/itpd_e_r03.pdf"
UA <- paste('Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:98.0)',
            'Gecko/20100101 Firefox/98.0')
res <- GET(url, add_headers(`User-Agent` = UA, Connection = 'keep-alive'))
writeBin(res$content, here("input","data","usitc_itpd_e_r03_metadata.pdf"))
rm(res,UA,url) #clean up


# Read and prepare the data 
x = vroom(here("temp","ITPDE_R03_no_names.csv"),col_names = TRUE)
gc()

x = lazy_dt(x) %>%
  mutate(flag_zero = ifelse(flag_zero=="u",1,0)) %>%
  group_by(exporter_iso3,exporter_iso3_dynamic,importer_iso3,importer_iso3_dynamic,broad_sector,year) %>%
  summarise(trade = sum(trade), flag_mirror = mean(flag_mirror), flag_zero = mean(flag_zero)) %>%
  ungroup() %>%
  as_tibble()

saveRDS(x,file=here("input","data","ITPDE_R03.rds"))
gc() # clean up
unlink(here("temp","*")) # remove all files in temp folder


# Download USITC DGD dataset -----------------------------------------

# Download the 2000-2022 data to the temp folder
url <- "https://www.usitc.gov/data/gravity/dgd_docs/release_2.1_2000_2019.zip"
download.file(url, destfile = here("temp","temp.zip"), mode = "wb", method = "libcurl",options = options(timeout = max(300, getOption("timeout"))))
unzip( here("temp","temp.zip"),exdir=here("temp"))  # unzip your file 
unlink(here("temp","temp.zip")) # remove all files in temp folder

# Download the 1948-1999 data to the temp folder
url <- "https://www.usitc.gov/data/gravity/dgd_docs/release_2.1_1948_1999.zip"
download.file(url, destfile = here("temp","temp.zip"), mode = "wb", method = "libcurl",options = options(timeout = max(300, getOption("timeout"))))
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
