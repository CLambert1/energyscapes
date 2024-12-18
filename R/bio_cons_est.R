# WARNING - Generated by {fusen} from dev/flat_bioconsest.Rmd: do not edit by hand


#' Estimating energyscape and biomass consumption
#'
#' The function first estimates the energyscape (spatialised energetic need of the population) of a marine predator species (either cetacean, seabirds, loggerhead turtles, sunfish, sharks, tunas or swordfish) from its abundance map and body mass distribution, as well as the sea surface temperature (for fish only). Second, the function estimate the daily ration consumed for a given prey group by a single predator individual and the corresponding biomass consumed by the total population. Results are provided as maps and vectors. This function runs a single estimation. 
#' Allometric relationships are derived from White et al. (2011) with beta parameters from Spitz et al. (2012) for cetaceans; from Ultsch et al. 2013 for loggerhead turtle; from Killen et al. (2016) for fishes and from Shaffer et al. (2011) for seabirds (contrasting Procellariforms and Charadriforms). 
#' 
#' @param predator_group Character. Predator taxonomic group, used to select the allometric equation used to compute the analysis. Can be "Cetacean", "Fish", "Charadriform", "Procellariform", "Loggerhead turtle"
#' @param predator_name Character. Name to be used in exported dataframes
#' @param prey_taxonomic_level Taxonomic level at which the diet is summarize (either "Family", "Taxonomic_group" or "Functional_group", for example), i.e. the column in which prey_group will be subsetted
#' @param prey_group Which level of the diet to select (one of the levels in the chosen prey_taxonomic_level)
#' @param diet Diet table, including the considered predator only. Must include pW (proportion of each item in the diet, as proportion of wet weight), Energy_content of the prey item (in kJ/g) and the column provided in prey_taxonomic_group
#' @param assimilation_rate Assimilation rate to be used to estimate the daily ration (default to 0.8)
#' @param n_days Number of days over which estimating biomas consumption (default to 1)
#' @param beta Vector of life cost parameter, used only for mammals
#' @param predator_weight Vector of body mass distribution for the predator (in kg)
#' @param abundance_map  Abundance map of the predator (must provide columns named mean and sd)
#' @param temperature_map SST map (only used for fish; must provide columns named mean and sd)
#'
#' @return The function returns a list composed of 6 elements: FMR, the energetic needs of a single individuals (kJ/d); abundance, the abubndance map; Energyscape, the energyscape map for the total predator population, for a single day (FMR*abundance; kJ/d); daily_ration, the estimated daily ration (in kg); prop_body_mass, the daily ration expressed as proportion of predator body mass; conso_map, a map of the prey_group biomass consumed by the predator population over the period provided by n_days.
#' 
#' @importFrom glue glue
#' @importFrom assertthat assert_that '%has_name%'
#' @importFrom dplyr mutate summarize select rename
#' @importFrom tidyselect contains
#' 
#' @export
#'
#' @examples
#' result <- bio_cons_est(predator_group = "Procellariform",
#'              predator_name = "CALDIO", 
#'              prey_taxonomic_level = "Taxonomic_group", 
#'              prey_group = "Teleost",
#'              diet = diet, 
#'              assimilation_rate = 0.8,
#'              n_days = 30+31+31,
#'              predator_weight = weight, 
#'              abundance_map = species_abundance, 
#'              temperature_map = sst)
#'
bio_cons_est <- function(predator_group,
                         predator_name,
                       beta = NULL,
                       prey_taxonomic_level, 
                       prey_group, 
                       diet, 
                       assimilation_rate = 0.8, 
                       n_days = 1,
                       predator_weight, # en kg
                       abundance_map, 
                       temperature_map = NULL){
  # checks ----
  if(isFALSE(predator_group %in% c("Cetacean", "Fish", "Procellariform", "Charadriform", "Loggerhead turtle"))){
    stop(glue::glue("{predator_group} is not a supported group of predator"))
  }
  assert_that(is.vector(predator_weight, mode = "numeric"))
  assert_that(is.data.frame(diet))
  assert_that(diet %has_name% c("pW", "Energy_content", prey_taxonomic_level))
  assert_that(is.data.frame(abundance_map))
  assert_that(abundance_map %has_name% c("mean", "sd"))
  
  if(all(isTRUE(predator_group == "Fish"), 
         is.null(temperature_map))){
    stop("you must provide a temperature_map when predator_group is 'Fish'")
  }
  if(all(isTRUE(predator_group == "Fish"), 
         isFALSE(is.data.frame(temperature_map)))){
    stop("temperature_map must be a dataframe")
  }
  if(all(isTRUE(predator_group == "Fish"),
         isFALSE(nrow(abundance_map) == nrow(temperature_map)))){
    stop("abundance_map and temperature_map must have the same length")
  }
  if(all(isTRUE(predator_group == "Fish"), 
         isFALSE(c("mean", "sd") %in% names(temperature_map)))){
    stop("temperature_map must contain mean and sd columns")
  }
  if(all(isTRUE(predator_group %in% c("Cetacean", "Loggerhead turtle")), 
         is.null(beta))){
    stop(glue::glue("you must provide a beta distribution when predator_group is {predator_group}"))
  }
  if(all(isTRUE(predator_group %in% c("Cetacean", "Loggerhead turtle")), 
         isFALSE(is.vector(beta, mode = "numeric")))){
    stop("beta must be a numeric vector")
  }
  
  #### Sample parameters ----
  predator_weight <- sample(predator_weight, size = 1)
  abundance <- as.vector( t( rnorm(n = nrow(abundance_map), 
                            mean = abundance_map[, "mean"], 
                            sd = abundance_map[, "sd"]) ))
  abundance[which(abundance < 0)] <- 0
  # le rnorm fait un tirage aleatoire sur chaque cellule independamment, donc le resultat n'est pas lisse
  
  #### FMR estimation ----
  if(predator_group == "Cetacean"){
    beta <- sample(beta, size = 1)
    # BMR <- 4.08*((predator_weight*1000)^0.69) *0.48 # *0.48 to put it from mLO2/h into kJ/d # WHITE
    BMR <- 293.1*((predator_weight)^0.75)  # KLEIBER
    FMR <- beta * BMR
    energyscape <- FMR * abundance
  }
  if(predator_group == "Fish"){
    temperature <- as.vector( t( rnorm(n = nrow(temperature_map), 
                                       mean = temperature_map$mean, 
                                       sd = temperature_map$sd) ))
    FMR <- 0.563 * ((predator_weight*1000)^0.937) * exp(0.025 * temperature) * 0.48*0.752  # *0.752 to put it from mgO2/h into kJ/d
    energyscape <- FMR * abundance
  }
  if(predator_group == "Procellariform"){
    FMR <- 23.326*((predator_weight*1000)^0.562)  # Shaffer et al 2011
    # FMR <- 2.149*((predator_weight*1000)^0.804) *3.9 # Ellis&Gabrielsen 2002 + Garthe et al 1996
    energyscape <- FMR * abundance
  }
  if(predator_group == "Charadriform"){
    FMR <- 10.181*((predator_weight*1000)^0.717)
    energyscape <- FMR * abundance
  }
  if(predator_group == "Loggerhead turtle"){
    beta <- sample(beta, size = 1)
    BMR <- 0.674*((predator_weight*1000)^0.649) * 0.48  # *0.48 to put it from mLO2/h into kJ/d
    FMR <- beta * BMR
    energyscape <- FMR * abundance
  }
  
  #### Diet ----
  sum_pw_e <- diet |> 
    as.data.frame() |>
    dplyr::mutate(quality = (pW/100) * Energy_content) |>
    dplyr::summarize(quality = sum(quality, na.rm = T)) |> as.data.frame() |>
    dplyr::mutate(Predator_key = predator_name)
    
  diet_compo <- diet |>
    dplyr::rename(Prey_category = tidyselect::contains(prey_taxonomic_level)) |> 
    subset(Prey_category == prey_group) |> 
    as.data.frame() |>
    dplyr::summarize(proportion = sum(pW/100, na.rm = T)) |> as.data.frame() |>
    dplyr::mutate(Predator_key = predator_name)

  
  #### Biomass consumption ----
  # ration journaliere (en kg)
  daily_ration <- ( ( FMR / (assimilation_rate * sum_pw_e$quality) )  * diet_compo$proportion ) /1000
  
  
  # ration journaliere en proportion du poids corporel
  prop_body_mass <- (daily_ration / predator_weight)*100
  
  # total consumption
  total_biomass <- daily_ration * abundance * n_days
  
  
  #### Return ----
  return(list(
    FMR = FMR,
    abundance = abundance,
    Energyscape = energyscape,
    daily_ration = daily_ration,
    prop_body_mass = prop_body_mass,
    conso_map = total_biomass))
}

