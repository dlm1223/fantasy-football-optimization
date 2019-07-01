# rm(list=ls())
source('functions.R', encoding = 'UTF-8')
load("Data/Fantasy Data.RData")

#change to 0 for STD or 1 or PPR. can change more stats below manually
recept.pts<-.5


###CLEAN DATA#####

#ffanalytics####

head(FFANALYTICS, 1)
FFANALYTICS[, c("Player","Team")]<-sapply(FFANALYTICS[, c("Player","Team")], coordName)
FFANALYTICS[is.na(FFANALYTICS)]<-0
#players who play multiple posiiotns are duplicated: take the mean
FFANALYTICS<-data.table(FFANALYTICS)[, `:=`(position=paste0(position,collapse=';')), by=c("Player", "Team", "playerId", "Season")]
FFANALYTICS<-FFANALYTICS[, lapply(.SD, mean, na.rm=T), by=c("playerId","Player",  "Team", "position", "Season")]
FFANALYTICS<-data.frame(FFANALYTICS)


FFANALYTICS$fantPts_FFA<-
  FFANALYTICS$passYds*1/25+FFANALYTICS$passTds*4+FFANALYTICS$passInt*-1+FFANALYTICS$twoPts*2+
  FFANALYTICS$rushYds*1/10+FFANALYTICS$recYds*1/10+FFANALYTICS$rec*recept.pts+FFANALYTICS$rushTds*6+FFANALYTICS$recTds*6+
  FFANALYTICS$fumbles*(-2)+FFANALYTICS$returnYds*0+FFANALYTICS$returnTds*6+
  #kicker
  FFANALYTICS$fg0019*1+FFANALYTICS$xp*1+FFANALYTICS$fg2029*1.5+FFANALYTICS$fg3039*2+FFANALYTICS$fg4049*2.5+FFANALYTICS$fg50*3+FFANALYTICS$fgMiss*-1
FFANALYTICS<- FFANALYTICS[!duplicated(FFANALYTICS[ c("Player", "Team", "Season")]),]
FFANALYTICS[FFANALYTICS$Player=='Lesean Mccoy'& FFANALYTICS$Season==2018,] 


#fftoday#####


FFTODAY[, c("Player", 'Team')]<-sapply(FFTODAY[, c("Player", 'Team')], coordName)
colnames(FFTODAY)[colnames(FFTODAY)=='fantPts']<-"fantPts_FFTODAY"

FFTODAY<-FFTODAY[!duplicated(FFTODAY[, c("Player", "Team", "Season")]),]
FFTODAY<-FFTODAY[!(FFTODAY$Pos=='QB'& FFTODAY$Season==2018), ] #something wrong with webpage

#imported as half-ppr
FFTODAY$fantPts_FFTODAY<-FFTODAY$fantPts_FFTODAY+(recept.pts-.5)*FFTODAY$recREC


##fantasydata.com#####


FDATA_SEASONAL$Player[grepl("\n", FDATA_SEASONAL$Player)]<-sapply(strsplit(FDATA_SEASONAL$Player[grepl("\n", FDATA_SEASONAL$Player)], "\n"), `[[`, 1)
FDATA_SEASONAL[, c("Player","Team")]<-sapply(FDATA_SEASONAL[, c("Player","Team")], coordName)
colnames(FDATA_SEASONAL)[colnames(FDATA_SEASONAL)=="ID"]<-"FDATAID"
colnames(FDATA_SEASONAL)[colnames(FDATA_SEASONAL)=="Pos"]<-"PosFDATA"
FDATA_SEASONAL[is.na(FDATA_SEASONAL)]<-0


#fdata SEASONAL projections
FDATA_SEASONAL$fantPts_FDATA<-FDATA_SEASONAL$PassYds*1/25+FDATA_SEASONAL$PassTD*4+FDATA_SEASONAL$PassInt*(-1)+
  FDATA_SEASONAL$RushYds*1/10+FDATA_SEASONAL$RecYds*1/10+FDATA_SEASONAL$Rec*recept.pts+
  FDATA_SEASONAL$RushTD*6+FDATA_SEASONAL$RecTD*6+FDATA_SEASONAL$Return.TD*6+
  FDATA_SEASONAL$FumsLost*-2+FDATA_SEASONAL$Fums*0
