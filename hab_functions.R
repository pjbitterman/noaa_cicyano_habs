# helper functions

library(tidyverse)
library(sp)
library(sf)
library(raster)
library(rgeos)
library(fs)
library(lubridate)


### returns filenames and some file properties of NOAA images within a directory
collect_images <- function(im.path) {
  # get file names
  file_names <- fs::dir_ls(im.path) 
  ext_names <- fs::path_ext(file_names) # get file extensions
  
  # put in tibble, filter for tif only
  image.files <- data.frame(file_names, ext_names) %>%
    tbl_df() %>%
    mutate(fn_char = as.character(file_names)) %>%
    mutate(file_names = fs_path(file_names %>% as.character)) %>% #lost fs type when put into df
    filter(str_detect(ext_names, "tif")) %>%
    mutate(fn = fs::path_file(file_names)) %>%
    mutate(year = stringr::str_sub(fn, 4, 7),
           start_month = stringr::str_sub(fn, 9, 10),
           start_day = stringr::str_sub(fn, 11, 12),
           end_month = stringr::str_sub(fn, 14, 15),
           end_day = stringr::str_sub(fn, 16, 17)) %>%
    mutate(start_date = paste0(year, "-", start_month, "-", start_day),
           end_date = paste0(year, "-", end_month, "-", end_day))
}

### returns filenames and some file properties of NOAA images within a directory
collect_images_modis <- function(im.path) {
  # get file names
  file_names <- fs::dir_ls(im.path) 
  ext_names <- fs::path_ext(file_names) # get file extensions
  
  # put in tibble, filter for tif only
  image.files <- data.frame(file_names, ext_names) %>%
    tbl_df() %>%
    mutate(fn_char = as.character(file_names)) %>%
    mutate(file_names = fs_path(file_names %>% as.character)) %>% #lost fs type when put into df
    filter(str_detect(ext_names, "tif")) %>%
    mutate(fn = fs::path_file(file_names)) %>%
    mutate(year = stringr::str_sub(fn, 11, 14),
           start_month = stringr::str_sub(fn, 16, 17),
           start_day = stringr::str_sub(fn, 18, 19),
           end_month = stringr::str_sub(fn, 21, 22),
           end_day = stringr::str_sub(fn, 23, 24)) %>%
    mutate(start_date = paste0(year, "-", start_month, "-", start_day),
           end_date = paste0(year, "-", end_month, "-", end_day))
}



### subsets raster to bounding box
clip_raster_to_bounding <- function(in.raster.path, boundingPolygon.path) {
  
  # read raster
  ras <- raster::raster(in.raster.path)
  
  # get the projection attributes of the raster
  ras.p4 <- sp::proj4string(ras) 
  
  # read the bounding polygon
  bb <- sf::read_sf(boundingPolygon.path) ## read shapefile
  
  # project the bounding box to the raster's proj4
  bb.projected <- sf::st_transform(bb, ras.p4)
  
  # intersect raster and bounding box
  ras.subset <- rgeos::intersect(ras, bb.projected)
}


