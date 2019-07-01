library(ggridges)

all.data$fantPts_AGG<-rowMeans(all.data[,colnames(all.data)%in% c("fantPts_FDATA", "fantPts_FFTODAY", "fantPts_FFA")], na.rm=T)


all.data<-all.data[order(all.data$ADP_half, decreasing = F),]
all.data<-ddply(all.data, .(Season),mutate, ADP.Rank=rank(ADP_half, na.last = "keep"))
all.data$ADP.Rank[is.na(all.data$ADP_half)]<-500 #undrafted


all.data[all.data$Season==2018,]

all.data<-all.data[which(all.data$fantPts_AGG>=50),]

plot(all.data$fantPts[all.data$Pos=="RB"]~all.data$fantPts_AGG[all.data$Pos=="RB"])
all.data$fantPts_AGG.bin<-cut(all.data$fantPts_AGG, breaks=c(0,  100, 150, 200, 250, 400))
all.data$Error<-all.data$fantPts-all.data$fantPts_AGG

table(all.data$fantPts_AGG.bin)
hist(all.data$Error[all.data$Pos=="RB"])

errors<-ddply(all.data[!is.na(all.data$Error),], .(fantPts_AGG.bin, Pos), summarize, 
              mean.error.FFA=mean(fantPts-fantPts_FFA, na.rm=T),
              mean.error.FDATA=mean(fantPts-fantPts_FDATA, na.rm=T),
              mean.error.FFTODAY=mean(fantPts-fantPts_FFTODAY, na.rm=T),
              mean.error=mean(Error),
              median.error=median(Error),
              sd.error=sd(Error),
              n=length(Error)
)
errors<-errors[errors$n>10,]
errors[order(errors$fantPts_AGG.bin, decreasing = T),]

#appears to be some bias in 3rd party projections
ggplot(data=all.data[all.data$Pos=="RB",],aes(x=fantPts_AGG.bin, y=Error) )+
  geom_boxplot()+
  coord_flip()
ggplot(data=all.data[all.data$Pos%in% c("WR"),],aes(x=Error, y=paste0(Pos,fantPts_AGG.bin )) )+
  stat_density_ridges(quantile_lines = TRUE, quantiles = 2)

