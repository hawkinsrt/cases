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

# ----------------------------------------------
# Package Installers
# ----------------------------------------------

#install.packages("bindrcpp")
#install.packages("data.table")
#install.packages("dplyr")
#install.packages("fpp2")
#install.packages("tidyr")
#install.packages("zoo")

# ----------------------------------------------
# File Locations/Configuration
# ----------------------------------------------

print("Loading Libraries")

suppressWarnings(suppressMessages(library(bindrcpp)))
suppressWarnings(suppressMessages(library(data.table)))
suppressWarnings(suppressMessages(library(fpp2)))
suppressWarnings(suppressMessages(library(tidyr)))
suppressWarnings(suppressMessages(library(zoo)))
suppressWarnings(suppressMessages(library(dplyr)))        # dplyr MUST be the last library listed!!!!

source("C:/Users/user/Desktop/SchoolWork/Semester 2/Cases/cfg.r")
source("C:/Users/user/Desktop/SchoolWork/Semester 2/Cases/Tables.r")

print("Loading Libraries Complete")

# ----------------------------------------------
# Begin Working with the Data
# ----------------------------------------------

# ----------------------------------------------
# INPUT
# ----------------------------------------------

# Create table variables for global use (not typically reccommended, but these are huge objects)

LoadTables()

# ----------------------------------------------
# PROCESSING
# ----------------------------------------------

inventory_table = CalculatingInventories()

capacities_table = CalculatingCapacities()

# TODO - Calculate next delivery date for each store

forecast_table = ForecastInventories()

# TODO - Find Differnces from the forecasted inventories and Invetory Peaks

# ----------------------------------------------
# OUTPUT
# ----------------------------------------------

# TODO - Create Outputs




stop("[NOT AN ERROR] - End of proven code")



# ----------------------------------------------
# STOP HERE
# Anything below here is not finished work and is just for testing
# ----------------------------------------------