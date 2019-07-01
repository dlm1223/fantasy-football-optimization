###DRAFT PICK OPTIMIZATION#####

#customPicks imputes a custom pick string for specified slot. useful for estimating draft trades
getPickDF<-function(slot="Slot4", numPicks=15, numTeams=12, customPicks=c()){
  pickDF<-data.frame(matrix(NA, ncol=numTeams, nrow=numPicks))
  colnames(pickDF)<-paste("Slot", 1:numTeams, sep="")
  last<-0
  for(i in 1:numPicks){
    if(i%%2==1){
      pickDF[i, ]<-(last+1):(last+numTeams)
    }else{
      pickDF[i, ]<-(last+numTeams):(last+1)
      
    }
    last<-last+numTeams
  }
  #optional: provide custom picks to account for a draft-pick trade
  if(length(customPicks)>0){
    pickDF[1:length(customPicks), slot]<-customPicks
  }
  pickDF
}

getPicks<-function(data=data,slot="Slot7",numTeams=12, numRB=5, numWR=5, numTE=1, numQB=2,numK=1,numDST=1, numFLEX=0,  shift=0,customPicks=c(),
                   out=c(), fix=c(), scoring="fantPts_AGG",outPos=c(),onePos=c()
){
  #comment out to test params
  #data<-all.data[all.data$Season==2019,];slot<-"Slot5";numRB<-5;numWR<-5;numTE<-1;numQB<-1;numK<-1;numFLEX<-1;numDST<-1;shift<-0;outPos=c();onePos=c();out<-c();fix<-c();scoring<-"fantPts_AGG";numTeams<-12;customPicks<-c()
  
  numPicks<-numRB+numQB+numWR+numTE+numFLEX+numDST+numK
  pickDF<-getPickDF(slot=slot, numPicks = numPicks, numTeams = numTeams, customPicks = customPicks)
  
  model <- list()
  optmode<-'lpsolve'
  A<-matrix(0, ncol=nrow(data), nrow=1000) #cols=decision variables, rows=constraints on variables
  model$obj<-data[, scoring]  #goal to maximize sum of FPTS for chosen variables
  model$modelsense <- "max"
  
  #position constraints
  q<-1
  A[q, grep("RB", data$Pos)]<-1; model$sense[q]<-">="; model$rhs[q]<-numRB;q<-q+1 #>=2 RBs
  A[q, grep("WR", data$Pos)]<-1; model$sense[q]<-">="; model$rhs[q]<-numWR;q<-q+1 #>=3 WRs
  A[q, grep("TE", data$Pos)]<-1; model$sense[q]<-">="; model$rhs[q]<-numTE;q<-q+1 
  A[q, grep("QB", data$Pos)]<-1; model$sense[q]<-">="; model$rhs[q]<-numQB;q<-q+1
  A[q, grep("K", data$Pos)]<-1; model$sense[q]<-">="; model$rhs[q]<-numK;q<-q+1 
  A[q, grep("DST", data$Pos)]<-1; model$sense[q]<-">="; model$rhs[q]<-numDST;q<-q+1
  A[q, grep("WR|RB|TE", data$Pos)]<-1; model$sense[q]<-">="; model$rhs[q]<-numRB+numWR+numTE+numFLEX;q<-q+1
  
  A[q, 1:nrow(data)]<-1; model$sense[q]<-"<="; model$rhs[q]<-numPicks;q<-q+1 #constrain total numPicks
  
  A[q, data$Player%in% out]<-1; model$sense[q]<-"<="; model$rhs[q]<-0;q<-q+1 #constrain total numPicks
  A[q, data$Player%in% fix]<-1; model$sense[q]<-">="; model$rhs[q]<-sum( data$Player%in% fix);q<-q+1 #constrain total numPicks
  
  
  #1st pick needs 15 players with adp greater than it. 2nd pick needs 14 players with adp greater than it. etc.
  tot<-numPicks
  for(i in 1:numPicks){
    storePick<-pickDF[i, slot]
    A[q, which(data[,"ADP.Rank"]*(1-shift)>=storePick)]<-1; model$sense[q]<-">="; model$rhs[q]<-tot;q<-q+1  
    tot<-tot-1 
  }
  
  #onePos param. must include a player with adp greater than or equal to pick number 
  if(length(onePos)>=1){
    storePick<-pickDF[length(onePos)+1, slot]
    A[q, which(data[,"ADP.Rank"]*(1-shift)<storePick& data$Pos==onePos[1])]<-1; model$sense[q]<-"="; model$rhs[q]<-1;q<-q+1  
  }
  
  #outpos param. exclude players
  if(length(outPos)>=1){
    storePick<-pickDF[length(outPos)+1, slot]
    A[q, which(data[,"ADP.Rank"]*(1-shift)<storePick& data$Pos==outPos[1])]<-1; model$sense[q]<-"<="; model$rhs[q]<-0;q<-q+1
  }
  
  # model$vtype   <- 'B'
  # params <- list(OutputFlag=0)
  # model$A<-A[1:(q-1),]
  
  result<-lp ("max", objective.in=model$obj, const.mat=A[1:(q-1),],
              const.dir=model$sense, const.rhs=model$rhs, all.bin=TRUE )
  result$x<-result$solution
  
  picks<-data[as.logical(result$x),]
  picks$Slot<-pickDF[, slot]
  picks
}


