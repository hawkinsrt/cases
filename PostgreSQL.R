suppressWarnings(suppressMessages(library(lubridate)))
suppressWarnings(suppressMessages(library(RPostgreSQL)))


LoadTablesSQL = function () {
  startTime = Sys.time()
  
  print("1 - Loading Data")
  
  # Establish driver for the Postgre Database
  print(" - 1.1 - Loading SQL drivers")
  drv = dbDriver("PostgreSQL")

  
  # Store Database connection info
  print(" - 1.2 - Connecting to database")
  con = dbConnect(drv, dbname = "test", host = "159.89.176.120", user = "student1", password = "VCUDAPT")

  
  print(" - 1.3 - Loading dates")
  DATE_TABLE = dbGetQuery(con,"SELECT calendardate FROM public.dimdate")
  assign("DATE_TABLE", DATE_TABLE, envir = globalenv())            # Send the table to the global environment (a.k.a. - make it a global variable; messy but these tables are too big to be playing around with parameter passing)
  
  
  print(" - 1.4 - Loading stores")
  STORE_TABLE = dbGetQuery(con, "SELECT storekey FROM dimstore WHERE closedate IS NOT NULL AND (DATE(NOW()) - DATE(opendate)) >= 28")
  NEW_STORE_TABLE = dbGetQuery(con, "SELECT storekey FROM dimstore WHERE closedate IS NOT NULL AND (DATE(NOW()) - DATE(opendate)) < 28")
  assign("STORE_TABLE", STORE_TABLE, envir = globalenv())          # Send the table to the global environment
  assign("NEW_STORE_TABLE", STORE_TABLE, envir = globalenv())          # Send the table to the global environment
  

  print(" - 1.5 - Loading shipments")
  SHIPMENTS_TABLE = dbGetQuery(con, "SELECT datekey, public.dimsku.skukey AS skukey, public.dimsku.sku AS sku, public.dimstore.storekey AS storekey, shipunits 
                               FROM public.factalertshipments 
                               JOIN public.dimstore ON public.factalertshipments.storekey = public.dimstore.storekey 
                               JOIN public.dimsku ON public.factalertshipments.skukey = public.dimsku.skukey
                               WHERE closedate IS NULL")
  SHIPMENTS_TABLE = SHIPMENTS_TABLE %>% mutate(calendardate = ymd(datekey))
  SHIPMENTS_TABLE = SHIPMENTS_TABLE %>% mutate(storesku = paste(storekey, sku, sep="-"))
  assign("SHIPMENTS_TABLE", SHIPMENTS_TABLE, envir = globalenv())  # Send the table to the global environment

  
  print(" - 1.6 - Loading scans")
  SCAN_TABLE = dbGetQuery(con, "SELECT datekey, public.dimstore.storekey AS storekey, public.dimsku.skukey AS skukey, public.dimsku.sku AS sku, salesunits
                          FROM public.factalertscans
                          JOIN public.dimstore ON public.factalertscans.storekey = public.dimstore.storekey
                          JOIN public.dimsku ON public.factalertscans.skukey = public.dimsku.skukey
                          WHERE closedate IS NULL")
  SCAN_TABLE = SCAN_TABLE %>% mutate(calendardate = ymd(datekey))
  SCAN_TABLE = SCAN_TABLE %>% mutate(storesku = paste(storekey, sku, sep="-"))
  assign("SCAN_TABLE", SCAN_TABLE, envir = globalenv())            # Send the table to the global environment

  
  print(" - 1.7 - Loading store:skus")
  STORE_SKU = unique(select(SHIPMENTS_TABLE, storesku, storekey, sku))
  assign("STORE_SKU", STORE_SKU, envir = globalenv())        # Send the table to the global environment

  
  print(paste("1.X - Loading Tables Complete", round(Sys.time()-startTime,digits = 2), "minutes"))
}