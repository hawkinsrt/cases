CalculatingDeliveryDates = function() {
  
  startTime = Sys.time()
  
  
  print("2 - Calculating Delivery Schedules")
  
  print(" - 2.1 - Translating dates to Day of Week")
  deliveries = SHIPMENTS_TABLE %>% arrange(storesku, calendardate) %>% mutate(dow = format(as.Date(calendardate), "%a"))

  
  print(" - 2.2 - Calculating counts and means of DoWs")
  deliveries = deliveries %>% filter(shipunits > 0, calendardate>PROCESSING_DATE-180) %>% group_by(storesku, dow) %>% summarise(n = n()) %>% mutate(mean = mean(n) - 1) %>% ungroup()
  
  
  print(" - 2.3 - Calculating delivery schedules")
  deliveries = deliveries %>% mutate(IsDeliver = (n >= mean))
  
  
  print(" - 2.4 - Calculating which stores to deliver to today")
  deliveries = filter(deliveries, dow == format(as.Date(PROCESSING_DATE + FORECAST_OFFSET), "%a"), IsDeliver == TRUE)
  assign("deliveries",    deliveries,    envir = globalenv())  # Send the table to the global environment


  print(paste("2.X - Delivery Schedules Calculations Complete", round(Sys.time() - startTime, digits = 2), ifelse(round(Sys.time()-startTime,digits = 2) < 3, "minutes", "seconds")))

  # Return the Output  
  deliveries[,1]
}


ForecastSalesA = function() {
  
  startTime = Sys.time()
  

  print("3 - Forecast Sales")
  
  print(" - 3.1 - Reducing data to only items that might be in today's forecasts")
  inventory_data = select(suppressWarnings(semi_join(SCAN_TABLE, delivery_table, by = "storesku")), calendardate, storesku, salesunits)

  
  # Creating Pivot Table of Dates x Store:Sku x inv_current
  print(" - 3.2 - Populating TS With Inventories")
  inventory_table2 = as.data.table(inventory_data)
  inventory_table2 = suppressWarnings(as.data.frame(dcast.data.table(inventory_table2, c(calendardate) ~ c(storesku), fun.aggregate = sum, fill = 0, value.var = "salesunits")))


  print(" - 3.2 - Pre-calculating date values")
  timeframe = dim(inventory_table2)[1]  # The number of days between max(inventory_table:date) and min(DATE_TABLE:date)
  training_dates = round(timeframe * 0.7)
  test_dates = timeframe - training_dates


  print(" - 3.4 - Forecasting sales")
  if (CALCULATE_MAPE){
    val_data = inventory_table2[1:training_dates,]
    val_test_data = inventory_table2[training_dates+1:timeframe,]
    val_fit = apply(val_data, training_dates, auto.arima)
    val_fcast = lapply(fit, forecast, h = test_dates)
    val_accuracy = lapply(accuracy(val_fcast, val_test_data))
  }

  inventory_table2 = ts(inventory_table2[,-1])
  fit = apply(inventory_table2, 2, auto.arima)
  fcast = lapply(fit, forecast, h = FORECAST_OFFSET)
  fcast = sapply(fcast,"[",4)
  fcast = (as.data.frame(fcast))

  
  print(" - 3.5 - Fixing store-sku formats")
  colnames(fcast) = substring(colnames(fcast),2,16)
  colnames(fcast) = substring(colnames(fcast),1,15)

  fcast2 = transpose(as.tibble(fcast))
  colnames(fcast2) = c(PROCESSING_DATE+1, PROCESSING_DATE+2, PROCESSING_DATE+3) #TODO
  fcast2$storesku = colnames(fcast) 
  substring(fcast2$storesku, 6,6) = "-"
  
  
  print(paste("3.X - Inventory Forecastings Complete", round(Sys.time() - startTime, digits = 2), ifelse(round(Sys.time()-startTime,digits = 2) < 3, "minutes", "seconds")))

  # Return the Output
  fcast2
}


