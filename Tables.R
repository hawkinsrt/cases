LoadTables = function () {
  
  startTime = Sys.time()
  
  
  print("1 - Loading Tables")
  
  
  print(" - 1.1 - Loading Scans")
  SCAN_TABLE              = read.csv(SCANS_PATH,     header = TRUE, col.names  = c("datekey", "skukey", "storekey", "categorykey", "salesunits", "monthnumberofyear", "weeknumberofyear", "monthnumberofyear", "calendardate", "sku", "skudescription", "city", "state", "zipcode", "categoryname", "brandname", "manufacturername", "groupname", "familyname", "opendate", "closedate"))
  assign("SCAN_TABLE", SCAN_TABLE, envir = globalenv())  # Send the table to the global environment (a.k.a. - make it a global variable; messy but these tables are too big to be playing around with parameter passing)
  
  
  print(" - 1.2 - Loading Shipments")
  SHIPMENTS_TABLE         = read.csv(SHIPMENTS_PATH, header = TRUE, col.names  = c("vendor", "mastervendor", "datekey", "skukey", "storekey", "vendorkey", "categorykey", "shipunits", "monthnumberofyear", "weeknumberofyear", "monthnumberofyear", "calendardate", "sku", "skudescription", "city", "state", "zipcode"))
  assign("SHIPMENTS_TABLE", SHIPMENTS_TABLE, envir = globalenv())  # Send the table to the global environment
  
  
  print(" - 1.3 - Loading Stores")
  STORE_TABLE             = read.csv(STORE_PATH,     header = TRUE, col.names  = c("storekey","clientkey","city","state","zipcode","opendate","closedate"))
  STORE_TABLE$storekey    = as.numeric(gsub(",", "", as.character(STORE_TABLE$storekey)))  # Fix a string to number problem
  assign("STORE_TABLE", STORE_TABLE, envir = globalenv())  # Send the table to the global environment
  
  
  print(" - 1.4 - Loading Dates")
  DATE_TABLE              = read.csv(DATE_PATH,     header = TRUE, col.names  = c("datekey",	"clientkey", "calendardate", "daynumberofweek", "daynameofweek", "daynumberofmonth", "daynumberofyear", "weeknumberofyear", "monthname", "monthnumberofyear", "quarternumberofyear", "calendaryear", "fiscalquarter", "fiscalyear", "fiscalweek"))
  DATE_TABLE$datekey      = as.numeric(gsub(",", "", as.character(DATE_TABLE$date)))  # Fix a string to number problem
  assign("DATE_TABLE", DATE_TABLE,envir = globalenv())  # Send the table to the global environment
  
  print(paste("Loading Tables Complete", round(Sys.time()-startTime,digits = 2), "minutes"))
}

CalculatingInventories = function(){
  
  startTime = Sys.time()
  
  
  print("2 - Calculating Inventories")
  
  
  print(" - 2.1 - Minimizing the columns in DATE_TABLE for better joining")
  date_data = select(DATE_TABLE, calendardate)
  
  
  print(" - 2.2 - Minimizing the columns in SHIPMENTS_TABLE for better joining")
  shipments_data = select(SHIPMENTS_TABLE, calendardate, storekey, sku, shipunits)
  
  
  print(" - 2.3 - Minimizing the columns in SCAN_TABLE for better joining, filter out closed stores and negative sales")
  scan_data = select(filter(SCAN_TABLE, closedate == "", salesunits > 0), calendardate, storekey, sku, salesunits)
  
  
  print(" - 2.4 - Joining SCAN_TABLE and SHIPMENTS_TABLE")
  inventory_data = suppressWarnings(full_join(shipments_data, scan_data, by = c("calendardate", "storekey", "sku")))
  
  
  print(" - 2.5 - Creating Primative Store:Sku Hash")
  inventory_data = as.data.table(mutate(inventory_data, storesku = paste(storekey, sku, sep="-")))
  storeskus = as.character(unique(paste(inventory_data$storekey, inventory_data$sku, sep="-")))
  
  
  print(" - 2.6 - Replacing NAs with zeros")
  inventory_data$shipunits[is.na(inventory_data$shipunits)]=0
  inventory_data$salesunits[is.na(inventory_data$salesunits)]=0
  
  
  # Sort the columns by Store:sku first, then by date
  print(" - 2.7 - Sort Columns")
  inventory_data = arrange(inventory_data, storesku, calendardate)
  
  
  # Add a column that calculates the change in inventory [ +/-units from shipments and -units from sales ]
  print(" - 2.8 - Calculating inventories")
  inventory_data = mutate(inventory_data, inv_change = shipunits - salesunits)
  
  
  # For each Store:sku, calculate the cumulative total of the inventory  [ cumsum(inv_change) ]
  print(" - 2.9 - Calculating inventories 2")
  inventory_data = inventory_data %>% group_by(storesku) %>% mutate(inv_current = ave(inv_change, storesku, FUN=cumsum)) 
  
  
  #print("# - Calculating shrink")
  #if (min(inventory_data$inv_current) < 0) inventory_data = mutate(inventory_data, shrinkamt = cumsum(inv_change * SHRINK_DECAY)) else inventory_data = mutate(inventory_data, shrinkamt = cumsum(inv_change * 0)) #Working on this one
  #if (min(inventory_data$inv_current) < 0) inventory_data = mutate(inventory_data, shrinkamt = 0) else inventory_data = mutate(inventory_data, shrinkamt = 0) 
  
  
  # If the inventory goes into the negative, add that number to the entire set of inventories for that store:sku to bring it out of negative - This is necessary for a poisson regression
  print(" - 2.10 - Reverse calculating starting inventories")
  inventory_data = inventory_data %>% group_by(storesku) %>% mutate(final_inventory = cumsum(inv_change)-min(inv_current))
  
  
  assign("storeskus", storeskus, envir = globalenv())  # Send the table to the global environment
  print(paste("Inventory Calculations Complete", round(Sys.time()-startTime,digits = 2), "minutes"))
  
  # Return the Output  
  inventory_data
}

