library(ggplot2)
library(grid)
library(gridExtra)
library(R.matlab)

oldResults <- read.csv('/Users/zer/RegFitAD/data/HCPwStruct/RegFitXpts/SavedResults/Noise2results.csv')
upres <- read.csv('/Users/zer/RegFitAD/data/HCPwStruct/RegFitXpts/SavedResults/UpsResultsNoise2.csv')
results <- merge(oldResults,upres,all = TRUE)
results<-get_results(results)
results$Dim <- .25*as.numeric(results$nResampling) + 1
results$nResampling<-factor(results$Dim)


nonoise <- read.csv('/Users/zer/RegFitAD/data/HCPwStruct/RegFitXpts/SavedResults/NoiseLess.csv')
results<-get_results(nonoise)

new.res <- read.csv('/Users/zer/RegFitAD/data/HCPwStruct/RegFitXpts/SavedResults/GoodRes.csv')
results<-get_results_hcp(new.res)

levels(results$Method)<-c('Classical','Proposed','Classical with Upsampling')
levels(results$nResampling) <- c('1.0000','2.7273','4.4545','6.1818','7.9091','9.6364','11.3636','13.0909','14.8182','16.5455','18.2727')#20
levels(results$nResampling) <- c('1.25','1.75','2.06','2.29','2.49','2.66','2.81','2.95','3.07','3.19','3.29') #,3.39)


results.toplot = subset(results,nReadings == '12' &Method != 'Classical'& Region!='Brainstem')
a<-ggplot(aes(x=nResampling,y=Value),data=subset(results.toplot,paramName == 'FA'))+ #&Region%in%c('F1','F2','F3')))+
  geom_point(aes(color = Region),position=position_jitter(width=0.1))+
  geom_boxplot(aes(fill=Region),outlier.size=0,position=position_dodge(width=0.2),width = 2)+
  ylab('FA')+
  xlab('Voxel dimension / mm')+
  theme(legend.position='none',axis.text.x=element_text(angle=45,hjust=1),axis.text.y=element_text(angle=60,hjust=1))+
  facet_wrap(~Method)

b<-ggplot(aes(x=nResampling,y=Value),data=subset(results.toplot,paramName == 'MD'))+ 
  geom_point(aes(color = Region),position=position_jitter(width=0.1))+
  geom_boxplot(aes(fill=Region),outlier.size=0,position=position_dodge(width=0.2),width = 2)+
  ylab(expression(paste('MD/mm'^2,'s'^-1)))+
  xlab('Voxel dimension / mm')+
  facet_wrap(~Method)+
  theme(legend.position='right',axis.text.x=element_text(angle=45,hjust=1),axis.text.y=element_text(angle=60,hjust=1))
grid.arrange(a,b)
c<-arrangeGrob(a,b)
ggsave(filename='/Users/zer/Dropbox/MICCAI2016/images/MineVsUps12.png',plot=c)


#This bit is good and shows clearly what we're talking about - maybe stick to FA for room? 
a<-ggplot(aes(x=nResampling,y=Value),data=subset(results,nReadings == 60& as.numeric(nResampling)<7 &paramName == 'FA'&Method == 'Classical'&  Thresh!='50' & Region %in% c('F:Column','F:Body','F:Crus')))+
  geom_point(aes(color = Region),position=position_jitter(width=0.1))+
  geom_boxplot(aes(fill=Region),outlier.size=0,position=position_dodge(width=0),width = 3)+
  facet_wrap(~Thresh,ncol=4)+
  ylab('FA')+
  xlab('Voxel Size/mm')+
  ggtitle('Effect of percentage threshold on parameter estimates')+
  coord_cartesian(ylim=c(0.2,1))+
  theme(axis.text.x=element_text(angle=45,hjust=1),axis.text.y=element_text(angle=60,hjust=1))

b<-ggplot(aes(x=nResampling,y=Value),data=subset(results,nReadings == 60& as.numeric(nResampling)<7 &paramName == 'MD'&Method == 'Classical'& Region %in% c('F:Column','F:Body','F:Crus')& Thresh!='50'))+
  geom_point(aes(color = Region),position=position_jitter(width=0.1))+
  geom_boxplot(aes(fill=Region),outlier.size=0,position=position_dodge(width=0),width = 3)+
  facet_wrap(~Thresh,ncol=4)+
  ylab(expression(paste('MD/mm'^2,'s'^-1)))+
  xlab('Voxel Size/mm')+
  coord_cartesian(ylim=c(.0005,0.0015))+
  theme(axis.text.x=element_text(angle=45,hjust=1),axis.text.y=element_text(angle=60,hjust=1))

grid.arrange(a,b)
c<-arrangeGrob(a,b)
ggsave(filename='/Users/zer/Dropbox/MICCAI2016/images/ClassicLowres.png',plot=c)

get_results_hcp<-function(results){
results$Method <- factor(results$Method)
results$nReadings <- factor(results$nReadings)
results$nRegion <- factor(results$nRegion)
results$nResampling<- factor(results$nResampling)
results$paramName <- factor(results$paramName)
results$Thresh <- results$Thresh * 100
results$Thresh <- factor(results$Thresh)
colnames(results)[4]<-'Region'
levels(results$Region)<-c('CSF','GM','WM','DGM','Brainstem','F:Column','F:Body','F:Crus')
results$Value[is.na(results$Value)] <- -0.3
return(results)
}