### calculates bloom size for WHO threshold bands within bounding box
calc_area_by_thresholds <- function(in.raster, boundingPolygon.path, 
                                    start_date, end_date,
                                    lake_transform) {


  # read the bounding polygon again for when we have 
  # to intersect points later
  bb <- sf::read_sf(boundingPolygon.path) ## read shapefile
  
  # get the projection attributes of the raster
  ras.p4 <- sp::proj4string(in.raster) 
  
  # project the bounding box to the raster's proj4
  bb.projected <- sf::st_transform(bb, ras.p4)
  
  
  # raster properties
  raster.res <- res(in.raster)
  pixel.area.m2 <- raster.res[1] * raster.res[2]
  
  # turn the st points into spatial points (makes filtering and counting easier)
  points.intersection <- as(in.raster,"SpatialPoints") 
  # get the dn.values
  points.values <- data.frame(dn.val = raster::extract(in.raster, 
                                                       points.intersection))
  # assign extracted vals to the points
  points.intersection$dn.val <- points.values
  
  # turn it into a sf so it's easier to work with
  # intersect with the bounding box again because when the 
  # rasters are intersected with the bb, it forces the output to be rectangular
  points.int.sf <- points.intersection %>% st_as_sf() %>%
    sf::st_intersection(., bb.projected) 
  
  if(lake_transform == "champlain_olci"){
    
    # valid points: 1-249 is valid data
    # as of 2019-02-01 metadata
    points_base <- points.int.sf %>% 
      mutate(index = transform_champlain_olci(dn.val)) 

  } else if(lake_transform == "erie_olci"){
    
    # valid points: 2-249 is valid data
    # as of 2019-02-01 metadata
    points_base <- points.int.sf %>% 
      mutate(index = transform_erie_olci(dn.val))

  } else if(lake_transform == "erie_modis"){
    points_base <- points.int.sf %>%
      mutate(index = transform_erie_modis(dn.val))
    
  } else {
    stop("your lake transformation was not found")
  }
  
  
  # THRESHOLDS ---- 
  # upper bounds on each - in units of CI (hence the divide by 1e8)
  # data from from WHO tables
  thresh.low <- 20000 / 1e8
  thresh.mod <- 100000 / 1e8
  thresh.high <- 10000000 / 1e8
  
  # then get sf for each 
  points_in_low <- points_base %>% 
    filter(index < thresh.low) 
  
  points_in_mod <- points_base %>%
    filter(index >= thresh.low & index < thresh.mod)
  
  points_in_high <- points_base %>%
    filter(index >= thresh.mod & index < thresh.high)
  
  points_in_veryhigh <- points_base %>%
    filter(index > thresh.high)
  
  list_of_sfs <- c(points_in_low, points_in_mod, 
                   points_in_high, points_in_veryhigh)
  
  # calculate metrics for each set of sf points
  calculate_area_pixels <- function(set_of_sfpoints){
    
    baseline_denom <- points_base %>% filter(!is.na(index)) %>% nrow()
    
    # proportion of points in the range / total non-land pixels
    prop_in_range <- nrow(set_of_sfpoints) / baseline_denom
    
    # area of pixels in range
    area_m2_in_range <- pixel.area.m2 * nrow(set_of_sfpoints)
    
    toReturn <- data.frame(prop_in_range, area_m2_in_range, 
                           start_date, end_date) %>%
      magrittr::set_colnames(c("prop_in_range", "area_m2_in_range", 
                               "start_date", "end_date"))
  }
  # can't get map_df to work right now (returns 0 rows), so do manually
  
  area_low <- calculate_area_pixels(points_in_low) %>% 
    mutate(whoCat = "low")
  area_mod <- calculate_area_pixels(points_in_mod) %>% 
    mutate(whoCat = "moderate")
  area_high <- calculate_area_pixels(points_in_high) %>% 
    mutate(whoCat = "high")
  area_veryhigh <- calculate_area_pixels(points_in_veryhigh) %>% 
    mutate(whoCat = "very_high")
  
  # combine and relevel the category factor
  all_areas <- bind_rows(area_low, area_mod, area_high, area_veryhigh) %>% 
    mutate(whoCat = forcats::fct_relevel(whoCat, c("very_high", 
                                                   "high", 
                                                   "moderate", 
                                                   "low")))
}

# extract values for points of interest
extract_values_at_pois <- function(in.raster, boundingPolygon.path,
                                   poi.path, start_date, end_date,
                                   lake_transform){
  
  # read the bounding polygon again for when we have 
  # to intersect points later
  bb <- sf::read_sf(boundingPolygon.path) ## read shapefile
  
  # read the POI shapefile
  poi <- sf::read_sf(poi.path) ## read shapefile
  
  # get the projection attributes of the raster
  ras.p4 <- sp::proj4string(in.raster) 
  
  # project the bounding box to the raster's proj4
  bb.projected <- sf::st_transform(bb, ras.p4)
  
  # project the poi to the raster's proj4
  poi.projected <- sf::st_transform(poi, ras.p4) %>% 
    mutate(poiRow = seq(1:nrow(.)))
  
  # only the pois in the bounding box
  poi.subset <- sf::st_intersection(poi.projected, bb.projected)
  
  # extract values of raster (DN)
  points.values <- data.frame(dn.val = raster::extract(in.raster, poi.subset))
  
  if(lake_transform == "champlain"){
    
    points.processed <- points.values %>%
      mutate(val_processed = transform_champlain(dn.val))
    
  }else if(lake_transform == "erie"){
    points.processed <- points.values %>%
      mutate(val_processed = transform_erie(dn.val))
  }else{
    stop("your lake transformation was not found")
  }
  
  toReturn <- points.processed %>% 
    dplyr::select(dn.val, val_processed) %>%
    mutate(start_date = start_date, 
           end_date = end_date,
           poiRow = poi.subset$poiRow)
  
}


