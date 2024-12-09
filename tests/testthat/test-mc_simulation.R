# WARNING - Generated by {fusen} from dev/flat_bioconsest.Rmd: do not edit by hand

test_that("mc_simulation() returns an error when no prey category in the provided prey_taxonomic_level",
  expect_error(
    object = mc_simulation(predator_name = "TURTRU", 
                           predator_group = "Cetacean",
             map_coordinates = map_coords,
             prey_taxonomic_level = "Taxonomic_group", 
             diet = diet |> subset(Taxonomic_group == "Krill"), 
             assimilation_rate = 0.8,
             n_days = 30+31+31,
             predator_weight = weight, 
             abundance_map = species_abundance, 
             temperature_map = NULL),
    regexp = "No prey categories in Taxonomic_group for TURTRU"
  )
)
