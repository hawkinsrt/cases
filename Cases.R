# ----------------------------------------------
# VCU - DAPT Class of 2019
#
# Michael Behrend
# Chelsea Drake
# Ryan Hawkins
# Mary Beth Nolan
# Kavitha Narayanan
# ----------------------------------------------

# ----------------------------------------------
# Reset Environment
# ----------------------------------------------
rm(list=ls())

# ----------------------------------------------
# Package Installers
# ----------------------------------------------

#install.packages("data.table")
#install.packages("dplyr")
#install.packages("fpp2")

# ----------------------------------------------
# File Locations/Configuration
# ----------------------------------------------

print("Loading Libraries")

suppressWarnings(suppressMessages(library(bindrcpp)))
suppressWarnings(suppressMessages(library(zoo)))
suppressWarnings(suppressMessages(library(tidyr)))
suppressWarnings(suppressMessages(library(data.table)))
suppressWarnings(suppressMessages(library(fpp2)))
suppressWarnings(suppressMessages(library(dplyr)))        # dplyr MUST be the last library listed!!!!

source("C:/Users/user/Desktop/SchoolWork/Semester 2/Cases/cfg.r")
source("C:/Users/user/Desktop/SchoolWork/Semester 2/Cases/Tables.r")

print("Loading Libraries Complete")

# ----------------------------------------------
# Begin Working with the Data
# ----------------------------------------------

# ----------------------------------------------
# INPUTS
# ----------------------------------------------

# Create table variables for global use (not typically reccommended, but these are huge objects)

LoadTables()

# ----------------------------------------------
# PROCESSING
# ----------------------------------------------

inventory_table = CalculatingInventories()

forecast_table = ForecastInventories()

# More TODO

# ----------------------------------------------
# OUTPUT
# ----------------------------------------------

# TODO

stop("[NOT AN ERROR] - End of proven code")

# ----------------------------------------------
# STOP HERE
# Anything below here is not finished work and is just for testing
# ----------------------------------------------

test_table = filter(inventory_table, storekey=="10858" | storekey=="11490", sku=="110025966"|sku=="111001662")

maxDate = max(as.Date(test_table$calendardate))

timeframe = as.numeric(maxDate - min(as.Date(DATE_TABLE$calendardate)))

storeskus = as.character(unique(paste(test_table$storekey, test_table$sku, sep="-")))

test_table2 = test_table[c(1:3,7)] %>% arrange(storekey, sku, as.Date(calendardate))

test_table2 = as.data.table(mutate(test_table2, storesku = paste(storekey, sku, sep="-")))

test_table3 = as.data.frame(dcast.data.table(ungroup(test_table2), c(calendardate)~c(storesku), fun.aggregate=sum,value.var="inv_current"))

for (i in 1:(dim(test_table3)[1]-1))  for (ii in 1:dim(test_table3)[2])  if (is.na(test_table3[i+1,ii]))  test_table3[i+1,ii] = unlist(test_table3[i,ii])



for (i in 1:(dim(inventory_table3)[1]))  na.locf(inventory_table3[i], na.rm=FALSE, fromLast=TRUE)

    if (is.na(inventory_table3[i+1,ii])) inventory_table3[i+1,ii] = unlist(inventory_table3[i,ii])

na.locf(inventory_table3, na.rm=FALSE, fromLast=TRUE)


