Abstract
	Ocean color products derived from  the Ocean Colour Land Imager (OLCI) aboard the European Space Agency's Sentinel-3 satellite. Products are calculated from Remote Sensing Reflectance (Rrs) and/or top of atmosphere reflectance corrected for Rayleigh scattering and molecular absorption (Rhos).

Purpose
	For use in estimating water quality and detecting algal blooms in the Continental US.

Extents
	Extent - Geographic
	West longitude -83.683300
	East longitude -78.614971
	North latitude 43.006608
	South latitude 41.275309

	Extent - GeoTiFF coordinate system
	West coordinate 281282.934996
	East coordinate 694382.934996
	North coordinate 4764308.997997
	South coordinate 4572608.997997

Spatial Representation - Grid
	Number of Dimensions 2
	Axis dimension properties
		Dimension
			Dimension name: column
			Dimension size: 1377
			Resolution
				Distance 300.0
		Dimension
			Dimension name: row
			Dimension size: 639
			Resolution
				Distance 300.0

	Corner points
		CornerPoint 281282.934996 4764308.997997
		CornerPoint 281282.934996 4572608.997997
		CornerPoint 694382.934996 4764308.997997
		CornerPoint 694382.934996 4572608.997997

Content Information
	Feature Catalog Description
		Files listed in this catalog contain a collection of daily products in GeoTIFF format. Details of each product may be found below.
		Filenames follow the following naming conventention:
			<sat>.yyyyjjj.mmdd.hhmm...hhmmC.L3.<areacode>.<srccode><version>.<productname>.tif
				<sat>		name of satellite
				yyyy		4-digit year
				jjj		julian day (zero-prefixed)
				mm		month of year (zero-prefixed)
				dd		day of month (zero-prefixed)
				hh		hour (zero-prefixed)
				mm		minute (zero-prefixed)
				<areacode>		areacode
				<srccode>		level 2 source code (v=SAPS,n=NASA,e=ESA)
				<l2genversion>		level 2 generating software version
				<SAPSversion>		SAPS software version
				<prodscriptversion>		product generating script version
				<productname>		standard product name

		Products where <prodscriptversion>=2
			Product name: CI
			Version: 1.1
			Description: Chlorophyll Cyanobacteria Index with clear water correction and CInoMCI adjacency flagging
			Scaling: round(83.3 * (log10(ci[ci>0]) + 4.2))
			Reverse scaling: 10**(3.0 / 250.0 * DN - 4.2) (for example: DN=100 translates to original value = 0.0010)
			Type: 1-band data
			Data key:
				0 - no detection
				250 - above range
				251 - adjacency
				252 - land
				253 - cloud
				254 - mixed or invalid
				255 - no data coverage
				1 - 249: scaled valid data

			Product name: CIcyano
			Version: 1.1
			Description: Chlorophyll Cyanobacteria Index - cyano only with clear water correction and CInoMCI adjacency flagging
			Scaling: round(83.3 * (log10(ci[ci>0]) + 4.2))
			Reverse scaling: 10**(3.0 / 250.0 * DN - 4.2) (for example: DN=100 translates to original value = 0.0010)
			Type: 1-band data
			Data key:
				0 - no detection
				250 - above range
				251 - adjacency
				252 - land
				253 - cloud
				254 - mixed or invalid
				255 - no data coverage
				1 - 249: scaled valid data

			Product name: CInoncyano
			Version: 1.1
			Description: Chlorophyll Cyanobacteria Index - noncyano only with clear water correction and CInoMCI adjacency flagging
			Scaling: round(83.3 * (log10(ci[ci>0]) + 4.2))
			Reverse scaling: 10**(3.0 / 250.0 * DN - 4.2) (for example: DN=100 translates to original value = 0.0010)
			Type: 1-band data
			Data key:
				0 - no detection
				250 - above range
				251 - adjacency
				252 - land
				253 - cloud
				254 - mixed or invalid
				255 - no data coverage
				1 - 249: scaled valid data

			Product name: truecolor
			Version: 1.0
			Description: RGB true color image
			Scaling: round(1.0 * <band> * 255 / 0.2)
			Type: 3-band RGB

		Products where <prodscriptversion>=1
			Product name: CIcyano
			Version: 1.1
			Description: Chlorophyll Cyanobacteria Index - cyano only with clear water correction
			Scaling: round((250 / 2.5) * (4 + log10(ci[ci>0])))
			Reverse scaling: 10**(DN/100 - 4) (for example: DN=100 translates to original value = 0.0010)
			Type: 1-band data
			Data key:
				1 - no detection
				250 - above range
				251 - adjacency
				252 - land
				253 - cloud
				254 - mixed or invalid
				0 - no data coverage
				2 - 249: scaled valid data

Reference System Information
	Spatial reference:
		PROJCS["WGS 84 / UTM zone 17N",
		    GEOGCS["WGS 84",
		        DATUM["WGS_1984",
		            SPHEROID["WGS 84",6378137,298.257223563,
		                AUTHORITY["EPSG","7030"]],
		            AUTHORITY["EPSG","6326"]],
		        PRIMEM["Greenwich",0,
		            AUTHORITY["EPSG","8901"]],
		        UNIT["degree",0.0174532925199433,
		            AUTHORITY["EPSG","9122"]],
		        AUTHORITY["EPSG","4326"]],
		    PROJECTION["Transverse_Mercator"],
		    PARAMETER["latitude_of_origin",0],
		    PARAMETER["central_meridian",-81],
		    PARAMETER["scale_factor",0.9996],
		    PARAMETER["false_easting",500000],
		    PARAMETER["false_northing",0],
		    UNIT["metre",1,
		        AUTHORITY["EPSG","9001"]],
		    AXIS["Easting",EAST],
		    AXIS["Northing",NORTH],
		    AUTHORITY["EPSG","32617"]]

Contact Information
	Name: Richard Stumpf
	Organization: US DOC; NOAA; NOS; National Centers for Coastal Ocean Science
	Email: Richard.Stumpf@noaa.gov
	Role: Principal Investigator

	Name: Michelle Tomlinson
	Organization: US DOC; NOAA; NOS; National Centers for Coastal Ocean Science
	Email: Michelle.Tomlinson@noaa.gov
	Role: Collaborator


Credit
	Contains modified Copernicus Sentinel-3a data from EUMETSAT.

Usage Constraints Information
	Provisional products subject to change.

Metadata Information
	Creation date: 2019-05-17
