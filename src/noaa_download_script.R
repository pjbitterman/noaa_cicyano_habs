library(tidyverse)
library(downloader)
library(rvest)


# URLs on the NOAA HABS Explorer page
champ.url <- "https://products.coastalscience.noaa.gov/habs_explorer/index.php?path=djFYWEE0NURTMllpTkN5VUVzdmtIcW5YWE83TTdDRzg2VldJWTFoc3JQdnBpckZ1K2FyTHgzUjUxSFNlOWlVZw==&uri=VWtuM1UzbVNVN0RsZzJMeTJvNlNpM29OalF0WTFQQjVZVnpuS3o5bnh1Ym0vYWhtWEh4ck1hREVUamE4SDZ0M0JnSnNMaHk4U2YyaTc0R04zM2ZId0hBbkVjOGkrTnJJMXR3WmtJbGJFeUkyUTY2OCtjUmpSUEFyWXpNWEIzZlc=&type=bllEUXA3TmhSK21RVDlqbFYxMmEwdz09"
erie.url <- "https://products.coastalscience.noaa.gov/habs_explorer/index.php?path=eXhJRlJpQjQ0NnNyYmQwL21vSFpjWWxoeWtud2l3YmhYSlhBUjM4bTM2QT0=&uri=VWtuM1UzbVNVN0RsZzJMeTJvNlNpM29OalF0WTFQQjVZVnpuS3o5bnh1Ym0vYWhtWEh4ck1hREVUamE4SDZ0M0JnSnNMaHk4U2YyaTc0R04zM2ZId04wdC8rNVdEdEdKTS9CQ3pEY2I0ZDg9&type=bllEUXA3TmhSK21RVDlqbFYxMmEwdz09"
ches.url <- "https://products.coastalscience.noaa.gov/habs_explorer/index.php?path=bVoraGxra3BOd0pQdnhnL21jd0QxL1hGRjE5QWRQaTVxWVI5VTlPaDlKbz0=&uri=VWtuM1UzbVNVN0RsZzJMeTJvNlNpM29OalF0WTFQQjVZVnpuS3o5bnh1Ym0vYWhtWEh4ck1hREVUamE4SDZ0M0JnSnNMaHk4U2YyaTc0R04zM2ZId0tDRGEwSjVPOVVQSjhjWXF4Z0g1Y0QxQlNaTGVHWHpKVXYxRnlNNnQ1bXA=&type=bllEUXA3TmhSK21RVDlqbFYxMmEwdz09"

# local directories to download to
champ.dltarget <- fs::fs_path("./downloads/champ")
erie.dltarget <- fs::fs_path("./downloads/erie")
ches.dltarget <- fs::fs_path("./downloads/chesapeake")

# function to batch download and sort downloaded images
# automatically skips previously downloaded files
image_dl_and_org <- function(noaaUrl, downloadUrl, lines_to_skip){
 
  hab.html <- read_html(noaaUrl)
  
  #gets links
  links.all <- hab.html %>%
    html_nodes(".onecol > a") %>%
    html_attr('href') 
  
  # get rid of readme and other files (like legend)
  links.cleaned <- links.all %>% 
    tail(length(.) - lines_to_skip)
  
  # gets names
  names.all <- hab.html %>% 
    html_nodes(".onecol") %>%
    html_text() 
  
  # the parsing of text has both readmes and a "names" header, so clean up
  # (get rid of first n, where n = 'lines_to_skip' parameter)
  names.cleaned <- names.all %>%
    tail(length(.) - 3) %>% as.character()
  
  # put them in a data.frame and use regex to extract 
  # the category (e.g., CI, CIcyano) of image
  df <- data.frame(links.cleaned, names.cleaned) %>%
    mutate(img.type = stringr::str_match(names.cleaned, "(_|-)[0-9]\\.(.*?)\\.tif")[,3])
  
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
        
        tryCatch(
          expr = {
            downloader::download(link, dltarget)
            message(paste0("Successfully downloaded "), link)
          },
          error = function(e){
            message(paste0("!!ERROR!!, COULD NOT DOWNLOAD ", link))
            print(e)
          },
          warning = function(w){
            message('Caught a warning!')
            print(w)
          },
          finally = {
            #message('All done, quitting.')
          }
        )   
        
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


### download them ----
image_dl_and_org(champ.url, champ.dltarget, lines_to_skip = 4) 
image_dl_and_org(erie.url, erie.dltarget, lines_to_skip = 3)
image_dl_and_org(ches.url, ches.dltarget, lines_to_skip = 3)


