# ----------------------------------------------
# VCU - DAPT Class of 2019
#
# Group 6 - Data Pirates
#
# Michael Behrend
# Chelsea Drake
# Ryan Hawkins
# Kavitha Narayanan
# Mary Beth Nolan
# ----------------------------------------------


# ----------------------------------------------
# Reset Environment
# ----------------------------------------------
rm(list=ls())
programStartTime = Sys.time()
print(paste("Program Start Time", programStartTime))


# ----------------------------------------------
# Package Installers
# ----------------------------------------------

#install.packages("bindrcpp")
#install.packages("data.table")
#install.packages("dplyr")
#install.packages("fpp2")
#install.packages("tidyr")
#install.packages("xts")
#install.packages("zoo")


# ----------------------------------------------
# File Locations/Configuration
# ----------------------------------------------

print("Loading Libraries")

suppressWarnings(suppressMessages(library(bindrcpp)))
suppressWarnings(suppressMessages(library(data.table)))
suppressWarnings(suppressMessages(library(fpp2)))
suppressWarnings(suppressMessages(library(tidyr)))
suppressWarnings(suppressMessages(library(xts)))
suppressWarnings(suppressMessages(library(zoo)))
suppressWarnings(suppressMessages(library(dplyr)))        # dplyr MUST be the last library listed!!!!


source("Tables.r")
source("PostgreSQL.r")

print("Loading Libraries Complete")


# ----------------------------------------------
# Program Settings
# ----------------------------------------------
print("Loading Program Settings")


# The processing date of the run
PROCESSING_DATE = as.Date("2018-01-23")
# PROCESSING_DATE = today()
print (paste("The processing date of this run is ", format(PROCESSING_DATE, "%A, %B %d, %Y"), sep=""))


# The number of days out to forecast
FORECAST_OFFSET = 2
print (paste("The forecasting date of this run is ", format(PROCESSING_DATE + FORECAST_OFFSET, "%A, %B %d, %Y"), sep=""))


# The shrink decay modifier
# Shrink decay does not work yet.
# Furthermore, a different system should be used where there is a differnt modifier for each sku
# SHRINK_DECAY = 0.10


# Set the working directory
wd = getwd()
if (!is.null(wd)) setwd(wd)


print("Loading Program Settings Complete")


# ----------------------------------------------
# Begin Working with the Data
# ----------------------------------------------

# ----------------------------------------------
# INPUT
# ----------------------------------------------

# Create table variables for global use (not typically reccommended, but these are huge objects)

LoadTablesSQL()

# ----------------------------------------------
# PROCESSING
# ----------------------------------------------

delivery_table = CalculatingDeliveryDates()

capacities_table = CalculatingCapacities()

inventory_table = CalculatingInventories()

preforecast_table = ForecastInventoriesA()

forecast_table = ForecastInventoriesB()

#output_table = CalculateActualDeliveries()

# ----------------------------------------------
# OUTPUT
# ----------------------------------------------

# TODO - Create Outputs



print(paste("Program Completed", round(Sys.time()-programStartTime,digits = 2), "minutes"))

stop("[NOT AN ERROR] - End of proven code")



# ----------------------------------------------
# STOP HERE
# Anything below here is not finished work and is just for testing
# ----------------------------------------------

INVENTORY_TEST = filter(inventory_data, storekey=="10871" | storekey=="11490" | storekey=="10858", sku=="111000407" | sku=="111000120" | sku=="110025966")
INVENTORY_TEST [,10:20]


SCAN_TEST = filter(SCAN_TABLE, storekey=="10871" | storekey=="11490" | storekey=="10858", sku=="111000407" | sku=="111000120" | sku=="110025966")
SHIPMENT_TEST = filter(SHIPMENTS_TABLE, storekey=="10871" | storekey=="11490" | storekey=="10858", sku=="111000407" | sku=="111000120" | sku=="110025966")
SCAN_TEST [,10:20]
SHIPMENT_TEST [,10:20]