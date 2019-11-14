# --------------------------------------------------------------------------------------------
# Name: surveySolutions.R
# Purpose: Import survey data from Survey Solutions website and unzip them to local drive 
# Author:	Roshan Adhikari
# Created:	2019-08-06
# Notes: You will need to first create an R API user in Administrator. Instructions can be  
# found on this link: https://rstudio-pubs-static.s3.amazonaws.com/239851_1bc298ae651c41c7a65e09ce82f9053f.html
#---------------------------------------------------------------------------------------------
library(xml2)
library(jsonlite)
library(httr)
library(dplyr)
### Specify Surveysolutions parameters for data import ---------------------------------------
headquarters <- "headquarters" # This is your survey solutions homepage 
export_type <- "tabular" #Format of your data you want to export
user <- "username"  #API user in server
password <- "password" #API password in server 

### Specify path where data will be stored ---------------------------------------------------
download_folder <- file.path("./Data/Raw")

### Check connection to server ---------------------------------------------------------------
# This gives the list of questionnaires and their ids
queryInfo <- sprintf("%s/api/v1/questionnaires",headquarters) 
InfoServer <- GET(queryInfo, authenticate(user, password)) #successful
http_type(InfoServer) # check format of content 
fromJSON(content(InfoServer, as = "text")) #read content in text format

### Extract data from the server -----------------------------------------------------------
# Extract questionnaire elements from the server
ListOfQn.df <- content(InfoServer)$Questionnaires %>% 
  bind_rows %>% 
  select(Title, Version, QuestionnaireIdentity)
View(ListOfQn.df)

fullimport<- function(i)
{
  # Fetch data from the specific version of the questionnaire you want
  myquestionnare <- ListOfQn.df %>% filter(Title == "Title of Questionnaire", Version == i)
  qn_Id <- myquestionnare$QuestionnaireIdentity
  
  # Preparing an export file in the server
  queryGenerate <- sprintf("%s/api/v1/export/%s/%s/start", headquarters,
                           export_type,qn_Id)
  queryPost <- POST(queryGenerate, authenticate(user, password))  
  
  
  # Download the data
  queryDownload <- sprintf("%s/api/v1/export/%s/%s", headquarters, export_type, qn_Id)
  dataDownload <- GET(queryDownload, authenticate(user, password)) 
  # So, we fetch using  redirected URL 
  redirectURL <- dataDownload$url 
  rawData <- GET(redirectURL) 
  
  ### Save the files to local drive  ----------------------------------------------------
  tounzip <- paste0("foldername",i,".zip") # Name the zip folder according to the data you want to download
  filecon <- file(file.path(download_folder, tounzip), "wb")
  writeBin(rawData$content, filecon) 
  #close the connection
  close(filecon)
  
  }
version = c(1,2,3) # Different versions of the survey questionnaire
lapply(version, fullimport) 

### Unzip zip files ---------------------------------------------------------------------
fullunzip<- function(i){
zipF <- file.path(paste0("./Data/Raw/",i,".zip")) # filepath
td <- file.path(paste0("./Data/Raw/",i)) # filepath
unzip(zipF,exdir=td,overwrite=TRUE)

}
version = c(1,2,3,4,5,6,7,8,9,10)
lapply(version, fullunzip) 


