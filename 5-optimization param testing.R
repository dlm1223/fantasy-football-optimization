source("2-organize data.R")
source("3-optimization errors.R")
source("4-optimization optimize.R")
errors[order(errors$fantPts_AGG.bin, decreasing = T),]

all.data<-all.data[, !grepl("[.]G", colnames(all.data))& !grepl("ADPSD", colnames(all.data))] #clean columns

#must define getPicks() and simSeason() functions from 4-optimization optimize.R



###ALL SLOTS######


simSlot<-function(slot){
  print(slot)
  scoring<-"fantPts_AGG"
  
  #default
  picks1<-getPicks(slot=slot, data=all.data[all.data$Season==2019,], numTeams = 12,customPicks = c(),
                   numRB=4, numWR = 5,numTE=2,numQB=2,numK=1, numDST=1,numFLEX = 0,shift=0,  out=c(), fix=c(), scoring=scoring)
  picks1
  topLineups1<-simSeason(picks = picks1, data=all.data, scoring=scoring,numSims=2000,
                         numRB = 2, numWR=2, numFLEX = 1, numQB=1, numTE = 1, numDST = 1, numK = 1   )
  simScores1<-sapply(topLineups1, function(x) sum(x$Sim))
  plot(cummean(simScores1))
  summary(simScores1)
  
  #default , no backup TE
  picks2<-getPicks(slot=slot, data=all.data[all.data$Season==2019,], numTeams = 12,customPicks = c(),
                   numRB=5, numWR = 5,numTE=1,numQB=2,numK=1, numDST=1,numFLEX = 0,shift=0,  out=c(), fix=c(), scoring=scoring)
  picks2
  topLineups2<-simSeason(picks = picks2, data=all.data, scoring=scoring,numSims=2000,
                         numRB = 2, numWR=2, numFLEX = 1, numQB=1, numTE = 1, numDST = 1, numK = 1   )
  simScores2<-sapply(topLineups2, function(x) sum(x$Sim))
  summary((simScores2))
  
  
  #default, no backup QB
  picks3<-getPicks(slot=slot, data=all.data[all.data$Season==2019,], numTeams = 12,customPicks = c(),
                   numRB=5, numWR = 5,numTE=2,numQB=1,numK=1, numDST=1,numFLEX = 0,shift=0,  out=c(), fix=c(), scoring=scoring)
  picks3
  topLineups3<-simSeason(picks = picks3, data=all.data, scoring=scoring,numSims=2000,
                         numRB = 2, numWR=2, numFLEX = 1, numQB=1, numTE = 1, numDST = 1, numK = 1   )
  simScores3<-sapply(topLineups3, function(x) sum(x$Sim))
  summary((simScores3))
  
  
  #zero RB in 1-3
  picks4<-getPicks(slot=slot, data=all.data[all.data$Season==2019,], numTeams = 12,customPicks = c(),outPos = rep("RB",3),
                   numRB=5, numWR = 4,numTE=2,numQB=2,numK=1, numDST=1,numFLEX = 0,shift=0,  out=c(), fix=c(), scoring=scoring)
  picks4
  topLineups4<-simSeason(picks = picks4, data=all.data, scoring=scoring,numSims=2000,
                         numRB = 2, numWR=2, numFLEX = 1, numQB=1, numTE = 1, numDST = 1, numK = 1   )
  topLineups4[[33]]
  simScores4<-sapply(topLineups4, function(x) sum(x$Sim))
  plot(cummean(simScores4))
  # hist(simScores4)
  
  
  #one RB in R1-5. 
  picks5<-getPicks(slot=slot, data=all.data[all.data$Season==2019,], numTeams = 12,customPicks = c(),onePos = rep("RB",5),
                   numRB=5, numWR = 3,numTE=2,numQB=2,numK=1, numDST=1,numFLEX = 0,shift=0,  out=c(), fix=c(), scoring=scoring)
  picks5
  topLineups5<-simSeason(picks = picks5, data=all.data, scoring=scoring,numSims=2000,
                         numRB = 2, numWR=2, numFLEX = 1, numQB=1, numTE = 1, numDST = 1, numK = 1   )
  topLineups5[[33]]
  simScores5<-sapply(topLineups5, function(x) sum(x$Sim))
  plot(cummean(simScores5))
  
  #zero WR in R1-3
  picks6<-getPicks(slot=slot, data=all.data[all.data$Season==2019,], numTeams = 12,customPicks = c(),outPos = rep("WR",3),
                   numRB=4, numWR = 5,numTE=2,numQB=2,numK=1, numDST=1,numFLEX = 0,shift=0,  out=c(), fix=c(), scoring=scoring)
  picks6
  topLineups6<-simSeason(picks = picks6, data=all.data, scoring=scoring,numSims=2000,
                         numRB = 2, numWR=2, numFLEX = 1, numQB=1, numTE = 1, numDST = 1, numK = 1   )
  simScores6<-sapply(topLineups6, function(x) sum(x$Sim))
  plot(cummean(simScores6))
  
  #one WR in R1-5
  picks7<-getPicks(slot=slot, data=all.data[all.data$Season==2019,], numTeams = 12,customPicks = c(),onePos=rep("WR", 5),
                   numRB=4, numWR = 5,numTE=2,numQB=2,numK=1, numDST=1,numFLEX = 0,shift=0,  fix=c(),  out=c(),  scoring=scoring)
  picks7
  topLineups7<-simSeason(picks = picks7, data=all.data, scoring=scoring,numSims=2000,
                         numRB = 2, numWR=2, numFLEX = 1, numQB=1, numTE = 1, numDST = 1, numK = 1   )
  simScores7<-sapply(topLineups7, function(x) sum(x$Sim))
  summary(simScores7)
  
  
  #zero QB R1-9
  picks8<-getPicks(slot=slot, data=all.data[all.data$Season==2019,], numTeams = 12,customPicks = c(),outPos=rep("QB",9),
                   numRB=4, numWR = 5,numTE=2,numQB=2,numK=1, numDST=1,numFLEX = 0,shift=0,  fix=c(),  out=c(),  scoring=scoring)
  picks8
  topLineups8<-simSeason(picks = picks8, data=all.data, scoring=scoring,numSims=2000,
                         numRB = 2, numWR=2, numFLEX = 1, numQB=1, numTE = 1, numDST = 1, numK = 1   )
  simScores8<-sapply(topLineups8, function(x) sum(x$Sim))
  plot(cummean(simScores8))
  summary(simScores8)
  topLineups8[[3]]
  
  #backup everyone!
  picks9<-getPicks(slot=slot, data=all.data[all.data$Season==2019,], numTeams = 12,customPicks = c(),fix=c(), 
                   numRB=3, numWR = 4,numTE=2,numQB=2,numK=2, numDST=2,numFLEX = 0,shift=0,  out=c(),  scoring=scoring)
  picks9
  topLineups9<-simSeason(picks = picks9, data=all.data, scoring=scoring,numSims=2000,
                         numRB = 2, numWR=2, numFLEX = 1, numQB=1, numTE = 1, numDST = 1, numK = 1   )
  simScores9<-sapply(topLineups9, function(x) sum(x$Sim))
  plot(cummean(simScores9))
  summary(simScores9)
  
  #draft a TE in first 2 rounds
  picks10<-getPicks(slot=slot, data=all.data[all.data$Season==2019,], numTeams = 12,customPicks = c(),fix = c(),onePos=rep("TE", 2),
                    numRB=4, numWR =5 ,numTE=2,numQB=2,numK=1, numDST=1,numFLEX = 0,shift=0,  out=c(),  scoring=scoring)
  picks10
  topLineups10<-simSeason(picks = picks10, data=all.data, scoring=scoring,numSims=2000,
                          numRB = 2, numWR=2, numFLEX = 1, numQB=1, numTE = 1, numDST = 1, numK = 1   )
  simScores10<-sapply(topLineups10, function(x) sum(x$Sim))
  plot(cummean(simScores10))
  summary(simScores10)
  
  
  #return all.sims
  
  all.sims<-data.frame(simScores1, simScores2, simScores3, simScores4,simScores5, simScores6, simScores7, simScores8, simScores9, simScores10   )
  all.sims<-melt(all.sims,value.name = "Lineup.Score", variable.name = "Sim" )
  all.sims$Slot<-slot
  all.sims
}


#each slot takes ~3 mins to run all its strategies so will probably take around 30 mins to run this
all.slot.sims<-ldply(lapply(paste("Slot", 1:12, sep=""),simSlot ), data.frame)
save(all.slot.sims, file="Data/all-slot-sims.Rda")



means<-ddply(all.slot.sims, .(Slot, Sim),summarize,
             mean.score=mean(Lineup.Score), 
             sd.score=sd(Lineup.Score), 
             high.score=sum(Lineup.Score>1900)/length(Lineup.Score))
means$Slot<-factor(means$Slot, levels=paste0("Slot", 1:12))
means[order(means$Slot),]
