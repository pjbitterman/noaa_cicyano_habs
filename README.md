# NOAA HAB Data Explorer helper scripts

This respository contains R scripts to aid in the download and processing of data from the NOAA HAB Data Explorer site (https://app.coastalscience.noaa.gov/habs_explorer/index.php?path=MjlWcmZwWDVIWDlGdnFqelpiRmZkUT09). The scripts previously worked on the Lake Erie, Lake Champlain, and Chesapeake Bay OLCI data products. HOWEVER, NOAA has recently updated their site such that: 1) Lake Champlain data are no longer published, and 2) the backend links are less consistent. While there is a web interface (https://coastalscience.noaa.gov/science-areas/habs/hab-monitoring-system/) to view and download these data, it involves a lot of clicking on images to manually download.

These scripts USED TO automate the process and help with some minor data processing. I originally developed these during my postdoc at the University of Vermont. I'm leaving the repository up for the sake of posterity and to provide an example of how to scrape/parse/download files using R tools. However, given the moving target of the NOAA site, I would not trust the download scripts in their current state.

- Use noaa_download_script.R to batch download the images.
- hab_functions.R is a series of scripts used to estimate bloom severity and extent for a SESYNC project. It works on composited images (from NOAA's ArcMap plug-in) and is likely not relevant to your particular application.