simSeason<-function(picks,data=all.data, numRB=2, numWR=2, numTE=1, numQB=1, numK=1, numDST=1, numFLEX=1,numSims=1,
                    returnLineup=F, fa.param=4, scoring="fantPts_AGG"){
  
  #picks<-picks1;numRB<-2; numWR<-2; numTE<-1; numQB<-1; numK<-1; numDST<-1; numFLEX<-1;numSims<-1000;data=all.data
  #get all possible Player.Sample.Values for players in picks.. doing this so don't have to re-reference back to original data for each sample:
  picks$Player.Sample.Values<-lapply(1:nrow(picks), function(x){
    data$Error[which(data$fantPts_AGG.bin==picks$fantPts_AGG.bin[x]& data$Pos==picks$Pos[x]& !is.na(data$Error))]
  })
  
  #simPicks..simulate each player's score based on their Player.Sample.Values. repeat for each numSims
  simPicks<-function(picks){
    
    #sample errors from entire data, not just given year
    picks$error<-sapply(1:nrow(picks), function(x){
      sample(picks$Player.Sample.Values[[x]], 1)
    })
    picks$Sim<-picks[,scoring]+picks$error
    picks$Sim[picks$Sim<0]<-0
    picks$Pickup<-0
    picks[, !colnames(picks)%in% "Player.Sample.Values"]
  }
  #repeat n=numSims
  picks<-lapply(1:numSims,function(x) simPicks(picks))
  
  #Player.Sample.Values for undrafted players
  undrafted<-data[is.na(data$ADP_half)& data$Season==picks[[1]]$Season[1]& !data$Player%in% picks[[1]]$Player,]
  undrafted$Player.Sample.Values<-lapply(1:nrow(undrafted), function(x){
    data$Error[which(data$fantPts_AGG.bin==undrafted$fantPts_AGG.bin[x]& data$Pos==undrafted$Pos[x]& !is.na(data$Error))]
  })
  
  
  simFAs<-function(undrafted,data, fa.param){
    
    undrafted$error<-sapply(1:nrow(undrafted), function(x){
      sample(undrafted$Player.Sample.Values[[x]], 1)
    })
    undrafted$Sim<-undrafted[, scoring]+undrafted$error
    undrafted$Sim[undrafted$Sim<0]<-0
    
    #assuming i can get the 4-th best player at each position--this is a param i can change
    # this is reasonably because if I am lacking at a position, I will have a decent chance of getting it
    undrafted<-undrafted[order(undrafted$Sim, decreasing = T),]
    fa.pickups<-c(which(undrafted$Pos=="QB")[fa.param],
                  which(undrafted$Pos=="RB")[fa.param],
                  which(undrafted$Pos=="WR")[fa.param],
                  which(undrafted$Pos=="TE")[fa.param],
                  which(undrafted$Pos=="DST")[fa.param],
                  which(undrafted$Pos=="K")[fa.param])
    fa.pickups<-undrafted[fa.pickups, ]
    fa.pickups$Pickup<-1
    fa.pickups[, !colnames(fa.pickups)%in% "Player.Sample.Values"]
  }
  #system.time({
    #get fa.pickips for each sim
  fa.pickups<-lapply(1:numSims, function(x) simFAs(undrafted =undrafted, data=data, fa.param = fa.param)) 
  #})
  
  #rbind FAs and picks for each sim
  picks2<-lapply(1:numSims, function(x) data.frame(rbindlist(list(picks[[x]], fa.pickups[[x]]), fill=T)))
  
  
  #get top lineup from FAs and picks for each sim
  getLineup<-function(picks2,numRB, numWR, numTE, numQB, numK, numDST, numFLEX){
    
    #from drafted players and pickups, return top Starting Lineup
    #get top lineup from Sims
    picks2<-picks2[order(picks2$Sim, decreasing = T),]
    for(i in c("RB", "WR", "TE", "QB", "DST", "K")){
      picks2[, i]<-ifelse(grepl(i, picks2$Pos), cumsum(grepl(i, picks2$Pos)), NA)
    }
    starters<-picks2[which(picks2$RB<=numRB| picks2$WR<=numWR| picks2$QB<=numQB|picks2$DST<=numDST| picks2$TE<=numTE| picks2$K<=numK),] #starters
    flex<-picks2[which(!picks2$Player%in% starters$Player&grepl("RB|WR|TE", picks2$Pos)),][1,] #flex
    
    result<-list(x=as.numeric(picks2$Player%in% c(starters$Player, flex$Player)))
    
    topLineup<-picks2[as.logical(result$x),!colnames(picks2)%in% c("RB", "WR", "TE", "QB", "DST", "K")]
    topLineup
  }
  topLineups<-lapply(picks2, function(x) getLineup(x, numRB=numRB, numWR=numWR, numTE=numTE, numQB=numQB,
                                                   numK=numK, numDST=numDST, numFLEX=numFLEX))
  #return top lineups
  topLineups
  
}