CalculatingInventories = function() {
  
  startTime = Sys.time()
  

  print("4 - Calculating Inventories")

  print(" - 4.1 - Joining Adding Forecasted Sales to SCAN_TABLE")
  inventory_data = melt(forecasted_sales_table, id.vars="storesku", variable.name="calendardate", value.name="salesunits")
  inventory_data$calendardate = as.Date(inventory_data$calendardate)
  inventory_data = bind_rows(SCAN_TABLE, inventory_data)
  

  print(" - 4.2 - Joining SCAN_TABLE and SHIPMENTS_TABLE")
  inventory_data = suppressWarnings(full_join(inventory_data, SHIPMENTS_TABLE, by = c("calendardate", "storesku")))


  print(" - 4.3 - Reducing inventory to only today's deliveries")
  inventory_data = suppressWarnings(semi_join(inventory_data, delivery_table, by = "storesku"))
  
  
  print(" - 4.4 - Replacing NAs with zeros")
  inventory_data$shipunits[is.na(inventory_data$shipunits)] = 0
  inventory_data$salesunits[is.na(inventory_data$salesunits)] = 0
  
  
  # Sort the columns by Store:sku first, then by date
  print(" - 4.5 - Sort Columns")
  inventory_data = arrange(inventory_data, storesku, calendardate)
  
  
  # Add a column that calculates the change in inventory [ +/-units from shipments and -units from sales ]
  print(" - 4.6 - Calculating inventories")
  inventory_data = inventory_data %>% mutate(inv_change = shipunits - salesunits)
  
  
  # For each Store:sku, calculate the cumulative total of the inventory  [ cumsum(inv_change) ]
  print(" - 4.7 - Calculating inventories 2")
  inventory_data = inventory_data %>% group_by(storesku) %>% mutate(inv_current = ave(inv_change, storesku, FUN=cumsum)) %>% ungroup()
  
  
  # If the inventory goes into the negative, add that negative number to the entire set of inventories for that store:sku to bring it out of negative - This is necessary for a poisson regression
  print(" - 4.8 - Reverse calculating starting inventories")
  inventory_data = suppressWarnings(inventory_data %>% group_by(storesku) %>% mutate(final_inventory = cumsum(inv_change) - min(inv_current)) %>% ungroup())
#  inventory_data = suppressWarnings(inventory_data %>% group_by(storesku) %>% mutate(final_inventory = (cumsum(inv_change) - min(inv_current)) * (1-SHRINK_DECAY)) %>% ungroup())
  
  
  print(paste("4.X - Inventory Calculations Complete", round(Sys.time() - startTime,digits = 2), "minutes"))

  # Return the Output  
  inventory_data
}


CalculatingCapacities = function() {
  
  startTime = Sys.time()
  
  
  print("5 - Calculating Store Inventory Capacity")
  
  # Get only rows that have a positive shipment count
  print(" - 5.1 - Creating a Table of Only Deliveries")
  dist_table = filter(inventory_table, shipunits > 0)
  
  
  # Get the average of all of the shipment dates  [ We are assuming the driver was able to bring the store up to or close to capacity each run.  So we will take the mean of the inventories after the delivery to determine the capacity ]
  print(" - 5.2 - Calculating Approximate Capacity of Each Store:Sku")
  capacities = dist_table %>% group_by(storesku) %>% summarise(mean = mean(final_inventory))
  
  
  print(paste("5.X - Inventories Capacity Calculations Complete", round(Sys.time() - startTime, digits = 2), "seconds"))

  # Return the Output
  capacities
}


CalculateActualDeliveries = function() {
  
  startTime = Sys.time()
  

  print("6 - Calculating Final Inventories")

  print(" - 6.1 - Combining forecasts with store capacities")
  inventory_table6 = inventory_table %>% left_join(capacities_table, by = "storesku")
  inventory_table6 = inventory_table6 %>% group_by(storesku) %>% filter(calendardate == max(calendardate))

  
  print(" - 6.2 - Calculating quantities")
  inventory_table6 = inventory_table6 %>% group_by(storesku) %>% mutate(Quantity = round(as.numeric(mean) - as.numeric(final_inventory),0)) 

  
  print(" - 6.3 - Seperating Store:skus")
  inventory_table6 = separate(inventory_table6, storesku, into=c("Store", "Sku"), sep="-")


  print(" - 6.4 - Choosing approperate columns for output")
  if (CALCULATE_MAPE) {
    inventory_table6 = inventory_table6 %>% select(Store, Sku, Quantity, MAPE, 'Size of Test') %>% filter(Quantity > 0)
  }  else {
    inventory_table6 = inventory_table6 %>% select(Store, Sku, Quantity) %>% filter(Quantity > 0)
  }

  
  print(" - 6.5 - Creating Output File")
  write.csv(inventory_table6, "dsd Output.csv")
  

  print(paste("6.X - Final Inventory Calculations Complete", round(Sys.time()-startTime,digits = 2), "minutes"))
}