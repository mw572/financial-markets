# ----------------------------------------------
# Script written by Marcus Williamson - 04/08/15
# ----------------------------------------------
# Part of Whitepaper research for title:
# "The financial press and stock markets in times of crisis"
# ----------------------------------------------
# Webscraping WSJ news 
# ----------------------------------------------

#Cleanup the DB before we start
ls()
rm(list = ls())

# set working directory
setwd("/Users/marcuswilliamson/Documents/R/Whitepaper Research/The financial press and stock markets in times of crisis - Data Collection/Data")

# load libraries
library(RCurl)
library(XML)
library(data.table)
library(plyr)

#how many pages of data do we have:
#SEARCHTERM IS MARKET
urlbase <- 'http://www.wsj.com/search/term.html?KEYWORDS=market&isAdvanced=true&min-date=2014/01/01&max-date=2015/01/01&page=1&daysback=4y&andor=AND&sort=date-desc&source=wsjarticle'

doc=htmlTreeParse(urlbase,useInternalNodes=TRUE)
ns = getNodeSet(doc,'//html/body/div[1]/div[2]/section[3]/div[1]/div[2]/div/div[2]/div[2]/menu/li[3]')

#this is our page count
count=as.numeric(gsub("[^0-9]","",sapply(ns,function(x) xmlValue(x))))

#part a + page no + part b give us the unique page link
urlbaseA <- "http://www.wsj.com/search/term.html?KEYWORDS=market&isAdvanced=true&min-date=2014/01/01&max-date=2015/01/01&page=" 
urlbaseB <- "&daysback=4y&andor=AND&sort=date-desc&source=wsjarticle"


#create our scraping function which takes url input and returns scraped output
scraper=function(urllink){
  
  # get html page content
  doc=htmlTreeParse(urllink,useInternalNodes=TRUE)
  
  # getting node sets
  
  #date of article
  rawdate=getNodeSet(doc,"/html/body/div[1]/div[2]/section[3]/div[1]/div[2]/div/div/ul/li/div/div/div[2]/ul/li/time/text()")

  #headline
  headline=getNodeSet(doc,"/html/body/div[1]/div[2]/section[3]/div[1]/div[2]/div/div/ul/li/div/div/h3/a/text()")
  
  #clean and put them in a table
  rawdate=sapply(rawdate,function(x) xmlValue(x))
  shortdate=lapply(rawdate,function(x) if(grepl("[.]",x)){as.Date(x,"%b. %d, %Y")} else{as.Date(x,"%b %d, %Y")}) #lapply to keep date format
  shortdate=lapply(shortdate,function(x) as.character.Date(x)) #converting into string
  datePublished=data.table(shortdate)
  
  #put in table
  headline=sapply(headline,function(x) xmlValue(x))
  headline=data.table(headline)
  
  # select the first price observation (Temp fix!)
  #linePrice <- linePrice[1:1,]
  
  scrapedfile <- cbind(datePublished, headline)
  
  # put all the fields in a dataframe
  return(scrapedfile)
}  


#create location for our output
scrapedfile.l=as.list(rep(NA,count))

#for loop to do the scraping and placing in output
for(i in 1:count){
  urlgen = paste(urlbaseA,i,urlbaseB,sep="",collapse = NULL)
  scrapedfile.l[[i]]=scraper(urlgen)
  print(paste(signif((i/count)*100,3),"%"))
}

#combining data outputs together
scrapedfile <- rbindlist(scrapedfile.l)

#Save our data to use later as backup
save(scrapedfile, file = "WSJ-14-15-Backup.Rdata") #rawbackup

#writing into table for csv output
output <- t(do.call(rbind,lapply(scrapedfile,matrix,ncol=nrow(scrapedfile),byrow=FALSE)))

#ensuring named correctly
colnames(output)[1:2] <- c("date","headline")

write.table(output, file="WSJ-2014-15-Market.csv",sep="|", quote = FALSE)

########################### END OF CODE #############################