FDATA_SEASONAL$fantPts_FDATA[which(FDATA_SEASONAL$PosFDATA=='DST')]<-FDATA_SEASONAL$FantPts[which(FDATA_SEASONAL$PosFDATA=='DST')]
hist(FDATA_SEASONAL$fantPts_FDATA)

head(FDATA_SEASONAL[FDATA_SEASONAL$Season==2017 & FDATA_SEASONAL$PosFDATA=="DST", c("Player","Team", "fantPts_FDATA")], 15)

#some data errors
FDATA_SEASONAL$Team[FDATA_SEASONAL$Player=="Fred Jackson"& FDATA_SEASONAL$Season==2015]<-"Sea"
FDATA_SEASONAL$Team[FDATA_SEASONAL$Player=="James Jones"& FDATA_SEASONAL$Season==2014]<-"Oak"
FDATA_SEASONAL$Team[FDATA_SEASONAL$Player=="James Jones"& FDATA_SEASONAL$Season==2015]<-"Gnb"
FDATA_SEASONAL$Team[FDATA_SEASONAL$Player=="Timothy Wright"& FDATA_SEASONAL$Season==2014]<-"Nwe"
FDATA_SEASONAL$FantPts<-NULL
FDATA_SEASONAL<-FDATA_SEASONAL[!FDATA_SEASONAL$Pos=='K',] #need to rescrape kicker projections
FDATA_SEASONAL<-FDATA_SEASONAL[!duplicated(FDATA_SEASONAL[, c("Player", "Team", "Season")]),]

####actuals####
fantasy.actuals[, c("Player", "Team")]<-sapply(fantasy.actuals[, c("Player", "Team")], coordName)

#imported as halfppr
fantasy.actuals$fantPts<-fantasy.actuals$fantPts+(recept.pts-.5)*fantasy.actuals$recREC

fantasy.actuals<-rbind.fill(fantasy.actuals, FFTODAY[FFTODAY$Season==2019, c("Player", "Team", "Pos", "Season")]) #i'm adding 2019 for merging purposes
table(fantasy.actuals$Season)

#note: for traded players,appears that they display player's first team 
fantasy.actuals[fantasy.actuals$Season==2018& fantasy.actuals$Player%in% c("Golden Tate", "Carlos Hyde"),] 
table(fantasy.actuals$Pos)



####AGGREGATE DATA#####


all.data<-Reduce(function(dtf1, dtf2) merge(dtf1, dtf2, by =c( "Player", "Team","Season"), all.x = TRUE),
                 list(fantasy.actuals[, c("Player", "Pos", "Team", "Season", "fantPts", "fantPts.G")], 
                      FFTODAY[,c("Player", "Team", "Season", "fantPts_FFTODAY")],
                      FDATA_SEASONAL[,c("Player", "Team", "Season", "fantPts_FDATA")],
                      FFANALYTICS[,c("Player", "Team", "Season", "fantPts_FFA")]
                 ))
all.data<-all.data[all.data$Pos%in% c('RB',"WR", "TE", "QB", "DST", "K"), ]
all.data$fantPts_FFTODAY[all.data$Pos=='QB'& all.data$Season==2018]<-all.data$fantPts_FFA[all.data$Pos=='QB'& all.data$Season==2018] #2018 fftoday got screwed up so imputing

ffcalc[duplicated(ffcalc[, c("Player", "Pos","Season")]),]


#Teams in FFCALC data are messed up, so need to merge on Name, Pos and so need to clean some duplicate names
all.data$Player[all.data$Player%in% c("Michael Williams")& all.data$Team%in% "Sea"]<-"Michael Williams (Sea)"
all.data$Player[all.data$Player%in% c("Steve Smith")& all.data$Team%in% c("Car", "Bal")]<-'Steve Smith Sr'
all.data$Player[all.data$Player%in% c("Adrian Peterson")& all.data$Team%in% c("Chi")]<-'Adrian Peterson (Chi)'
all.data$Player[all.data$Player%in% c("Zach Miller")& all.data$Team%in% c("Jax")]<-'Zach Miller (Jax)'

