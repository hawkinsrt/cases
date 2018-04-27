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

test_table = filter(inventory_table, storekey=="10871" | storekey=="11490" | storekey=="10858", sku=="111000407" | sku=="111000120" | sku=="110025966")