# calculate distance from each poi to the nearest blooming pixel
calc_distance_to_pois <- function(in.raster, boundingPolygon.path,
                                  poi.path, start_date, end_date,
                                  lake_transform,
                                  trimPoiToStudyArea = TRUE){
  
  # read the bounding polygon again for when we have 
  # to intersect points later
  bb <- sf::read_sf(boundingPolygon.path) ## read shapefile
  
  # read the POI shapefile
  poi <- sf::read_sf(poi.path) ## read shapefile
  
  # get the projection attributes of the raster
  ras.p4 <- sp::proj4string(in.raster) 
  
  # project the bounding box to the raster's proj4
  bb.projected <- sf::st_transform(bb, ras.p4)
  
  # project the poi to the raster's proj4
  poi.projected <- sf::st_transform(poi, ras.p4) %>% 
    mutate(poiRow = seq(1:nrow(.)))
  
  if(trimPoiToStudyArea){
    # only the pois in the bounding box
    poi.subset <- sf::st_intersection(poi.projected, bb.projected)
  }
  else{
    poi.subset <- poi.projected
  }
 
  
  # turn the st points into spatial points (makes filtering and counting easier)
  points.intersection <- as(in.raster,"SpatialPoints") 
  # get the dn.values
  points.values <- data.frame(dn.val = raster::extract(in.raster, 
                                                       points.intersection))
  # assign extracted vals to the points
  points.intersection$dn.val <- points.values
  
  # turn it into a sf so it's easier to work with
  # intersect with the bounding box again because when the 
  # rasters are intersected with the bb, it forces the output to be rectangular
  points.int.sf <- points.intersection %>% st_as_sf() %>%
    sf::st_intersection(., bb.projected) 
  
  # then transform
  # then for each level, calculate distance
  
  if(lake_transform == "champlain"){
    
    # valid points: 1-249 is valid data
    # as of 2019-02-01
    points_base <- points.int.sf %>% 
      mutate(index = transform_champlain(dn.val)) 
    
  } else if(lake_transform == "erie"){
    
    # valid points: 2-249 is valid data
    # as of 2019-02-01
    points_base <- points.int.sf %>% 
      mutate(index = transform_erie(dn.val))
    
  } else if(lake_transform == "erie_modis"){
    points_base <- points.int.sf %>%
      mutate(index = transform_erie_modis(dn.val))
    
  } else {
    stop("your lake transformation was not found")
  }
  
  
  # THRESHOLDS ---- 
  # upper bounds on each - in units of CI (hence the divide by 1e8)
  # data from from WHO tables
  thresh.low <- 20000 / 1e8
  thresh.mod <- 100000 / 1e8
  thresh.high <- 10000000 / 1e8
  
  # then get sf for each 
  points_in_low <- points_base %>% 
    filter(index < thresh.low) 
  
  points_in_mod <- points_base %>%
    filter(index >= thresh.low & index < thresh.mod)
  
  points_in_high <- points_base %>%
    filter(index >= thresh.mod & index < thresh.high)
  
  points_in_veryhigh <- points_base %>%
    filter(index >= thresh.high)
  
  list_of_sfs <- c(points_in_low, points_in_mod, 
                   points_in_high, points_in_veryhigh)
  
  
  # calculate metrics for each set of sf points
  calculate_distance <- function(pois.subset, points_in_range){
    
    ### distance from pois to blooming point (Euclidian distance)
    poi_distance_df <- sf::st_distance(poi.subset, points_in_range) %>%
      as.tibble() %>%
      mutate(poiRow = poi.subset$poiRow)
  

    if(nrow(points_in_range) > 0){
      # calculate nearest pixel in threshold to each POI
      poi_min_distance <- poi_distance_df %>%
        gather(., "bloom_pt", "distance", -poiRow) %>%
        group_by(poiRow) %>%
        summarise(nearestDistance = min(distance)) %>%
        arrange(poiRow)
    } else{
      poi_min_distance <- poi_distance_df %>%
        mutate(nearestDistance = NA)
    }
    
    return(poi_min_distance)
  }
  
  # can't get map_df to work right now (returns 0 rows), so do manually
  dist_low <- calculate_distance(poi.subset, points_in_low) %>% 
    mutate(whoCat = "low")
  dist_mod <- calculate_distance(poi.subset, points_in_mod) %>% 
    mutate(whoCat = "moderate")
  dist_high <- calculate_distance(poi.subset, points_in_high) %>% 
    mutate(whoCat = "high")
  dist_veryhigh <- calculate_distance(poi.subset, points_in_veryhigh) %>% 
    mutate(whoCat = "very_high")
  
  # combine and relevel the category factor
  all_dists <- bind_rows(dist_low, dist_mod, dist_high, dist_veryhigh) %>% 
    mutate(whoCat = forcats::fct_relevel(whoCat, 
                                         c("very_high", 
                                           "high", 
                                           "moderate", 
                                           "low"))) %>%
    mutate(start_date = start_date,
           end_date = end_date)    
}

