# ----------------------------------------------
# FILE LOCATIONS
# ----------------------------------------------

print("Loading Constants")


# File/Dir Names

INPUT_FILE_DIR   = "C:/Users/user/Desktop/SchoolWork/Semester 2/Cases/Data/Raw Data/"
OUTPUT_FILE_DIR  = "C:/Users/user/Desktop/SchoolWork/Semester 2/Cases/"
OUTPUT_FILENAME  = "Cases - Final Project - Group 6.pdf"
FULL_OUTPUT_PATH = paste(OUTPUT_FILE_DIR, OUTPUT_FILENAME, sep="")


# Moved file directories to top for easier line of sight for users

SCANS_FN         = "factalertscans.csv"
SHIPMENTS_FN     = "factalertshipments.csv"
STORE_FN         = "dimstore.csv"
DATE_FN          = "dimdate.csv"


# Paths

SCANS_PATH       = paste(INPUT_FILE_DIR,  SCANS_FN,        sep="")
SHIPMENTS_PATH   = paste(INPUT_FILE_DIR,  SHIPMENTS_FN,    sep="")
STORE_PATH       = paste(INPUT_FILE_DIR,  STORE_FN,        sep="")
DATE_PATH        = paste(INPUT_FILE_DIR,  DATE_FN,        sep="")


# Other Settings

# SHRINK_DECAY = 0.10  # Does not work yet.


print("Loading Constants Complete")