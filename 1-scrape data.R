
#setwd() to current directory--note: all this data already has been saved as Data/Fantasy Data.RData

source('functions.R', encoding = 'UTF-8')


########FFANALYTICS SEASONAL PROJECTIONS######

FFANALYTICS<-ldply(lapply( list.files("Data/FFAnalytics/", pattern="-0", full.names = T),
                           function(x) {
                             df<-read.csv(x);
                             df$Season<-as.numeric(substring(x, 36,39))
                             df
                           }), data.frame)
FFANALYTICS[, c("player", "team")]<-sapply(FFANALYTICS[, c("player", "team")], coordName)
FFANALYTICS[, !colnames(FFANALYTICS)%in% c("player", "team", "position")]<-sapply(FFANALYTICS[, !colnames(FFANALYTICS)%in% c("player", "team","position")], as.numeric)
colnames(FFANALYTICS)[colnames(FFANALYTICS)%in% c("player", "team")]<-c("Player", "Team")
FFANALYTICS[is.na(FFANALYTICS)]<-0


########FANTASYDATA.com SEASONAL PROJECTIONS######

remDr<-rsDriver(browser = "chrome", port=as.integer(runif(n=1,min = 1, max = 10000)), chromever="74.0.3729.6") #

#1. go to : https://fantasydata.com/nfl-stats/fantasy-football-weekly-projections?position=4&team=17&season=2018&seasontype=1&scope=1
#2. create LOGIN and sign in
#3. click   ACCEPT COOKIES

getTeam<-function( Season, Team, Pos,Site=5,  postseason=F){
  #Season<-2019;Team<-0;Pos<-2;Site<-5;postseason<-F
  
  print(c(Team, Pos))
  
  url<-paste0(c("https://fantasydata.com/nfl-stats/fantasy-football-weekly-projections?position=",Pos, "&team=",Team,"&season=",Season,
                "&seasontype=", 1+2*postseason,"&scope=1&scoringsystem=",Site), collapse=""   )
  remDr$client$navigate(url)
  Sys.sleep(3)
  page<-remDr$client$getPageSource()[[1]]
  page<-read_html(page)
  
  cols<-page%>% html_nodes(".k-link")%>% html_text()
  test<-page%>% html_table(fill=T)
  test<-lapply(test, head, 10)
  test<-do.call( "cbind", test[3:4])
  test<-test[, -1]
  if(Pos==2){
    colnames(test)<-c("Player", "Team", "Pos", "Gms", "PassComp", "PassAtt", "PassPct", "PassYds","PassYds.Att", "PassTD", "PassInt","PassRating",
                      "RushAtt", "RushYds","RushAvg", "RushTD", "PPG", "FantPts" )
    
  }else if(Pos==3){
    colnames(test)<-c("Player", "Team", "Pos", "Gms", "RushAtt", "RushYds", "RushAvg", "RushTD","Targets","Rec",  "RecYds","RecTD",
                      "Fums","FumsLost","PPG", "FantPts"  )
    
  }else if(Pos%in% 4:5){
    colnames(test)<-c("Player", "Team", "Pos", "Gms", "Targets", "Rec", "RecRec.Tgt", "RecYds","RecTD", "RecLong", "RecYds.Tgt", "RecYds.Rec",
                      "RushAtt", "RushYds", "RushAvg", "RushTD",
                      "Fums","FumsLost","PPG", "FantPts"  )
  } else if (Pos==6){
    colnames(test)<-c("Player","Team", "Pos", "Gms", "FGM", "FGA", "FGPCT", "FGLong", "XPM", "XPA", "PPG", "FantPts")
  } else if(Pos==7){
    colnames(test)<-c("Player","Team", "Pos", "Gms", "TFL", "Sacks", 
                      "QB.Hits", "Def.Int", "Fum.Rec", "Safeties", "Def.TD", "Return.TD","Pts.Allowed" , "PPG", "FantPts")
  }
  ids<-page%>%html_nodes("td:nth-child(2) a")%>% html_attr("href")
  ids<-ids[!is.na(ids)]
  test$ID<-ids[1:nrow(test)]
  test$Season<-Season
  test
}
#links to import
testGrid<-expand.grid(Pos=c(2, 3, 4, 5, 6, 7), Team=0:31, Season=2014:2019)
if(exists("FDATA_SEASONAL")){
  FDATA_SEASONAL2<-FDATA_SEASONAL[FDATA_SEASONAL$Season!=2019,]
  testGrid<-testGrid[testGrid$Season==2019,]
}
#import links
testList<-list();length(testList)<-nrow(testGrid)
for(x in 1:nrow(testGrid)){
  testList[[x]]<- getTeam(Season=testGrid$Season[x], Team=testGrid$Team[x], Pos=testGrid$Pos[x])
}
FDATA_SEASONAL<-data.frame(rbindlist(testList,fill=T ))
FDATA_SEASONAL<-FDATA_SEASONAL[, !colnames(FDATA_SEASONAL)%in% c("PassPct", "PassYds.Att", "PassRating", "RushAvg", "RecLong", "RushLong",
                                                                 "RecYds.Tgt", "RecYds.Rec")]
