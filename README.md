# NOAA HAB Data Explorer helper scripts

This respository contains R scripts to aid in the download and processing of data from the NOAA HAB Data Explorer site (https://products.coastalscience.noaa.gov/habs_explorer/index.php?path=ZDdvU1ZrdnRjSE82bU9QRHRXWmpOdz09). The scripts have only been tested on the Lake Erie, Lake Champlain, and Chesapeake Bay OLCI data products. 

Essentially, the website design makes it difficult to download large amounts of data from NOAA. These scripts automate the process and help with some minor data processing. I originally developed these during my postdoc at the University of Vermont, but still use them occasionally in my research.

- Use noaa_download_script.R to batch download the images.
- hab_functions.R is a series of scripts used to estimate bloom severity and extent for a SESYNC project. It works on composited images (from NOAA's ArcMap plug-in) and is likely not relevant to your particular application.