CalculatingDeliveryDates = function() {
  
  startTime = Sys.time()
  
  
  print("2 - Calculating Delivery Schedules")
  
  print(" - 2.1 - Translating dates to Day of Week")
  deliveries = SHIPMENTS_TABLE %>% mutate(dow = format(as.Date(calendardate), "%a"))
  
  
  print(" - 2.2 - Calculating counts and means of DoWs")
  deliveries2 = deliveries %>% group_by(storesku, dow) %>% summarise(n = n()) %>% mutate(mean = mean(n)) %>% ungroup()
  
  
  print(" - 2.3 - Calculating delivery schedules")
  deliveries2 = deliveries2 %>% mutate(IsDeliver = (n >= mean))
  
  
  print(" - 2.4 - Calculating which stores to deliver to today")
  deliveries2 = filter(deliveries2, dow == format(as.Date(PROCESSING_DATE + FORECAST_OFFSET), "%a"), IsDeliver == TRUE)
  assign("deliveries",    deliveries,    envir = globalenv())  # Send the table to the global environment

    
  print(paste("2.X - Delivery Schedules Calculations Complete", round(Sys.time() - startTime, digits = 2), ifelse(round(Sys.time()-startTime,digits = 2) < 3, "minutes", "seconds")))

  # Return the Output  
  deliveries2[,1]
}


CalculatingInventories = function() {
  
  startTime = Sys.time()
  
  
  print("3 - Calculating Inventories")
  
  # TODO - Make the SQL server do this join
  print(" - 3.1 - Joining SCAN_TABLE and SHIPMENTS_TABLE")
  inventory_data = suppressWarnings(full_join(SHIPMENTS_TABLE, SCAN_TABLE,
                                    by = c("calendardate", "storekey", "sku", "datekey", "storesku", "skukey")))
                                    # The last three joins above are not functionally necessary, but it prevents duplicate columns from being created by R
  

  print(" - 3.2 - Reducing inventory to only today's deliveries")
  inventory_data = suppressWarnings(semi_join(inventory_data, delivery_table, by = "storesku"))

  
  #print(" - 3.3 - Creating Primative Store:Sku Hash")
  #inventory_data = as.data.table(mutate(inventory_data, storesku = paste(storekey, sku, sep = "-")))

  
  print(" - 3.3 - Replacing NAs with zeros")
  inventory_data$shipunits[is.na(inventory_data$shipunits)] = 0
  inventory_data$salesunits[is.na(inventory_data$salesunits)] = 0
  
  
  # Sort the columns by Store:sku first, then by date
  print(" - 3.4 - Sort Columns")
  inventory_data = arrange(inventory_data, storesku, calendardate)

  
  # Add a column that calculates the change in inventory [ +/-units from shipments and -units from sales ]
  print(" - 3.5 - Calculating inventories")
  inventory_data = inventory_data %>%  mutate(inv_change = shipunits - salesunits)

  
  # For each Store:sku, calculate the cumulative total of the inventory  [ cumsum(inv_change) ]
  print(" - 3.6 - Calculating inventories 2")
  inventory_data = inventory_data %>% group_by(storesku) %>% mutate(inv_current = ave(inv_change, storesku, FUN=cumsum)) %>% ungroup()

  
  # Might need to be done at a different point in the process?
  #print("# - Calculating shrink")   
  #if (min(inventory_data$inv_current) < 0) inventory_data = mutate(inventory_data, shrinkamt = cumsum(inv_change * SHRINK_DECAY)) else inventory_data = mutate(inventory_data, shrinkamt = cumsum(inv_change * 0)) #Working on this one
  #if (min(inventory_data$inv_current) < 0) inventory_data = mutate(inventory_data, shrinkamt = 0) else inventory_data = mutate(inventory_data, shrinkamt = 0) 

    
  # If the inventory goes into the negative, add that negative number to the entire set of inventories for that store:sku to bring it out of negative - This is necessary for a poisson regression
  print(" - 3.7 - Reverse calculating starting inventories")
  inventory_data = inventory_data %>% group_by(storesku) %>% mutate(final_inventory = cumsum(inv_change) - min(inv_current)) %>% ungroup()
  
  
  print(paste("3.X - Inventory Calculations Complete", round(Sys.time() - startTime,digits = 2), "minutes"))
  
  # Return the Output  
  inventory_data
}


CalculatingCapacities = function() {
  
  startTime = Sys.time()
  
  
  print("4 - Calculating Store Inventory Capacity")
  
  # Get only rows that have a positive shipment count
  print(" - 4.1 - Creating a Table of Only Deliveries")
  dist_table = filter(inventory_table, shipunits > 0)
  
  
  # Get the average of all of the shipment dates  [ We are assuming the driver was able to bring the store up to or close to capacity each run.  So we will take the mean of the inventories after the delivery to determine the capacity ]
  print(" - 4.2 - Calculating Approximate Capacity of Each Store:Sku")
  capacities = dist_table %>% group_by(storesku) %>% summarise(mean = mean(final_inventory))
  
  
  print(paste("4.X - Inventories Capacity Calculations Complete", round(Sys.time() - startTime, digits = 2), "seconds"))
  
  
  # Return the Output
  capacities
}


