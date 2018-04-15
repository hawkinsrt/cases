LoadTables = function () {
  
  startTime = Sys.time()

    
  print("1 - Loading Tables")

    
  print(" - 1.1 - Loading Scans")
  SCAN_TABLE              = read.csv(SCANS_PATH,     header = TRUE, col.names  = c("datekey", "skukey", "storekey", "categorykey", "salesunits", "monthnumberofyear", "weeknumberofyear", "monthnumberofyear", "calendardate", "sku", "skudescription", "city", "state", "zipcode", "categoryname", "brandname", "manufacturername", "groupname", "familyname", "opendate", "closedate"))
  assign("SCAN_TABLE", SCAN_TABLE, envir = globalenv())

    
  print(" - 1.2 - Loading Shipments")
  SHIPMENTS_TABLE         = read.csv(SHIPMENTS_PATH, header = TRUE, col.names  = c("vendor", "mastervendor", "datekey", "skukey", "storekey", "vendorkey", "categorykey", "shipunits", "monthnumberofyear", "weeknumberofyear", "monthnumberofyear", "calendardate", "sku", "skudescription", "city", "state", "zipcode"))
  assign("SHIPMENTS_TABLE", SHIPMENTS_TABLE, envir = globalenv())
  
  
  print(" - 1.3 - Loading Stores")
  STORE_TABLE             = read.csv(STORE_PATH,     header = TRUE, col.names  = c("storekey","clientkey","city","state","zipcode","opendate","closedate"))
  STORE_TABLE$storekey    = as.numeric(gsub(",", "", as.character(STORE_TABLE$storekey)))
  assign("STORE_TABLE", STORE_TABLE, envir = globalenv())

  
  print(" - 1.4 - Loading Dates")
  DATE_TABLE              = read.csv(DATE_PATH,     header = TRUE, col.names  = c("datekey",	"clientkey", "calendardate", "daynumberofweek", "daynameofweek", "daynumberofmonth", "daynumberofyear", "weeknumberofyear", "monthname", "monthnumberofyear", "quarternumberofyear", "calendaryear", "fiscalquarter", "fiscalyear", "fiscalweek"))
  DATE_TABLE$datekey    = as.numeric(gsub(",", "", as.character(DATE_TABLE$date)))
  assign("DATE_TABLE", DATE_TABLE,envir = globalenv())

  
  print(paste("Loading Tables Complete", round(Sys.time()-startTime,digits = 2), "minutes"))
}