FDATA_SEASONAL[, !colnames(FDATA_SEASONAL)%in% c("Player", "Pos", "Team", "ID")]<-
  sapply(FDATA_SEASONAL[, !colnames(FDATA_SEASONAL)%in% c("Player", "Pos", "Team", "ID")], function(x) as.numeric(gsub("[,]", "", x)))

#combine and clean
if(exists("FDATA_SEASONAL2")){
  FDATA_SEASONAL<-rbind.fill(FDATA_SEASONAL[, colnames(FDATA_SEASONAL)%in% colnames(FDATA_SEASONAL2)],  FDATA_SEASONAL2)
} 
table(FDATA_SEASONAL$Team, FDATA_SEASONAL$Season)


##FFTODAY SEASONAL PROJECTIONS#####

readFFTODAY<-function(Season, PosID, Page){
  print(c(Season, PosID, Page))
  
  if(PosID%in%c(50, 60, 70)){
    leagueID<-193033 #idp scoring
  }else{
    leagueID<-17#yahoo scoring
  }
  page<-read_html(paste0("http://fftoday.com/rankings/playerproj.php?Season=",Season ,"&PosID=",PosID ,"&LeagueID=", leagueID, "&order_by=FFPts&sort_order=DESC&cur_page=", Page)) 
  stats<-page%>% html_table(  fill=T)
  stats<-stats[[length(stats)-1]]
  stats<-stats[-c(1:2),-1 ]
  if(nrow(stats)>1){
    if(PosID==10){
      colnames(stats)<-c("Player", "Team", "Bye", "passATT", "passCMP", "passYDS", "passTD", "passINT", "rushATT", "rushYDS", "rushTD", "fantPts")
      stats$Pos<-"QB"
    }else if(PosID==20){
      colnames(stats)<-c("Player", "Team", "Bye","rushATT", "rushYDS", "rushTD", "recREC", 'recYDS',"recTD", "fantPts" )
      stats$Pos<-"RB"
    } else if(PosID==30){
      colnames(stats)<-c("Player", "Team", "Bye", "recREC", 'recYDS',"recTD", "rushATT", "rushYDS", "rushTD","fantPts" )
      stats$Pos<-"WR"
    }else if(PosID==40){
      colnames(stats)<-c("Player", "Team", "Bye", "recREC", 'recYDS',"recTD", "fantPts" )
      stats$Pos<-"TE"
    }else if(PosID==50){
      colnames(stats)<-c("Player", "Team", "Bye", "defSOLO", 'defAST',"defSACK", "defPD" , "defINT", "defFF", "defFR", "fantPts")
      stats$Pos<-"DL"
    }else if(PosID==60){
      colnames(stats)<-c("Player", "Team", "Bye", "defSOLO", 'defAST',"defSACK", "defPD" , "defINT", "defFF", "defFR", "fantPts")
      stats$Pos<-"LB"
    }else if(PosID==70){
      colnames(stats)<-c("Player", "Team", "Bye", "defSOLO", 'defAST',"defSACK", "defPD" , "defINT", "defFF", "defFR", "fantPts")
      stats$Pos<-"DB"
    }else if(PosID==80){
      colnames(stats)<-c("Player", "Team", "Bye", "kickFGM", 'kickFGA',"kickFG.", "kickXPM" , "kickXPA", "fantPts")
      stats$Pos<-"K"
    }else if(PosID==99){
      stats<-stats[, c(1, ncol(stats))]
      colnames(stats)<-c("Player", "fantPts" )
      stats$Team<-stats$Player
      stats$Pos<-"DST"
    }
    stats$Season<-Season
  } else{
    stats<-data.frame()
  }
  stats
}
importGrid<-expand.grid(Season=2008:2019, PosID=c(seq(10, 80, 10), 99), Page=0:2)

