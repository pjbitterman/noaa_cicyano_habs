library(tidyverse)
library(downloader)
library(rvest)


# URLs on the NOAA HABS Explorer page
champ.url.old <- "https://products.coastalscience.noaa.gov/habs_explorer/index.php?path=djFYWEE0NURTMllpTkN5VUVzdmtIcW5YWE83TTdDRzg2VldJWTFoc3JQdnBpckZ1K2FyTHgzUjUxSFNlOWlVZw==&uri=VWtuM1UzbVNVN0RsZzJMeTJvNlNpM29OalF0WTFQQjVZVnpuS3o5bnh1Ym0vYWhtWEh4ck1hREVUamE4SDZ0M0JnSnNMaHk4U2YyaTc0R04zM2ZId0hBbkVjOGkrTnJJMXR3WmtJbGJFeUkyUTY2OCtjUmpSUEFyWXpNWEIzZlc=&type=bllEUXA3TmhSK21RVDlqbFYxMmEwdz09"
champ.url.new <- "https://products.coastalscience.noaa.gov/habs_explorer/index.php?path=djFYWEE0NURTMllpTkN5VUVzdmtIbGxQalBCYVd5REsvL0lVYzNJaVF2NlY1a1F2TS9tblJyWjZxdnV4NVE3eQ==&uri=VWtuM1UzbVNVN0RsZzJMeTJvNlNpM29OalF0WTFQQjVZVnpuS3o5bnh1Ym0vYWhtWEh4ck1hREVUamE4SDZ0M0JnSnNMaHk4U2YyaTc0R04zM2ZId0hBbkVjOGkrTnJJMXR3WmtJbGJFeUx4OUVOMlc2TEV4ckdQSXZhQWRZQXQ=&type=bllEUXA3TmhSK21RVDlqbFYxMmEwdz09"
erie.url.older <- "https://products.coastalscience.noaa.gov/habs_explorer/index.php?path=eXhJRlJpQjQ0NnNyYmQwL21vSFpjWWxoeWtud2l3YmhYSlhBUjM4bTM2QT0=&uri=VWtuM1UzbVNVN0RsZzJMeTJvNlNpM29OalF0WTFQQjVZVnpuS3o5bnh1Ym0vYWhtWEh4ck1hREVUamE4SDZ0M0JnSnNMaHk4U2YyaTc0R04zM2ZId04wdC8rNVdEdEdKTS9CQ3pEY2I0ZDg9&type=bllEUXA3TmhSK21RVDlqbFYxMmEwdz09"
erie.url.old <- "https://products.coastalscience.noaa.gov/habs_explorer/index.php?path=eXhJRlJpQjQ0NnNyYmQwL21vSFpjWWxoeWtud2l3YmhYSlhBUjM4bTM2QT0=&uri=VWtuM1UzbVNVN0RsZzJMeTJvNlNpM29OalF0WTFQQjVZVnpuS3o5bnh1Ym0vYWhtWEh4ck1hREVUamE4SDZ0M0JnSnNMaHk4U2YyaTc0R04zM2ZId04wdC8rNVdEdEdKTS9CQ3pEY2I0ZDg9&type=bllEUXA3TmhSK21RVDlqbFYxMmEwdz09"
erie.url <- "https://app.coastalscience.noaa.gov/habs_explorer/index.php?path=RUIvWnB3dWJmS3RvNXlWcjF4a1hLM1B0eERkak1wT2hueTFPRjFMSzVyQmJYMjVpQ2NmUzk5eVllQlVQd1ZiTw==&uri=VWtuM1UzbVNVN0RsZzJMeTJvNlNpM29OalF0WTFQQjVZVnpuS3o5bnh1Ym0vYWhtWEh4ck1hREVUamE4SDZ0M2tsd1M1OWg3UDJ0djIrNEkvbXliRUpBLzVSc3NaMVRvY3I5TG9ISjNTM2E4dDVNRzVZNmt2TjBVMHF5dUtha2s=&type=bllEUXA3TmhSK21RVDlqbFYxMmEwdz09"
ches.url <- "https://app.coastalscience.noaa.gov/habs_explorer/index.php?path=VExHdnF1V2hheWFIczEvcDJMMVNlSWFWKzBEZEhWT1pDN2hlK01jL3VBendadUlBR05sdWtmQitzSTkzOTgwTg==&uri=VWtuM1UzbVNVN0RsZzJMeTJvNlNpM29OalF0WTFQQjVZVnpuS3o5bnh1Ym0vYWhtWEh4ck1hREVUamE4SDZ0M2tsd1M1OWg3UDJ0djIrNEkvbXliRUtwU2p1eSsvZzZjU0cxZ2lDcUl2RjRpQ3hvNDJIWTZENWpkMFZXVXNwOFY=&type=bllEUXA3TmhSK21RVDlqbFYxMmEwdz09"

# local directories to download to
champ.dltarget <- fs::fs_path("./downloads/champ")
erie.dltarget <- fs::fs_path("./downloads/erie")
ches.dltarget <- fs::fs_path("./downloads/chesapeake")

# function to batch download and sort downloaded images
# automatically skips previously downloaded files
image_dl_and_org <- function(noaaUrl, downloadUrl){
  
  hab.html <- read_html(noaaUrl)

  # gets names
  names.all <- hab.html %>% 
    html_nodes(".onecol") %>%
    html_text() 
  
  # the parsing of text has both readmes and a "names" header, so clean up
  # and retain only those with the 'sentinel-3' string in their name
  names.cleaned <- names.all %>%
    str_subset(., "sentinel-3") %>% 
    as.character() %>%
    stringr::str_trim(., "left")

  
  #gets links
  links.all <- hab.html %>%
    html_nodes(".onecol > a") %>%
    html_attr('href') 
  
  # get rid of readme and other files (like legend)
  # ensure we have the same number of names and links
  links.cleaned <- links.all %>% 
    tail(length(names.cleaned))
  
  
  # put them in a data.frame and use regex to extract 
  # the category (e.g., CI, CIcyano) of image
  # NOAA keeps changing file name patterns and breaking regex.
  # this is less elegant (and i'm sure there's a way to nest the expressions),
  # but it works and should hopefully be more generalizable
  fun.extract.imgtype <- function(instring){
    toReturn <-str_extract(instring, "(.*(?=\\.tif))") %>% 
      str_extract(., "[^\\.]+$")
    return(toReturn)
  }
  

  df <- data.frame(link = links.cleaned, fname = names.cleaned) %>%
    mutate(img.type = fun.extract.imgtype(fname))
  
  
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
    flist <- list(as.character(chunkToDl$link), 
                  as.character(chunkToDl$fname), subdir)

    # download them all
    flist %>% pmap(dl_images)
    
  }
  
  i.cats %>% purrr::map(dl_chunks)
  
}


### download them ----
image_dl_and_org(champ.url.new, champ.dltarget) 
image_dl_and_org(erie.url, erie.dltarget)
image_dl_and_org(ches.url, ches.dltarget)