CalculatingInventories = function(){

  startTime = Sys.time()

    
  print("2 - Calculating Inventories")
  
  
  # Minimizing the columns in DATE_TABLE for better joining
  print(" - 2.1 - Minimizing the columns in DATE_TABLE for better joining")
  date_data = select(DATE_TABLE, calendardate)

  
  # Minimizing the columns in SHIPMENTS_TABLE for better joining
  print(" - 2.2 - Minimizing the columns in SHIPMENTS_TABLE for better joining")
  shipments_data = select(SHIPMENTS_TABLE, calendardate, storekey, sku, shipunits)
  

  # Minimize the columns in SCAN_TABLE and filter out closed stores -- Ignore Scans with negative sales as per DSD
  print(" - 2.3 - Minimizing the columns in SCAN_TABLE for better joining, filter out closed stores and negative sales")
  scan_data = select(filter(SCAN_TABLE, closedate == "", salesunits > 0), calendardate, storekey, sku, salesunits)
  
  
  print(" - 2.4 - Joining SCAN_TABLE and SHIPMENTS_TABLE")
  inventory_data = suppressWarnings(full_join(shipments_data, scan_data, by = c("calendardate", "storekey", "sku")))
  

  print(" - 2.5 - Replacing NAs with zeros")
  inventory_data$shipunits[is.na(inventory_data$shipunits)]=0
  inventory_data$salesunits[is.na(inventory_data$salesunits)]=0


  print(" - 2.6 - Sort Columns")
  inventory_data = arrange(inventory_data, storekey, sku, calendardate)
  
  
  print(" - 2.7 - Calculating inventories")
  inventory_data = mutate(inventory_data, inv_change = shipunits - salesunits)

  
  print(" - 2.8 - Calculating inventories 2")
  inventory_data2 = inventory_data %>% group_by(storekey, sku) %>% mutate(inv_current = ave(inv_change, storekey, sku, FUN=cumsum))

  
  #print("# - Calculating shrink")
  #if (min(inventory_data$inv_current) < 0) inventory_data = mutate(inventory_data, shrinkamt = cumsum(inv_change * SHRINK_DECAY)) else inventory_data = mutate(inventory_data, shrinkamt = cumsum(inv_change * 0)) #Working on this one
  #if (min(inventory_data$inv_current) < 0) inventory_data = mutate(inventory_data, shrinkamt = 0) else inventory_data = mutate(inventory_data, shrinkamt = 0) 

  
  #print("# - Reverse calculating starting inventories")
  #if (min(inventory_data$inv_current) < 0) inventory_data = inventory_data %>% group_by(storekey, sku) %>% mutate(final_inventory = cumsum(inv_change)-min(inv_current)) else inventory_data = inventory_data %>% group_by(storekey, sku) %>% mutate(final_inventory = 0)
  

  print(" - 2.9 - Cleaning Up")

  print(paste("Inventory Calculations Complete", round(Sys.time()-startTime,digits = 2), "minutes"))

  
  # Return the Output  
  inventory_data2
}


ForecastInventories = function(){
  
  startTime = Sys.time()

  
  print("3 - Forecast Inventories")
  round(Sys.time()-startTime,digits = 2)
  maxDate = max(as.Date(inventory_table$calendardate))
  timeframe = as.numeric(maxDate - min(as.Date(DATE_TABLE$calendardate)))
  
                         
  print(" - 3.1 - Creating SKU List")
  round(Sys.time()-startTime,digits = 2)
  storeskus = as.character(unique(paste(inventory_table$storekey, inventory_table$sku, sep="-")))


  print(" - 3.2 - Sorting and Selecting Inventory Table")
  round(Sys.time()-startTime,digits = 2)
  inventory_table2 = inventory_table[c(1:3,7)] %>% arrange(storekey, sku, as.Date(calendardate))
  
  
  print(" - 3.3 - Creating Primative Store:Sku Hash")
  round(Sys.time()-startTime,digits = 2)
  inventory_table2 = as.data.table(mutate(inventory_table2, storesku = paste(storekey, sku, sep="-")))

  
  print(" - 3.4 - Populating TS With Inventories")
  round(Sys.time()-startTime,digits = 2)
  inventory_table3 = as.data.frame(dcast.data.table(ungroup(inventory_table2), c(calendardate)~c(storesku), fun.aggregate=sum,value.var="inv_current"))


  print(" - 3.5 - Replacing NAs")
  round(Sys.time()-startTime,digits = 2)
  for (i in 1:(dim(inventory_table3)[1]-1)) na.locf(inventory_table3[i], na.rm=FALSE, fromLast=TRUE)

  
  print(" - 3.6 - Creating Forecast Table Shell")
  round(Sys.time()-startTime,digits = 2)
  inventory_table4 = data.frame(matrix(data = 0, ncol = 0, nrow=length(storeskus)), row.names = storeskus)

    
  print(" - 3.7 - Calculating Forecasts of Inventories")
  for (i in 1:dim(inventory_table3)[2]){
    tmp = forecast(ts(inventory_table3[,i]), h=3)
    inventory_table4[i,1] = round(tmp$mean[1])
    inventory_table4[i,2] = round(tmp$mean[2])
  }
  colnames(inventory_table4) = c("Day +1", "Day +2")

    
  print(paste("Forecast Inventories Calculations Complete", round(Sys.time()-startTime,digits = 2), "minutes"))

  
  # Return the Output
  inventory_table4
}