if(exists("FFTODAY")){
  FFTODAY2<-FFTODAY[FFTODAY$Season!=2019,]
  importGrid<-importGrid[importGrid$Season==2019,]
}
FFTODAY<-ldply(lapply(1:nrow(importGrid), function(x) readFFTODAY(Season = importGrid$Season[x],
                                                                  PosID = importGrid$PosID[x], 
                                                                  Page=importGrid$Page[x])), data.frame)
FFTODAY[, !colnames(FFTODAY)%in% c("Player", "Team", "Pos")]<-sapply(FFTODAY[, !colnames(FFTODAY)%in% c("Player", "Team", "Pos")], function(x) as.numeric(gsub("[,]|[%]","", x)))
FFTODAY$Bye<-NULL
FFTODAY[is.na(FFTODAY)]<-0

if(exists("FFTODAY2")){
  FFTODAY<-rbind(FFTODAY,FFTODAY2 )
} 
table(FFTODAY$Season)

##FANTASY PTS-SCORED ACTUALS#####


readActuals<-function(Season, PosID, Page){
  print(c(Season, PosID, Page))
  
  if(PosID%in%c(50, 60, 70)){
    leagueID<-193033 #idp scoring
  }else{
    leagueID<-17#yahoo scoring
  }
  url<-paste0("https://www.fftoday.com/stats/playerstats.php?Season=",Season ,"&PosID=",
              PosID ,"&LeagueID=", leagueID, "&order_by=FFPts&sort_order=DESC&cur_page=", Page)
  page<-read_html(url) 
  stats<-page%>% html_table(  fill=T)
  stats<-stats[[length(stats)-1]]
  stats<-stats[-c(1:2), ]
  if(nrow(stats)>1){
    if(PosID==10){
      colnames(stats)<-c("Player", "Team", "G", "passATT", "passCMP", "passYDS", "passTD", "passINT", "rushATT", "rushYDS", "rushTD", "fantPts", "fantPts.G")
      stats$Pos<-"QB"
    }else if(PosID==20){
      colnames(stats)<-c("Player", "Team", "G","rushATT", "rushYDS", "rushTD", "recTGT", "recREC", 'recYDS',"recTD", "fantPts" , "fantPts.G")
      stats$Pos<-"RB"
    } else if(PosID==30){
      colnames(stats)<-c("Player", "Team", "G","recTGT", "recREC", 'recYDS',"recTD", "rushATT", "rushYDS", "rushTD","fantPts" , "fantPts.G")
      stats$Pos<-"WR"
    }else if(PosID==40){
      colnames(stats)<-c("Player", "Team", "G","recTGT", "recREC", 'recYDS',"recTD", "fantPts", "fantPts.G" )
      stats$Pos<-"TE"
    }else if(PosID==50){
      colnames(stats)<-c("Player", "Team", "G", "defSOLO", 'defAST',"defSACK", "defPD" , "defINT", "defFF", "defFR", "fantPts", "fantPts.G")
      stats$Pos<-"DL"
    }else if(PosID==60){
      colnames(stats)<-c("Player", "Team", "G", "defSOLO", 'defAST',"defSACK", "defPD" , "defINT", "defFF", "defFR", "fantPts", "fantPts.G")
      stats$Pos<-"LB"
    }else if(PosID==70){
      colnames(stats)<-c("Player", "Team", "G", "defSOLO", 'defAST',"defSACK", "defPD" , "defINT", "defFF", "defFR", "fantPts", "fantPts.G")
      stats$Pos<-"DB"
    }else if(PosID==80){
      colnames(stats)<-c("Player", "Team", "G", "kickFGM", 'kickFGA',"kickFG.", "kickXPM" , "kickXPA", "fantPts", "fantPts.G")
      stats$Pos<-"K"
    }else if(PosID==99){
      stats<-stats[, c(1,ncol(stats)-1, ncol(stats))]
      colnames(stats)<-c("Player", "fantPts" , "fantPts.G")
      stats$Team<-stats$Player
      stats$Pos<-"DST"
    }
    stats$Player<-page%>% html_nodes(".sort1 a")%>% html_text() #get rid of Rank in name
    stats$Season<-Season
  } else{
    stats<-data.frame()
  }
  stats
}
importGrid<-expand.grid(Season=2008:2018, PosID=c(seq(10, 80, 10), 99), Page=0:2)

fantasy.actuals<-ldply(lapply(1:nrow(importGrid), function(x) readActuals(Season = importGrid$Season[x],
                                                                          PosID = importGrid$PosID[x],
                                                                          Page=importGrid$Page[x])), data.frame)
