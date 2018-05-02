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
#install.packages("gWidgets")
#install.packages("gWidgetstcltk")
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
suppressWarnings(suppressMessages(library(tibble)))
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


# DATABASE DETAILS
DB_NAME = "test"
DB_HOST = "159.89.176.120"


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
print (paste("*** CALCULATING MAPE VALUES -  ", ifelse(CALCULATE_MAPE, "ON", "OFF"), " ***", sep = ""))
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

forecasted_sales_table = ForecastSalesA()

inventory_table = CalculatingInventories()

capacities_table = CalculatingCapacities()

# ----------------------------------------------
# OUTPUT
# ----------------------------------------------

CalculateActualDeliveries()


# ----------------------------------------------
# End Program
# ----------------------------------------------

programEndTime = Sys.time()
print(paste("Program Completed", round(programEndTime - programStartTime, digits = 2), "hours"))
print(paste("*** PROGRAM END TIME - ", programEndTime, " ***", sep = ""))