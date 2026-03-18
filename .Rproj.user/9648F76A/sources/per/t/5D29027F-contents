# SETUP -------------------------------------------------------------------

# Load libraries
library(here) #easy file referencing, root is set at project root
library(dplyr)
library(tidyr)



# Load data ---------------------------------------------------------------

x = readRDS(here("input","data","usitc_itpd_e_r02.rds"))
y = readRDS(here("input","data","usitc_dgd.rds"))

# Aggregate trade data to the country level  (skip this step for industry-level estimations) ------------------------------------------------------

# # Available years per sector in ITPD_E_r02
# # Services only available from 2000 onwards, manufacturing and mining\&energy from 1988 onwards
# x %>% 
#   select(year, broad_sector) %>% 
#   distinct() %>% 
#   arrange(broad_sector, year) %>% 
#   group_by(broad_sector) %>% 
#   summarise(min=min(year), max=max(year))

x = x %>%
  filter(broad_sector != "Services") %>% # Exclude services as only available from 2000 onwards
  filter(year>=1988) %>% # Limit years to 1988 onwards
  group_by(exporter_iso3,exporter_dynamic_code,importer_iso3,importer_dynamic_code,year) %>%
  summarise(trade = sum(trade), flag_mirror = mean(flag_mirror), flag_zero = mean(flag_zero)) %>%
  ungroup() 


# Merge USITC itpd_e and dgd ---------------------------------------------

# Sum to calculate total trade

x = left_join(x,y,by=c("year", 
                       "exporter_dynamic_code" = "dynamic_code_o",
                       "importer_dynamic_code" = "dynamic_code_d")) 

rm(y)