fantasy.actuals[, !colnames(fantasy.actuals)%in% c("Player", "Team", "Pos")]<-
  sapply(fantasy.actuals[, !colnames(fantasy.actuals)%in% c("Player", "Team", "Pos")], function(x) as.numeric(gsub("[,]|[%]","", x)))
fantasy.actuals[is.na(fantasy.actuals)]<-0
table(fantasy.actuals$Season)


####ADP DATA FROM FFCALC######

readffcalc<-function(year, scoring="standard"){
  if(grepl("half", scoring)){
    scoring<-"half-ppr"
  }
  
  url<-paste(c("https://fantasyfootballcalculator.com/adp?format=", scoring, "&year=", year,"&teams=12&view=graph&pos=all"), sep="", collapse="")
  page<-read_html(url)
  stats<-page%>%html_table(fill=T)
  stats<-stats[[1]]
  if(ncol(stats)==11){
    colnames(stats)<-c("Rk", "Round", "Player", "Pos", "Team",  "ADP", "ADPSD","High", "Low", "TimesDrafted", "Graph" )
    
  } else{
    colnames(stats)<-c("Rk", "Round", "Player", "Pos", "Team", "Bye", "ADP", "ADPSD","High", "Low", "TimesDrafted", "Graph")
    
  }
  stats<-stats[, !grepl("High|Low|TimesDrafted|Graph|Rk|Round|Bye", colnames(stats))]
  stats$Season<-year
  colnames(stats)[colnames(stats)%in% c("ADP","ADPSD")]<-paste(c("ADP", "ADPSD"), gsub("andar", "", scoring), sep="_")
  stats$Pos[stats$Pos=="PK"]<-"K"
  stats$Pos[stats$Pos=="DEF"]<-"DST"
  stats
}
if(!exists("ffcalc")){
  ffcalc_ppr<-ldply(lapply(2010:2019, function(x) readffcalc(x, scoring="ppr")), data.frame)
  ffcalc_half<-ldply(lapply(2018:2019, function(x) readffcalc(x, scoring="half")), data.frame)
  ffcalc_std<-ldply(lapply(2007:2019, readffcalc), data.frame)
  ffcalc<-Reduce(function(x, y) merge(x, y, all=TRUE,  by=c("Player", "Pos","Team", "Season")), list(ffcalc_std, ffcalc_half, ffcalc_ppr))
  colnames(ffcalc)<-gsub("[.]ppr", "",colnames(ffcalc))
  
} else{
  ffcalc_ppr<-ldply(lapply(2019, function(x) readffcalc(x, scoring="ppr")), data.frame)
  ffcalc_half<-ldply(lapply(2019, function(x) readffcalc(x, scoring="half")), data.frame)
  ffcalc_std<-ldply(lapply(2019, readffcalc), data.frame)
  ffcalc2<-Reduce(function(x, y) merge(x, y, all=TRUE,  by=c("Player", "Pos","Team", "Season")), list(ffcalc_std, ffcalc_half, ffcalc_ppr))
  ffalc<-rbind.fill(ffcalc2, ffcalc[ffcalc$Season!=2019,])
}

ffcalc$ADP_half[is.na(ffcalc$ADP_half)]<-rowMeans(ffcalc[is.na(ffcalc$ADP_half), c("ADP_std", "ADP_ppr")], na.rm=T)
ffcalc$ADPSD_half[is.na(ffcalc$ADPSD_half)]<-rowMeans(ffcalc[is.na(ffcalc$ADPSD_half), c("ADPSD_std", "ADPSD_ppr")], na.rm=T)
ffcalc[ffcalc$Season==2007, grepl("SD", colnames(ffcalc))]<-NA
ffcalc$ADPSD_half[ffcalc$ADPSD_half>30]<-30
plot(ffcalc$ADPSD_half~ffcalc$ADP_half)
ffcalc<-ffcalc[order(ffcalc$Season, ffcalc$ADP_half, decreasing = F), ]
ffcalc[ffcalc$Season==2007,][1:30,]
ffcalc[, c("Team", "Player")]<-sapply(ffcalc[, c("Team", "Player")], coordName)

head(ffcalc[ffcalc$Season==2019,]) #ADP data




#save everything
save(list=c("FDATA_SEASONAL", "FFANALYTICS", "FFTODAY",
            "ffcalc", "fantasy.actuals"), file="Data/Fantasy Data.RData")

