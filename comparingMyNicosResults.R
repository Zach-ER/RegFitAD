library('ggplot2')

classicMeth <- read.csv('/Users/zer/Downloads/statistics.csv')
classicMeth$subject_id <- levels(comparison$subject_id)


myMeth <- read.csv('/Users/zer/RegFitAD/data/allResults.txt',sep = ' ',header = F)
myMeth <- myMeth[,colSums(is.na(myMeth))<nrow(myMeth)]
myMeth <- myMeth[complete.cases(myMeth),]

colnames(myMeth)<- c('subjID','regionNo','D1','D2','D3','MD','FA')
myMeth$regionNo <- factor(myMeth$regionNo)
myMeth$subjID <- factor(myMeth$subjID)

qplot(subset(myMeth$MD,myMeth$regionNo == 50))
qplot(classicMeth$md_48)

ggplot(subset(myMeth,strtoi(regionNo) < 11 & strtoi(regionNo) >2 ),aes(x=FA,fill = regionNo))+
  geom_histogram(alpha = 0.6,binwidth = 0.01)