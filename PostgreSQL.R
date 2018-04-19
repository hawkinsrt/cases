suppressWarnings(suppressMessages(library(RPostgreSQL))) 

# Establish driver for the Postgre Database
drv <- dbDriver("PostgreSQL")

# Store Database connection info
con <- dbConnect(drv, dbname = "test",
                 host = "159.89.176.120",
                 user = "student1", password = "VCUDAPT")

DATE_TABLE <- dbGetQuery(con,"SELECT datekey, clientkey, calendardate, daynumberofweek, daynameofweek, weeknumberofyear, monthname
                              FROM public.dimdate")

STORE_TABLE <- dbGetQuery(con, "SELECT storekey, clientkey, opendate, closedate
                                FROM public.dimstore")

SHIPMENTS_TABLE <- dbGetQuery(con, "SELECT datekey, skukey, storekey, vendorkey,  shipunits
                                    FROM public.factalertshipments")

SCAN_TABLE <- dbGetQuery(con, "SELECT datekey, storekey, skukey, salesunits
                               FROM public.factalertscans")