ffcalc$Player[ffcalc$Player%in% c("Michael Williams")& ffcalc$Team%in% "Sea"]<-"Michael Williams (Sea)"
ffcalc$Player[ffcalc$Player%in% c("Steve Smith")& ffcalc$Team%in% c("Car", "Bal")]<-'Steve Smith Sr'
ffcalc$Player[ffcalc$Player%in% c("Adrian Peterson")& ffcalc$Team%in% c("Chi")]<-'Adrian Peterson (Chi)'
ffcalc$Player[ffcalc$Player%in% c("Zach Miller")& ffcalc$Team%in% c("Jax")]<-'Zach Miller (Jax)'

all.data<-merge(all.data,  ffcalc[, !colnames(ffcalc)=="Team"], by=c("Player", "Pos", "Season"), all.x=T) 



all.data[duplicated(all.data[, c("Player", "Season", "ADP_half")])& !is.na(all.data$ADP_half),] #make sure no duplicates

table(all.data$Pos, all.data$Season)

summary(all.data[all.data$Season>=2014& !is.na(all.data$ADP_half),])



####QUICK PLOTS######

#plot some correlations
all.data[, grepl("fantPts_", colnames(all.data))][all.data[, grepl("fantPts_", colnames(all.data))]==0]<-NA
all.data$fantPts_AGG<-rowMeans(all.data[,colnames(all.data)%in% c("fantPts_FDATA", "fantPts_FFTODAY", "fantPts_FFA")], na.rm=T)

#to compare projection rankings fairly, drop missing values
analyze<-all.data[complete.cases(all.data[,c("fantPts", "ADP_half", "fantPts_FFA", "fantPts_FDATA", "fantPts_FFTODAY")])|
                    (complete.cases(all.data[,c("fantPts", "ADP_half", "fantPts_FFA",  "fantPts_FFTODAY")])& all.data$Pos=='K')  ,] #
analyze<-analyze[analyze$Season>=2014,]
analyze<-ddply(analyze, .(Pos, Season), mutate,
               Actual.rank=rank(-fantPts,na.last = "keep" ),
               ADP.rank=rank(ADP_half,na.last = "keep" ),
               fantPts_AGG.rank=rank(-fantPts_AGG, na.last="keep"),
               fantPts_FFA.rank=rank(-fantPts_FFA, na.last = "keep"), #na.last=keep will return NA rank for missing values
               fantPts_FDATA.rank=rank(-fantPts_FDATA, na.last = "keep"), #na.last=keep will return NA rank for missing values
               fantPts_FFTODAY.rank=rank(-fantPts_FFTODAY, na.last = "keep") #na.last=keep will return NA rank for missing values
)
head(analyze[analyze$Season==2018& analyze$Pos=="WR",], 15)
cors<-ddply(analyze, .(Pos), summarize,
            n=length(Actual.rank),
            ADP.rank=cor(Actual.rank,ADP.rank ),
            fantPts_AGG.rank=cor(Actual.rank, fantPts_AGG.rank), #comapring projection, not exactly fair
            fantPts_FFA.rank=cor(Actual.rank,fantPts_FFA.rank),
            fantPts_FDATA.rank=cor(Actual.rank,fantPts_FDATA.rank ),
            fantPts_FFTODAY.rank=cor(Actual.rank,fantPts_FFTODAY.rank)
            
)
cors
ggplot(melt(cors[, !colnames(cors)=="n"], id.vars="Pos", value.name='cor',variable.name='Source'), aes(x=Pos, y=cor, fill=Source))+
  geom_bar(position="dodge", stat="identity")+
  ggtitle("Correlations to End of Season Rank,2014-2018")



analyze<-all.data[complete.cases(all.data[,c("fantPts", "ADP_half", "fantPts_AGG")]) ,] #
table(analyze$Season)
analyze<-ddply(analyze, .(Pos, Season), mutate,
               Actual.rank=rank(-fantPts,na.last = "keep" ),
               ADP.rank=rank(ADP_half,na.last = "keep" ),
               fantPts_AGG.rank=rank(-fantPts_AGG, na.last = "keep")
)
analyze$fantPts_ENSEMBLE.rank<-rowMeans(analyze[, c("ADP.rank", "fantPts_AGG.rank")])

