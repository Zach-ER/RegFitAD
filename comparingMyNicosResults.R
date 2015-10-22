library('ggplot2')

classicMeth <- read.csv('/Users/zer/Downloads/statistics.csv')
classicMeth$subject_id <- levels(comparison$subject_id)


myMeth <- read.csv('/Users/zer/RegFitAD/data/allResultsCorrected.txt',sep = ' ',header = F)
myMeth <- myMeth[,colSums(is.na(myMeth))<nrow(myMeth)]
myMeth <- myMeth[complete.cases(myMeth),]

colnames(myMeth)<- c('subjID','regionNo','D1','D2','D3','MD','FA')
myMeth$regionNo <- factor(myMeth$regionNo)
myMeth$subjID <- factor(myMeth$subjID)

ggplot(aes(x = regionNo, y = FA),data = myMeth)+
  geom_boxplot(notch = T)
  
ggplot(aes(x = regionNo, y = MD),data = myMeth)+
  geom_boxplot(notch = T)


qplot(classicMeth$md_8)

ggplot(subset(myMeth,strtoi(regionNo) < 11 & strtoi(regionNo) >2 ),aes(x=MD,fill = regionNo))+
  geom_histogram(alpha = 0.6)