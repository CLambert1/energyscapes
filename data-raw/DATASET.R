library(tidyverse)
### 1 - Retrieve original data -------------------------------------------------
maps_dir <- "~/ECOSCOPE/ANALYSES/0_Maps_formatting"
func_dir <- "~/ECOSCOPE/ANALYSES/4_EnergyScapes"
work_dir <- "~/ECOSCOPE/ANALYSES/4_EnergyScapes/GRAGRI"

### 1 - Predator maps
# GRAGRI_raw <- rast(paste0(maps_dir, "/ASI_pred_GRAGRI.tif"))
sp_table <- read.table("~/ECOSCOPE/ANALYSES/0_Maps_formatting/Predator_table.csv", sep = ";", dec = ".", h = T)

species_abundance <- data.frame(x = sp_table$x, y = sp_table$y, mean = sp_table$TURTRU_Mean, sd = sp_table$TURTRU_sd)
map_coords <- species_abundance[,c(1:2)]

### 3 - Temp maps
sst_mean <- read.table("~/ECOSCOPE/DATA_oceano/ASI_2018/Data/Seasonal_mean_environmental_conditions_ASI_resolution.csv", sep = ";", dec = ".", h = T)
sst_sd <- read.table("~/ECOSCOPE/DATA_oceano/ASI_2018/Data/Seasonal_sd_environmental_conditions_ASI_resolution.csv", sep = ";", dec = ".", h = T)

sst <- data.frame(x = sst_mean$x, y = sst_mean$y, mean = sst_mean$SST, sd = sst_sd$SST)


### 4 - Open diet data
diet <- readxl::read_excel(paste(func_dir, "Diet.xlsx", sep = "/"), sheet = "Diet_composition")
energ <- readxl::read_excel(paste(func_dir, "Diet.xlsx", sep = "/"), sheet = "Energy_content")

diet <- left_join(diet, energ, "Latin_name") %>% subset(Predator_key == "TURTRU")


### 7 - Construct weight
weight <- sn::rsn(n = 500, xi = 300, omega = 150, alpha = -1.9)
weight <- weight[-(which(weight < 50))]


### 8 - Construct weight
beta <- truncnorm::rtruncnorm(n = 500, mean = 3, sd = 0.2*2, a = 1, b = 5)


### 9 - Copy to data/
usethis::use_data(diet, overwrite = TRUE)
usethis::use_data(species_abundance, overwrite = TRUE)
usethis::use_data(sst, overwrite = TRUE)
usethis::use_data(weight, overwrite = TRUE)
usethis::use_data(map_coords, overwrite = TRUE)
usethis::use_data(beta, overwrite = TRUE)

# create the documentation
checkhelper::use_data_doc("diet")
rstudioapi::navigateToFile("R/doc_diet.R")

checkhelper::use_data_doc("species_abundance")
rstudioapi::navigateToFile("R/doc_species_abundance.R")

checkhelper::use_data_doc("sst")
rstudioapi::navigateToFile("R/doc_sst.R")

checkhelper::use_data_doc("weight")
rstudioapi::navigateToFile("R/doc_weight.R")

checkhelper::use_data_doc("map_coords")
rstudioapi::navigateToFile("R/doc_map_coords.R")

checkhelper::use_data_doc("beta")
rstudioapi::navigateToFile("R/doc_beta.R")

attachment::att_amend_desc() # do it each time changes anything in the R file (and reinstall)