cors<-ddply(analyze, .(Pos), summarize,
            ADP.rank=cor(Actual.rank,ADP.rank ),
            fantPts_AGG=cor(Actual.rank, -fantPts_AGG), #comapring projection, not exactly fair
            fantPts_AGG.rank=cor(Actual.rank,fantPts_AGG.rank),
            fantPts_ENSEMBLE.rank=cor(Actual.rank,fantPts_ENSEMBLE.rank)
            
)
cors
ggplot(melt(cors, id.vars="Pos", value.name='cor',variable.name='Source'), aes(x=Pos, y=cor, fill=Source))+
  geom_bar(position="dodge", stat="identity")


analyze$Fantasy.Starter<-analyze$fantPts_ENSEMBLE.rank<=12& analyze$Pos%in%c("TE", "QB", "DST", "K")|
  analyze$fantPts_ENSEMBLE.rank<=30& analyze$Pos%in%c("RB")|
  analyze$fantPts_ENSEMBLE.rank<=40& analyze$Pos%in%c("WR")

cors<-ddply(analyze[analyze$Fantasy.Starter,], .(Pos), summarize,
            ADP.rank=cor(Actual.rank,ADP.rank ),
            fantPts_AGG=cor(Actual.rank, -fantPts_AGG), #comapring projection, not exactly fair
            fantPts_AGG.rank=cor(Actual.rank,fantPts_AGG.rank),
            fantPts_ENSEMBLE.rank=cor(Actual.rank,fantPts_ENSEMBLE.rank)
            
)
cors
ggplot(melt(cors, id.vars="Pos", value.name='cor',variable.name='Source'), aes(x=Pos, y=cor, fill=Source))+
  geom_bar(position="dodge", stat="identity")

#top 12 each position
analyze<-all.data[complete.cases(all.data[,c("fantPts", "ADP_half", "fantPts_FFA", "fantPts_FDATA", "fantPts_FFTODAY")])|
                    (complete.cases(all.data[,c("fantPts", "ADP_half",  "fantPts_FFTODAY")])& all.data$Pos%in% c('K', 'DST'))  ,] #
analyze<-analyze[analyze$Season>=2014,]
analyze<-ddply(analyze, .(Pos, Season), mutate,
               Actual.rank=rank(-fantPts,na.last = "keep" ),
               ADP.rank=rank(ADP_half,na.last = "keep" ),
               fantPts_AGG.rank=rank(-fantPts_AGG, na.last="keep"),
               fantPts_FFA.rank=rank(-fantPts_FFA, na.last = "keep"), #na.last=keep will return NA rank for missing values
               fantPts_FDATA.rank=rank(-fantPts_FDATA, na.last = "keep"), #na.last=keep will return NA rank for missing values
               fantPts_FFTODAY.rank=rank(-fantPts_FFTODAY, na.last = "keep") #na.last=keep will return NA rank for missing values
)
cors<-ddply(analyze[analyze$ADP.rank<=12,], .(Pos), summarize,
            n=length(Actual.rank),
            ADP.rank=cor(Actual.rank,ADP.rank ),
            fantPts_AGG.rank=cor(Actual.rank, fantPts_AGG.rank), #comapring projection, not exactly fair
            fantPts_FFA.rank=cor(Actual.rank,fantPts_FFA.rank),
            fantPts_FDATA.rank=cor(Actual.rank,fantPts_FDATA.rank ),
            fantPts_FFTODAY.rank=cor(Actual.rank,fantPts_FFTODAY.rank)
            
)
cors
ggplot(melt(cors[, !colnames(cors)=="n"], id.vars="Pos", value.name='cor',variable.name='Source'), aes(x=Pos, y=cor, fill=Source))+
  geom_bar(position="dodge", stat="identity")+
  ggtitle("Correlations to End of Season Rank,2014-2018, Top 12 players by Pos")
