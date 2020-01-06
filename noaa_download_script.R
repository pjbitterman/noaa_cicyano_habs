library(tidyverse)
library(downloader)
library(rvest)

champ.url <- "https://products.coastalscience.noaa.gov/habs_explorer/index.php?path=djFYWEE0NURTMllpTkN5VUVzdmtIcW5YWE83TTdDRzg2VldJWTFoc3JQdnBpckZ1K2FyTHgzUjUxSFNlOWlVZw==&uri=VWtuM1UzbVNVN0RsZzJMeTJvNlNpM29OalF0WTFQQjVZVnpuS3o5bnh1Ym0vYWhtWEh4ck1hREVUamE4SDZ0M0JnSnNMaHk4U2YyaTc0R04zM2ZId0hBbkVjOGkrTnJJMXR3WmtJbGJFeUkyUTY2OCtjUmpSUEFyWXpNWEIzZlc=&type=bllEUXA3TmhSK21RVDlqbFYxMmEwdz09"
erie.url <- "https://products.coastalscience.noaa.gov/habs_explorer/index.php?path=eXhJRlJpQjQ0NnNyYmQwL21vSFpjWWxoeWtud2l3YmhYSlhBUjM4bTM2QT0=&uri=VWtuM1UzbVNVN0RsZzJMeTJvNlNpM29OalF0WTFQQjVZVnpuS3o5bnh1Ym0vYWhtWEh4ck1hREVUamE4SDZ0M0JnSnNMaHk4U2YyaTc0R04zM2ZId04wdC8rNVdEdEdKTS9CQ3pEY2I0ZDg9&type=bllEUXA3TmhSK21RVDlqbFYxMmEwdz09"

champ.dltarget <- fs::fs_path("./downloads/champ")
erie.dltarget <- fs::fs_path("./downloads/erie")


image_dl_and_org <- function(noaaUrl, downloadUrl){
  
  hab.html <-read_html(noaaUrl)
  
  #gets links
  links.all <- hab.html %>%
    html_nodes(".onecol > a") %>%
    html_attr('href') 
  
  # the readme files have two links each, so clean up (get rid of 4)
  links.cleaned <- links.all %>% 
    tail(length(.) - 4)
  
  # gets names
  names.all <- hab.html %>% 
    html_nodes(".onecol") %>%
    html_text() 
  
  # the parsing of text has both readmes and a "names" header, so clean up
  # (get rid of 3)
  names.cleaned <- names.all %>%
    tail(length(.) - 3) %>% as.character()
  
  # put them in a data.frame and use regex to extract 
  # the category (e.g., CI, CIcyano) of image
  df <- data.frame(links.cleaned, names.cleaned) %>%
    mutate(img.type = stringr::str_match(names.cleaned, "_[0-9]\\.(.*?)\\.tif")[,2])
  
  i.cats <- df$img.type %>% unique()
  
  if(!fs::dir_exists(downloadUrl)){
    fs::dir_create(downloadUrl)
  }
  
  # outer function to get just the data we want
  dl_chunks <- function(image.category) {
    
    # create new subdirectory
    subdir <- file.path(downloadUrl, image.category) %>%
      fs::as_fs_path()
    
    if(!fs::dir_exists(subdir)){
      fs::dir_create(subdir)
    }
    
    # get the chunk of files to download
    chunkToDl <- df %>% filter(img.type == image.category)
    
    # function to download individual images
    dl_images <- function(link, fname, basepath){
      dltarget <- paste0(basepath, "/", fname)
      if(!fs::file_exists(dltarget)){
        downloader::download(link, dltarget)
      }
      else{
        print("file exists, skipping")
      }
    }
    
    # put them in a list
    flist <- list(as.character(chunkToDl$links.cleaned), 
                  as.character(chunkToDl$names.cleaned), subdir)

    # download them all
    flist %>% pmap(dl_images)
    
  }
  
  i.cats %>% purrr::map(dl_chunks)
  
}


image_dl_and_org(champ.url, champ.dltarget)
image_dl_and_org(erie.url, erie.dltarget)