### calculates mean bloom value within bounding box
calc_ciValueInArea <- function(in.raster, boundingPolygon.path, 
                                    start_date, end_date,
                                    lake_transform) {
  
  # read the bounding polygon again for when we have 
  # to intersect points later
  bb <- sf::read_sf(boundingPolygon.path) ## read shapefile
  
  # get the projection attributes of the raster
  ras.p4 <- sp::proj4string(in.raster) 
  
  # project the bounding box to the raster's proj4
  bb.projected <- sf::st_transform(bb, ras.p4)
  
  
  # raster properties
  raster.res <- res(in.raster) #raster resolution, assume meters
  pixel.area.m2 <- raster.res[1] * raster.res[2]
  
  # turn the st points into spatial points (makes filtering and counting easier)
  points.intersection <- as(in.raster,"SpatialPoints") 
  # get the dn.values
  points.values <- data.frame(dn.val = raster::extract(in.raster, 
                                                       points.intersection))
  # assign extracted vals to the points
  points.intersection$dn.val <- points.values
  
  # turn it into a sf so it's easier to work with
  # intersect with the bounding box again because when the 
  # rasters are intersected with the bb, it forces the output to be rectangular
  points.int.sf <- points.intersection %>% st_as_sf() %>%
    sf::st_intersection(., bb.projected) 
  
  if(lake_transform == "champlain"){
    
    # valid points: 1-249 is valid data
    # as of 2019-02-01
    points_base <- points.int.sf %>% 
      mutate(index = transform_champlain(dn.val)) 
    
  } else if(lake_transform == "erie"){
    
    # valid points: 2-249 is valid data
    # as of 2019-02-01
    points_base <- points.int.sf %>% 
      mutate(index = transform_erie(dn.val))
    
  } else {
    stop("your lake transformation was not found")
  }
  
  valid_pts <- points_base %>% dplyr::filter(!is.na(index))
  
  if(nrow(valid_pts) > 0){
    meanCi <- mean(valid_pts$index)
  }
  else{
    meanCi = 0
  }
  

  toReturn <- data.frame(meanCi, start_date)
  
  
}


# NOAA transform for ERIE data
# valid as of 2019-02-01
transform_erie_olci <- function(x){
  
  # valid points: 2-249 is valid data
  ifelse(x > 1 & x < 250,
         10**(x / 100 - 4),
         NA)
  
}

# NOAA transform for CHAMPLAIN data
# valid as of 2019-02-01 metadata
transform_champlain_olci <- function(x){
  
  # valid points: 2-249 is valid data
  ifelse(x > 1 & x < 250,
         10**(((3.0 / 250.0) * x) - 4.2),
         NA)
}

# NOAA transform for Erie MODIS data
# valid as of 2019-03-22 metadata
# same as erie OLCI transform
transform_erie_modis <- function(x){
  
  # valid points: 2-249 is valid data
  ifelse(x > 1 & x < 250,
         10**(x / 100 - 4),
         NA)
  
}



