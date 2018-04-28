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
print(paste("*** PROGRAM START TIME - ", programStartTime, " ***", sep = ""))


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


source("PostgreSQL.r")
source("Tables.r")

print("Loading Libraries Complete")


# ----------------------------------------------
# Program Settings
# ----------------------------------------------
print("Loading Program Settings")

# PROCESSING DATE OF THE RUN
PROCESSING_DATE = as.Date("2018-01-23")
# PROCESSING_DATE = today()


# THE NUMBER OF DAYS OUT TO FORECAST
FORECAST_OFFSET = 2


# SHOULD THE JOB CALCULATE MAPE VALUES?
CALCULATE_MAPE = FALSE


# SHRINK DECAY MODIFIER
# Shrink decay does not work yet.
# Furthermore, a different system should be probably used where there is a differnt modifier for each sku
# SHRINK_DECAY = 0.10


# Set the working directory
wd = getwd()
if (!is.null(wd)) setwd(wd)


# Display settings for user
print("")
print (paste("*** PROCESSING DATE - ", format(PROCESSING_DATE, "%A, %B %d, %Y"), " ***", sep = ""))
print (paste("*** FORECASTING DATE -  ", format(PROCESSING_DATE + FORECAST_OFFSET, "%A, %B %d, %Y"), " ***", sep = ""))
if (CALCULATE_MAPE) {
  print ("*** CALCULATING MAPE VALUES - ON ***")
} else {
  print ("*** CALCULATING MAPE VALUES - OFF ***")
}
# print (paste("*** CALCULATING MAPE VALUES -  ", ifelse(CALCULATE_MAPE, "ON", "OFF"), " ***", sep = ""))
print ("")
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

inventory_table = CalculatingInventories()

capacities_table = CalculatingCapacities()

preforecast_table = ForecastInventoriesA()

forecast_table = ForecastInventoriesB()

#output_table = CalculateActualDeliveries()

# ----------------------------------------------
# OUTPUT
# ----------------------------------------------

# TODO - Create Outputs


programEndTime = Sys.time()
print(paste("Program Completed", round(programEndTime - programStartTime, digits = 2), "hours"))
print(paste("*** PROGRAM END TIME - ", programEndTime, " ***", sep = ""))

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

inventory_data2 [30:40,]
inventory_data2 [5180:5200,] %>%  mutate(inv_change = shipunits - salesunits)
inventory_data2 [5180:5200,]
glimpse(inventory_data)