CalculatingCapacities = function(){
  
  startTime = Sys.time()
  
  
  print("3 - Calculating Store Inventory Capacity")
  
  # Get only rows that have a positive shipment count
  print(" - 3.1 - Creating a Table of Only Deliveries")
  dist_table = filter(inventory_table, shipunits>0)
  
  
  # Get the average of all of the shipment dates  [ We are assuming the driver was able to bring the store up to or close to capacity each run.  So we will take the mean of the inventories after the delivery to determine the capacity ]
  print(" - 3.3 - Calculating Approximate Capacity of Each Store:Sku")
  capacities = dist_table %>% summarise(mean = mean(final_inventory))  
  
  
  print(paste("Inventories Capacity Calculations Complete", round(Sys.time()-startTime, digits = 2), "minutes / or seconds."))
  
  
  # Return the Output
  capacities
}

ForecastInventories = function(){
  
  startTime = Sys.time()
  
  
  print("4 - Forecast Inventories")
  
  print(" - 4.1 - Pre-calculating values")
  maxDate = max(as.Date(inventory_table$calendardate))  # This SHOULD be today's date, but I don't want to assume
  timeframe = as.numeric(maxDate - min(as.Date(DATE_TABLE$calendardate)))  # The number of days between max(inventory_table:date) and min(DATE_TABLE:date)
  
  
  # Reduce the number of columns in the table and sort
  print(" - 4.2 - Sorting and Selecting Inventory Table")
  inventory_table2 = inventory_table[c(1,6,8)] %>% arrange(storesku, as.Date(calendardate))
  
  
  # Creating Store:sku hash (might be copy/paste redundant)
  print(" - 4.3 - Creating Primative Store:Sku Hash")
  inventory_table2 = as.data.table(mutate(inventory_table2, storesku = paste(storesku, sep="-")))
  
  
  # Creating Pivot Table of Dates x Store:Sku x inv_current   [Might need to replace inv_current with final_inv?]
  print(" - 4.4 - Populating TS With Inventories")
  inventory_table3 = as.data.frame(dcast.data.table(ungroup(inventory_table2), c(calendardate)~c(storesku), fun.aggregate=sum, value.var="inv_current"))
  
  
  # Replace NAs with Previous Inventory Value
  print(" - 4.5 - Replacing NAs")
  for (i in 1:(dim(inventory_table3)[1]-1)) na.locf(inventory_table3[i], na.rm=FALSE, fromLast=TRUE)
  
  
  # Create Blank Table for Forecasts
  print(" - 4.6 - Creating Forecast Table Shell")
  inventory_table4 = data.frame(matrix(data = 0, ncol = 0, nrow=length(storeskus)), row.names = storeskus)
  
  
  # Perform Forecasts!  We now know what the inventory of each Store:sku will be in 2 days   [This step takes a few hours.  Might need to revisit.]
  print(" - 4.7 - Calculating Forecasts of Inventories - This step is currently taking hours to complete")
  for (i in 2:dim(inventory_table3)[2]){
    tmp = forecast(ts(inventory_table3[,i]), h=3)
    inventory_table4[i,1] = round(tmp$mean[1])
    inventory_table4[i,2] = round(tmp$mean[2])
  }
  colnames(inventory_table4) = c("Day +1", "Day +2")
  
  
  print(paste("Forecast Inventories Calculations Complete", round(Sys.time()-startTime,digits = 2), "minutes"))
  
  
  # Return the Output
  inventory_table4
}