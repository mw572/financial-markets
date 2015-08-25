#-----------------------------------------------
# Script written by Marcus Williamson - 06/08/15
#-----------------------------------------------
# Part of the Whitepaper research for the title:
# "The financial press and stock markets in times of crisis"
#-----------------------------------------------
# 'Bad News Index' creation
#-----------------------------------------------

# Code adapted from: https://github.com/abromberg/sentiment_analysis


#import libraries
library(plyr)
library(stringr)
library(e1071)


#Cleanup before we start
ls()
rm(list = ls())

setwd("~/Documents/R/Whitepaper Research/The financial press and stock markets in times of crisis - Data Collection/Data")

#load up word polarity list and format it 
afinn_list <- read.delim(file='AFINN-111.txt', header=FALSE, stringsAsFactors=FALSE)
names(afinn_list) <- c('word', 'score')
afinn_list$word <- tolower(afinn_list$word)

#load up our extended dictionary from recent recession wording
bad_extended <- read.delim(file='badwordsextended.txt', header=FALSE, stringsAsFactors=FALSE)


#categorize words as very n to very p and add some movie-specific words
vn <- c(afinn_list$word[afinn_list$score==-5 | afinn_list$score==-4], bad_extended)
n <- c(afinn_list$word[afinn_list$score==-3 | afinn_list$score==-2 | afinn_list$score==-1], "second-rate", "moronic", "third-rate", "flawed", "juvenile", "boring", "distasteful", "ordinary", "disgusting", "senseless", "static", "brutal", "confused", "disappointing", "bloody", "silly", "tired", "predictable", "stupid", "uninteresting", "trite", "uneven", "outdated", "dreadful", "bland")
p <- c(afinn_list$word[afinn_list$score==3 | afinn_list$score==2 | afinn_list$score==1], "first-rate", "insightful", "clever", "charming", "comical", "charismatic", "enjoyable", "absorbing", "sensitive", "intriguing", "powerful", "pleasant", "surprising", "thought-provoking", "imaginative", "unpretentious")
vp <- c(afinn_list$word[afinn_list$score==5 | afinn_list$score==4], "uproarious", "riveting", "fascinating", "dazzling", "legendary")


#load up our data - 2014-2015 "scrapedfile"
load("~/Documents/R/Whitepaper Research/The financial press and stock markets in times of crisis - Data Collection/Data/WSJ-14-15-Backup.Rdata")

#function to calculate number of words in each category within a sentence
sentimentScore <- function(sentences, vn, n, p, vp){
  
  final_scores <- matrix('', 0, 5)
  scores <- laply(sentences, function(sentence, vn, n, p, vp){
    
    initial_sentence <- sentence
    
    #remove unnecessary characters and split up by word 
    sentence <- gsub('[[:punct:]]', '', sentence)
    sentence <- gsub('[[:cntrl:]]', '', sentence)
    sentence <- gsub('\\d+', '', sentence)
    sentence <- tolower(sentence)
    wordList <- str_split(sentence, '\\s+')
    words <- unlist(wordList)
    
    #build vector with matches between sentence and each category
    vpm <- match(words, vp)
    pm <- match(words, p)
    vnm <- match(words, vn)
    nm <- match(words, n)
    
    
    #sum up number of words in each category
    vpm <- sum(!is.na(vpm))
    pm <- sum(!is.na(pm))
    vnm <- sum(!is.na(vnm))
    nm <- sum(!is.na(nm))
    score <- c(vnm, nm, pm, vpm)
    
    #add row to scores table
    newrow <- c(initial_sentence, score)
    final_scores <- rbind(final_scores, newrow)
    
    return(final_scores)
  }, vn, n, p, vp)
  return(scores)
}

#create dataframe for output
df <- data.frame(day=integer(),headline=character(),stringsAsFactors=FALSE)
a <- 1
#to iterate through this scoring function for each day 
for(i in 1:nrow(scrapedfile)){
  if(i==1){df <- rbind(df[1:1,],c(a,scrapedfile$headline[i]),df[-(1:1),])}
  else if(as.character(scrapedfile$shortdate[i])==as.character(scrapedfile$shortdate[i-1])){df <- rbind(df[1:i,],c(a,scrapedfile$headline[i]),df[-(1:i),])}
  else {
  a = a + 1
  df <- rbind(df[1:i,],c(a,scrapedfile$headline[i]),df[-(1:i),])
  }
  print(paste(signif((i/nrow(scrapedfile))*100,2),"%"))
}

#put in dataframe format and split by date so we have "daily headlines in lists" this may take a while to run
datelists <- split(df , f = df$day )
#create our counts dataframe to store totals by day
counts <- data.frame(day=integer(),vn=integer(),n=integer(),p=integer(),vp=integer(),neg=integer(),tot=integer(),stringsAsFactors=FALSE)
vals <- c(1:20) #create a vector to compare counts of bad words against
headlines <- as.data.frame()

#creating a loop to cycle through days
for(i in 1:length(datelists)){
  #generate our scores for a days worth of headlines
  headlines <- as.data.frame(datelists[i])
  colnames(headlines) = c("day","headline")
  #get our word counts
  result <- as.data.frame(sentimentScore(headlines$headline, vn, n, p, vp),stringsAsFactors=FALSE)
  negarticles = sum(!is.na(match(as.numeric(result$`4`)|as.numeric(result$`5`),vals)))
  totalarticles = sum(!is.na(match(as.numeric(result$`4`)|as.numeric(result$`5`)|as.numeric(result$`3`)|as.numeric(result$`2`),vals)))
  #place them in the counts data frame
  counts <- rbind(counts[1:i,],c(i,sum(as.numeric(result$`5`)),sum(as.numeric(result$`4`)),sum(as.numeric(result$`3`)),sum(as.numeric(result$`2`)),as.numeric(negarticles),as.numeric(totalarticles)),counts[-(1:i),])
}
counts = counts[-1,]

#save table of data as backup
write.table(counts, file="WSJ-2014-15-Market-counts.csv", quote = FALSE)

#THE BAD NEWS INDEX
#note: we are combining very bad & bad with very postive & positive
#formula: w = c/l (relative importance of article), b = w(t(n+1)) (bad news overall), we do not have t defined as the total available columns where news could appear
#
#looping through to create index for each day
badnewsindex <- data.frame(day=integer(),index=integer(),stringsAsFactors=FALSE)

for(i in 1:nrow(counts)){
  
  #calculating w = c/l, (total/negative columns)
  w = as.numeric(counts$tot[i])/as.numeric(counts$neg[i])
  b = w*(1+as.numeric(counts$n[i])+as.numeric(counts$vn[i]))
  
  badnewsindex <- rbind(badnewsindex[1:i,],c(i,b),badnewsindex[-(1:i),])
}
badnewsindex = badnewsindex[-1,]

#save table of data as backup
write.table(badnewsindex, file="WSJ-2014-15-Market-index.csv", quote = FALSE)

############################## END CODE ##################################