ForecastInventoriesA = function() {
  
  startTime = Sys.time()
  
  
  print("5 - Forecast Inventories")
  
  print(" - 5.1 - Pre-calculating values")
  timeframe = as.numeric(PROCESSING_DATE - min(as.Date(DATE_TABLE$calendardate)))  # The number of days between max(inventory_table:date) and min(DATE_TABLE:date)
  
  
  # Reduce the number of columns in the table and sort
  print(" - 5.2 - Sorting and Selecting Inventory Table")
  inventory_table2 = inventory_table[c('calendardate', 'storesku', 'final_inventory')] %>% arrange(storesku, as.Date(calendardate))

  
  # Calculate time series ranges
  # I'm using ceiling and floor because 2 rounds with 0.5s will both round up
  print(" - 5.3 - Sorting and Selecting Inventory Table")
  ts_ranges = inventory_table %>% group_by(storesku) %>% summarise(mindate = min(calendardate), maxdate = max(calendardate)) %>% mutate(datediff = maxdate - mindate, trainr = ceiling(datediff * 0.7), testr = floor(datediff * 0.3), splitdate = mindate + trainr) %>% ungroup()
  assign("ts_ranges",    ts_ranges,    envir = globalenv())  # Send the table to the global environment

  # Creating Store:sku hash (might be copy/paste redundant)
  print(" - 5.4 - Creating Primative Store:Sku Hash")
  inventory_table2 = as.data.table(mutate(inventory_table2, storesku = paste(storesku, sep="-")))
  
  
  # Creating Pivot Table of Dates x Store:Sku x inv_current   [Might need to replace inv_current with final_inv?]
  print(" - 5.5 - Populating TS With Inventories")
  inventory_table2 = suppressWarnings(as.data.frame(dcast.data.table(inventory_table2, c(calendardate) ~ c(storesku), fun.aggregate = sum, fill = NA, value.var = "final_inventory")))

  
  print(paste("5.X - Inventory Forecastings Complete", round(Sys.time() - startTime, digits = 2), ifelse(round(Sys.time()-startTime,digits = 2) < 3, "minutes", "seconds")))
  
  # Return the Output
  inventory_table2
}


ForecastInventoriesB = function(){
    
  startTime = Sys.time()

  
  print("6 - Forecast Inventories")
  
  # Create Blank Table for Forecasts
  print(" - 6.1 - Creating Forecast Table Shell")
  if (CALCULATE_MAPE) {
    inventory_table4 = data.frame(matrix(data = 0, ncol = dim(preforecast_table)[2], nrow = 3), row.names = c(paste("Day +", FORECAST_OFFSET, sep = ""), "MAPE", "Size of Test"))
  }
  else {
    inventory_table4 = data.frame(matrix(data = 0, ncol = dim(preforecast_table)[2], nrow = 1), row.names = c(paste("Day +", FORECAST_OFFSET, sep = "")))
  }
  
  # Perform Forecasts!  We now know what the inventory of each Store:sku will be in 2 days
  print(" - 6.2 - Calculating Forecasts of Inventories")
  print(Sys.time())
  for (i in 2:dim(preforecast_table)[2]) {
    if (i %% 10000 == 0){
      print(paste(i, " out of ", dim(preforecast_table)[2], " forecasts complete.", sep=""))
    }

    training_data = preforecast_table[1:as.numeric(ts_ranges[i-1, "trainr"]), 2]
    test_data = preforecast_table[as.numeric(ts_ranges[i-1, "trainr"]+1):as.numeric(ts_ranges[i-1, "datediff"]), 2]
    full_data = preforecast_table[1:as.numeric(ts_ranges[i-1, "datediff"]), 2]

    if (ts_ranges[i-1, "datediff"] >= 60 && sum(!is.na(test_data)) > 1 && sum(!is.na(training_data)) > 1) {
      training_data = tsclean(training_data)
      test_data = tsclean(test_data)
      full_data = tsclean(full_data)

      # Record Forecasted Values
      forecast_tmp = forecast(auto.arima(full_data), h = FORECAST_OFFSET + 1)
      inventory_table4[1, i - 1] = forecast_tmp$mean[FORECAST_OFFSET]
      
      if (CALCULATE_MAPE) {
        # Record Test Values
        forecast_tmp = forecast(auto.arima(training_data), h = as.numeric(ts_ranges[i-1, "testr"]))
        forecast_tmp = as.numeric(forecast_tmp$mean)
  
        inventory_table4[2, i-1] = 100 * mean(abs((as.numeric(forecast_tmp) - test_data) / test_data))
        
        # Record Forecasted Values
        inventory_table4[3, i-1] = ts_ranges[i-1, "testr"]
      }
    }
    else {
      inventory_table4[1, i-1] = "Not enough data to create forecasts.  Manual calculation required."
      if (CALCULATE_MAPE) {
        inventory_table4[2, i-1] = NA
        inventory_table4[3, i-1] = NA
      }
    }
  }

  colnames(inventory_table4) = colnames(preforecast_table)[2:dim(inventory_table4)[2]]
  print(Sys.time())
  
  # Return the Output
  inventory_table4
  
  print(paste("6.X - Inventory Forecastings Complete", round(Sys.time() - startTime,digits = 2), "minutes"))
}


CalculateActualDeliveries = function() {
  
  startTime = Sys.time()
  
  
  print("7 - Calculating Final Inventories")
  
  print(" - 7. - ")

  print(" - 7. - ")
  
  
  print(" - 7. - ")
  
  
  print(" - 7. - ")
  
  
  print(" - 7. - ")
  
  
  print(" - 7. - ")
  
  
  print(paste("Final Inventory Calculations Complete", round(Sys.time()-startTime,digits = 2), "hours"))
  
  # Return the Output
  output_table
}