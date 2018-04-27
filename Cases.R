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

#set working directory to Poject Directory first

source("cfg.r")
source("Tables.r")
source("PostgreSQL.r")

print("Loading Libraries Complete")

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

# TODO - Change from Forecast() to Arima()...Forecast is probably using Arima, so doing that last

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

SCAN_TEST = filter(SCAN_TABLE, storekey=="10871" | storekey=="11490" | storekey=="10858", sku=="111000407" | sku=="111000120" | sku=="110025966")
SHIPMENT_TEST = filter(SHIPMENTS_TABLE, storekey=="10871" | storekey=="11490" | storekey=="10858", sku=="111000407" | sku=="111000120" | sku=="110025966")
LEFT_TEST = suppressWarnings(left_join(SHIPMENT_TEST, SCAN_TEST, by = c("calendardate", "storekey", "sku", "datekey", "skukey", "storesku")))
RIGHT_TEST = suppressWarnings(right_join(SHIPMENT_TEST, SCAN_TEST, by = c("calendardate", "storekey", "sku", "datekey", "skukey", "storesku")))
ANTI_TEST = suppressWarnings(anti_join(SHIPMENT_TEST, SCAN_TEST, by = c("calendardate", "storekey", "sku", "datekey", "skukey", "storesku")))

SCAN_TEST = arrange(SCAN_TEST, storesku, calendardate)
SHIPMENT_TEST = arrange(SHIPMENT_TEST, storesku, calendardate)
LEFT_TEST = arrange(LEFT_TEST, storesku, calendardate)
RIGHT_TEST = arrange(RIGHT_TEST, storesku, calendardate)
ANTI_TEST = arrange(ANTI_TEST, storesku, calendardate)


head(SCAN_TEST)
head(SHIPMENT_TEST)
