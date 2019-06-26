
#has coordName() function to coordinate teams and players

library(RSelenium)
# library(lme4)
# library(png)
# library(grid)
# library(doSNOW)
library(plyr)
library(dplyr)
library(rvest)
library(ggplot2)
library(data.table)
library(XML)
library(lubridate)
library(lpSolve)
library(zoo)
library(MASS)
library(stringi)
options(stringsAsFactors = F, scipen =999)

simpleCap <- function(x) {
  s <- strsplit(x, " ")[[1]]
  paste(toupper(substring(s, 1,1)), tolower(substring(s, 2)),
        sep="", collapse=" ")
}
unwanted_array <- list(    'Š'='S', 'š'='s', 'Ž'='Z', 'ž'='z', 'À'='A', 'Á'='A', 'Â'='A', 'Ã'='A', 'Ä'='A', 'Å'='A', 'Æ'='A', 'Ç'='C', 'È'='E', 'É'='E',
                           'Ê'='E', 'Ë'='E', 'Ì'='I', 'Í'='I', 'Î'='I', 'Ï'='I', 'Ñ'='N', 'Ò'='O', 'Ó'='O', 'Ô'='O', 'Õ'='O', 'Ö'='O', 'Ø'='O', 'Ù'='U',
                           'Ú'='U', 'Û'='U', 'Ü'='U', 'Ý'='Y', 'Þ'='B', 'ß'='Ss', 'à'='a', 'á'='a', 'â'='a', 'ã'='a', 'ä'='a', 'å'='a', 'æ'='a', 'ç'='c',
                           'è'='e', 'é'='e', 'ê'='e', 'ë'='e', 'ì'='i', 'í'='i', 'î'='i', 'ï'='i', 'ð'='o', 'ñ'='n', 'ò'='o', 'ó'='o', 'ô'='o', 'õ'='o',
                           'ö'='o', 'ø'='o', 'ù'='u', 'ú'='u', 'û'='u', 'ý'='y', 'ý'='y', 'é'='e', '«'='' )

####ABBREVIATIONS###
abbrev<-read.csv("Data/Abbrev.txt", sep="\t", header=TRUE, row.names = NULL)
abbrev$Abbrev2<-unlist(lapply(strsplit(abbrev$FullName, " "), function(x) paste(x[-length(x)], collapse=" ")))
abbrev$Abbrev2[abbrev$Abbrev=="NYJ"]<-"N.Y. Jets"
abbrev$Abbrev2[abbrev$Abbrev=="NYG"]<-"N.Y. Giants"
abbrev$Abbrev<-sapply(abbrev$Abbrev, simpleCap)
abbrev$Abbrev[abbrev$Abbrev%in% c("Gb", "Kc", "La", "Ne", "No", "Sd","Sf", "Tb")]<-
  c("Gnb", "Kan", "Lar", "Nwe", "Nor", "Sdg", "Sfo", "Tam")
abbrev$Abbrev3<-tolower(abbrev$Abbrev)
abbrev$Abbrev3[abbrev$Abbrev3=="ari"]<-"crd"
abbrev$Abbrev3[abbrev$Abbrev3=="bal"]<-"rav"
abbrev$Abbrev3[abbrev$Abbrev3=="hou"]<-"htx"
abbrev$Abbrev3[abbrev$Abbrev3=="ind"]<-"clt"
abbrev$Abbrev3[abbrev$Abbrev3=="oak"]<-"rai"
abbrev$Abbrev3[abbrev$Abbrev3=="ten"]<-"oti"
abbrev$Abbrev3[abbrev$Abbrev3=="stl"|abbrev$Abbrev3=="lar"|abbrev$Abbrev3=="la"]<-"ram"



#https://stackoverflow.com/questions/20495598/replace-accented-characters-in-r-with-non-accented-counterpart-utf-8-encoding


coordName<-function(x) {
  x<-chartr(paste(names(unwanted_array), collapse=''),
            paste(unwanted_array, collapse=''),
            x)
  
  x[x%in% abbrev$Abbrev]<-abbrev$Abbrev[match(x[x%in% abbrev$Abbrev], abbrev$Abbrev)]
  x[x%in% abbrev$Abbrev2]<-abbrev$Abbrev[match(x[x%in% abbrev$Abbrev2], abbrev$Abbrev2)]
  x[x%in% abbrev$Abbrev3]<-abbrev$Abbrev[match(x[x%in% abbrev$Abbrev3], abbrev$Abbrev3)]
  x[x%in% abbrev$FullName]<-abbrev$Abbrev[match(x[x%in% abbrev$FullName], abbrev$FullName)]
  
  x<-gsub("^\\s+|\\s+$", "", x)
  x<-gsub(" Jr.| Sr.","",x)
  x<-gsub("*|+|`", "",x)
  x<-gsub("[*]|[`]", "",x)
  x<-gsub("[+]", "",x)
  x<-gsub(", Jr.", " Jr.", x)
  x<-gsub("[.]|[']|[,]", "", x)
  x<-gsub(" Jr", "", x)
  x<-gsub(" Sr", "", x)
  x<-gsub(" III| Iii", "", x)
  x<-gsub(" IV", "", x)
  x<-gsub(" II| Ii", "", x)
  x<-gsub("-", " ", x)
  x<-gsub("  ", " ", x)
  
  x<-gsub("R J ", "RJ ", x)
  x<-gsub("D J ", "DJ ", x)
  x<-gsub("E J ", "EJ ", x)
  x<-gsub("T J ", "TJ ", x)
  x<-gsub("D J ", "DJ ", x)
  
  
  x<-gsub("De'Andre", "DeAndre", x)
  x<-gsub("Le'Ron", "LeRon", x)
  
  
  x<-sapply(x,simpleCap)
  x<-gsub("Zac |Zack |Zachary |Zackary ", "Zach ", x)
  x<-gsub("Johnathan |Jon |John ", "Jonathan ", x)
  x<-gsub("Christopher ", "Chris ", x)
  x<-gsub("Billy ", "Bill ", x)
  x<-gsub("Deshone", "DeShone", x)
  x<-gsub("Khalif", "Kalif", x)
  x<-gsub("Gerell", "Gerrell", x)
  x<-gsub("Mitch ", "Mitchell ", x)
  x<-gsub("William ", "Will ", x)
  x<-gsub("Pat ", "Patrick ", x)
  x<-gsub("Alex ", "Alexander ", x)
  x<-gsub("Jimmy ", "Jim ", x)
  x<-gsub("Thad ", "Thaddeus ", x)
  x<-gsub("Tim |Timothhy |Timmy ", "Timothy ", x)
  x<-gsub("Matt ", "Matthew ", x)
  x<-gsub("Nathan |Nathaniel ", "Nate ", x)
  x<-gsub("Joe ", "Joseph ", x)
  x<-gsub("Shaquelle |Shaquille |Shaquil ", "Shaq ", x)
  x<-gsub("Johnnie Lee ", "Johnnielee ", x)
  x<-gsub("Josh ", "Joshua ", x)
  x<-gsub("Rich ", "Richard ", x)
  x<-gsub("Mike |mike ", "Michael ", x)
  x<-gsub("Rob ", "Robert ", x)
  x<-gsub("Samuel ", "Sam ", x)
  x<-gsub("Nicholas |Nicolas |Nic ", "Nick ", x)
  x<-gsub("Daniel |Danny ", "Dan ", x)
  x<-gsub("Stevie ", "Steve ", x)
  x<-gsub("Brad ", "Bradley ", x)
  x<-gsub("Walt ", "Walter ", x)
  x<-gsub("Trenton ", "Trent ", x)
  x<-gsub("Edward ", "Ed ", x)
  x<-gsub("Ronald ", "Ron ", x)
  x<-gsub("Isreal ", "Israel ", x)
  x<-gsub("Vincent ", "Vince ", x)
  x<-gsub("Dave ", "David ", x)
  x<-gsub("Rodrick |Roderick ", "Rod ", x)
  x<-gsub("Ben |Benny ", "Benjamin ", x)
  x<-gsub("Brenden ", "Brendan ", x)
  x[ grepl("Odell", x) & grepl("Beckham", x)]<-"Odell Beckham"  
  x[x==  "Evan Dietrich Smith"]<-"Evan Smith"
  x[x==  "Chris Kirksey"]<-"Christian Kirksey"
  x[x==  "Antwon Blake"]<-"Valentino Blake"
  x[x==  "Joseph Lefeged"]<-"Joseph Young"
  x[x==  "Lac Edwards"]<-"Lachlan Edwards"
  x[x==  "Cb Bryant"]<-"Christian Bryant"
  x[x==  "Leterrius Walton"]<-"Lt Walton"
  x[x==  "Nordly Capi"]<-"Cap Capi"
  x[x==  "Jacob Schum"]<-"Jake Schum"
  x[x==  "Owamagbe Odighizuwa"]<-"Owa Odighizuwa"
  x[x==  "Ricky Wagner"]<-"Rick Wagner"
  x[x==  "Gator Hoskins"]<-"Harold Hoskins"
  x[x==  "Vladimir Ducasse"]<-"Vlad Ducasse"
  x[x==  "Dejonathan Gomes"]<-"Dejon Gomes"
  x[x==  "Dajonathan Harris"|x=="Dajon Harris"|x=="DaJohnathan Harris"|x=="DaJohn Harris"]<-"Dajohn Harris"
  x[x==  "Jeffrey Linkenbach"]<-"Jeff Linkenbach"
  x[x==  "Manuel Ramirez"]<-"Manny Ramirez"
  x[x==  "Herbert Taylor"]<-"Herb Taylor"
  x[x==  "Ike Ndukwe"]<-"Ikechuku Ndukwe"
  x[x==  "Nate Arthur Byham"]<-"Nate Byham"
  x[x==  "Vic Worsley"]<-"Victor Worsley"
  x[x==  "Baba Oshinowo"]<-"Babatunde Oshinowo"
  x[x==  "Bam Childress"]<-"Brandon Childress"
  x[x==  "Steve Cheek"]<-"Stephen Cheek"
  x[x==  "Steve Neal"]<-"Stephen Neal"
  x[x==  "Renaud Williams"]<-"Renauld Williams"
  x[x==  "Woody Dantzler"]<-"Woodrow Dantzler"
  x[x==  "Raymond Perryman"]<-"Ray Perryman"
  x[x==  "Jj Huggins"]<-"Johnny Huggins"
  x[x==  "Abdul Karim Al Jabbar"]<-"Karim Abdul Jabbar"
  x[x==  "Maugaula Tuitele"]<-"Ula Tuitele"
  x[x==  "Rocket Ismail"]<-"Raghib Ismail"
  x[x==  "Michael A Jones"]<-"Michael Jones"
  x[x==  "T Marcus Spriggs"]<-"Marcus Spriggs"
  x[x==  "Tyrone M Williams"]<-"Tyrone Williams"
  x[x=="Eman Sanders"]<-"Emmanuel Sanders"
  x[x=="Bishop Stankey"]<-"Bishop Sankey"
  x[x=="Jarret Boykin"]<-"Jarrett Boykin"
  x[x=="Kadem Carrey"]<-"Kadeem Carey"
  x[x=="Brendan Lefell"]<-"Brandon Lafell"
  x[x=="Ezekial Ansah"]<-"Ezekiel Ansah"
  x[x=="Jarius Byrd"]<-"Jairus Byrd"
  x[x=="Devis Harris"]<-"David Harris"
  x[x=="Ryan Matthews"]<-"Ryan Mathews"
  x[x=="Levonte David"]<-"Lavonte David"
  x[x=="Gio Bernard"]<-"Giovani Bernard"
  x[x=="Steven Haushka"|x=="Steve Hauschka"]<-"Steven Hauschka"
  x[x=="Cordarelle Patterson"]<-"Cordarrelle Patterson"
  x[x=="Luke Kueckly"]<-"Luke Kuechly"
  x[x=="Paul Worrliow"]<-"Paul Worrilow"
  x[x=="Micheal Floyd"]<-"Michael Floyd"
  x[x=="Odell Beckam"]<-"Odell Beckham"
  x[x=="Kennan Allen"]<-"Keenan Allen"
  x[x=="Ryan Tannehil"]<-"Ryan Tannehill"
  
  
  x[x==  "Greg K Jones"]<-"Greg Jones"
  x[x==  "Todd F Collins"]<-"Todd Collins"
  x[x==  "Kevin R Williams"]<-"Kevin Williams"
  x[x==  "Charles L Johnson"]<-"Charles Johnson"
  x[x==  "Michael L Lewis"]<-"Michael Lewis"
  x[x==  "Andre Hal"]<-"Andre Hall"
  x[x==  "R Jay Soward"]<-"Rjay Soward"
  x[x==  "Dede Dorsey"|x=="DeDe Dorsey"]<-"De Dorsey"
  x[x==  "Scott Vines"]<-"Scottie Vines"
  x[x==  "N D Kalu"]<-"ND Kalu"
  x[x==  "Will Peterson"]<-"Will James"
  x[x==  "AD Denham"]<-"Anthony Denham"
  x[x==  "Joseph Davenport"]<-"Joseph Dean Davenport"
  x[x==  "Derek M Smith"]<-"Derek Smith"
  x[x==  "Stephen Hauschka"]<-"Steven Hauschka"
  x[x==  "Roosevelt Williams"]<-"Roe Williams"
  x[x==  "Oshiomogho Atogwe"]<-"Oj Atogwe"
  x[x==  "Jolonn Dunbar"]<-"Jo Lonn Dunbar"
  x[x==  "Standford Keglar"]<-"Stanford Keglar"
  x[x==  "Chinedum Ndukwe"]<-"Nedu Ndukwe"
  x[x==  "Dwight Bentley"]<-"Bill Bentley"
  x[x==  "Ray Ventrone"]<-"Raymond Ventrone"
  x[x==  "Jay Elliott"]<-"Jayrone Elliott"
  x[x==  "Sammie Hill"]<-"Sammie Lee Hill"
  x[x==  "Cameron Cleeland"]<-"Cam Cleeland"
  x[x==  "Tony Hargrove"]<-"Anthony Hargrove"
  x[x==  "Ed Hartwell"]<-"Edgerton Hartwell"
  x[x==  "Junior Siav"]<-"Junior Siavii"
  x[x==  "Jerry Attaochu"]<-"Jeremiah Attaochu"
  x[x==  "Jalen Tabor"]<-"Teez Tabor"
  x[x==  "Albert Fincher"]<-"Alfred Fincher"
  x[x==  "Pep Levingston"]<-"Lazarius Levingston"
  x[x==  "Hebron Fangupo"]<-"Loni Fangupo"
  x[x==  "Jay Ratliff"]<-"Jeremiah Ratliff"
  x[x==  "Macho Harris"]<-"Victor Harris"
  x[x==  "Juqua Thomas"]<-"Juqua Parker"
  x[x==  "Christion Jones"]<-"Christian Jones"
  x[x==  "Mo Alexander"]<-"Maurice Alexander"
  x[x==  "Malcolm Floyd"]<-"Malcom Floyd"
  x[x==  "Joseph Unga"]<-"Jj Unga"
  x[x==  "Jean Phillipe Darche"]<-"Jp Darche"
  x[x==  "Christian Mohr"]<-"Chris Mohr"
  x[x==  "Corderrelle Patterson"]<-"Cordarrelle Patterson"
  x[grepl( "Dom", x)& grepl("Rodgers", x)& grepl("romartie", x)]<-"Dominique Rodgers Cromartie"
  x[ grepl("Stallworth", x)& grepl("Donte", x)]<-"Donte Stallworth"
  x[ grepl("Priest", x)& grepl("Holmes", x)]<-"Priest Holmes"
  x[ grepl("David", x)& grepl("Givens", x)]<-"David Givens"
  x[ grepl("Chad", x)& grepl("Ocho", x)]<-"Chad Johnson"
  x[x==  "M White"]<-"Myles White"
  x[x==  "Nickell Robey"]<-"Nickell Robey Coleman"
  x[x==  "Deji Olatoye"]<-"Ayodeji Olatoye"
  x[x==  "Saverio Rocca"]<-"Sav Rocca"
  x[x==  "Travis Carrie"]<-"Tj Carrie"
  x[x==  "Jordan Dizon"]<-"Jordon Dizon"
  x[x==  "Dj Ware"]<-"Dan Ware"
  x[x==  "Donald Drer"]<-"Donald Driver"
  x[x==  "Ziggy Hood"]<-"Evander Hood"
  x[x==  "Ziggy Ansah"]<-"Ezekiel Ansah"
  x[x==  "Chris Dwightstone Jones"]<-"Chris Jones"
  x[x==  "Tony Dewayne Mcdaniel"]<-"Tony Mcdaniel"
  x[x==  "Don Juan Carey"]<-"Don Carey"
  x[x==  "Brian Jeffrey Mihalik"]<-"Brian Mihalik"
  x[x==  "Robert Chevis Nelson"]<-"Robert Nelson"
  x[x==  "Doug Oneal Middleton"]<-"Doug Middleton"
  x[x==  "Mickey Charles Shuler"]<-"Mickey Shuler"
  x[x==  "Lequan Letrell Lewis"]<-"Lequan Lewis"
  x[x==  "Andre Phillip Smith"]<-"Andre Smith"
  x[x==  "Jacque Cesaire"]<-"Jacques Cesaire"
  x[x==  "Boobie Dixon"]<-"Anthony Dixon"
  x[x==  "Andre Jerome Caldwell"]<-"Andre Caldwell"
  x[x==  "Devin Breaux"]<-"Delvin Breaux"
  x[x==  "Tyron Crawford"]<-"Tyrone Crawford"
  x[x==  "Cornellius Carradine"]<-"Tank Carradine"
  x[x==  "Hasean Clinton Dix"]<-"Ha Ha Clinton Dix"
  x[x==  "Ramon Humbar"]<-"Ramon Humber"
  x[x==  "Chad Ochocinco"]<-"Chad Johnson"
  x[x==  "Philip Rers"]<-"Philip Rivers"
  x[x==  "Tani Tupou"]<-"Taniela Tupou"
  x[x==  "Bobo Wilson"]<-"Jesus Wilson"
  x[x==  "John Paul Foschi"]<-"Jp Foschi"
  x[x==  "Danny Ware"]<-"Dj Ware"
  x[x==  "Jonathan Baldwin"]<-"Jon Baldwin"
  x[x==  "Chartric Darby"]<-"Chuck Darby"
  x[x==  "Trevor Graham"]<-"Tj Graham"
  x[x==  "J Talley"]<-"Julian Talley"
  x[x==  "Charles D Johnson"]<-"Charles Johnson"
  x[x==  "Seantavious Jones"]<-"Seantavius Jones"
  x[x==   "Will Fuller V"]<- "Will Fuller"
  x[x==   "Pacman Jones"]<- "Adam Jones"
  x[x==   "Broderick Bunkley"]<- "Brodrick Bunkley"
  x[x== "Evan Dietrich-Smith"  ]<-"Evan Smith" 
  x[x=="Philly Brown"  ]<-"Corey Brown"  
  x[x=="Zachdiles"  ]<-"Zach Diles"  
  x[x=="Leighton Vander"  ]<-"Leighton Vander Esch"  
  
  x[x=="Laurinaitis"]<-"James Laurinaitis"
  x[x=="Bradshaw"]<-"Ahmad Bradshaw"
  x[x==  "Samajae Perine"]<-"Samaje Perine"
  x[x==  "Phillip Rivers"]<-"Philip Rivers"
  x[x==  "Tedd Ginn"]<-"Ted Ginn"
  x[x==  "Alexander Ogletree"]<-"Alec Ogletree"
  x[x==  "Tony Jeffersom"]<-"Tony Jefferson"
  x[x==  "Vinateri"|x=="vinateri"|x=="Adam Vinateri"]<-"Adam Vinatieri"
  x[x==  "Khali Mack"|x=="Kahlil Mack"]<-"Khalil Mack"
  x[x==  "Wendall Smallwood"]<-"Wendell Smallwood"
  x[x==  "Alshon Jeffrey"]<-"Alshon Jeffery"
  x[x==  "Will Lutz"]<-"Wil Lutz"
  x[x==  "Risshard Matthews"]<-"Rishard Matthews"
  x[x==  "Joey Brosa"]<-"Joey Bosa"
  x[x==  "Giovanni Bernard"]<-"Giovani Bernard"
  x[x==  "Jim Grahm"]<-"Jim Graham"
  x[x==  "Hassan Reddick"]<-"Haason Reddick"
  x[x==  "Dein Jones"]<-"Deion Jones"
  x[x==  "James Connor"]<-"James Conner"
  x[x==  "Robbie Anderson"]<-"Robby Anderson"
  x[x==  "Terrence West"]<-"Terrance West"
  x[x==  "Jay Ajayii"]<-"Jay Ajayi"
  x[x==  "Isiah Crowell"]<-"Isaiah Crowell"
  x[x==  "Bernard Mckinney"]<-"Benardrick Mckinney"
  x[x==  "Paul Puz"|x=="Paul Posluzsny"|x=="Paul Posluzny"]<-"Paul Posluszny"
  x[x==  "Lagarette Blount"|x=="Legarette Blount"]<-"Legarrette Blount"
  x[x==  "Erik Decker"]<-"Eric Decker"
  x[x==  "Bilall Powell"]<-"Bilal Powell"
  x[x==  "Jedeveon Clowdney"|grepl("eon Clowney", x)]<-"Jadeveon Clowney"
  x[x==  "Mathew Stafford"]<-"Matthew Stafford"
  x[x==  "Chandler Carazano"]<-"Chandler Catanzaro"
  x[x==  "Navarro Bowman"]<-"Navorro Bowman"
  x[x==  "Emanuel Sanders"]<-"Emmanuel Sanders"
  x[x==  "Darren Mccfadden"]<-"Darren Mcfadden"
  x[x==  "James Laurinatis"]<-"James Laurinaitis"
  x[x==  "Gore"]<-"Frank Gore"
  x[x==  "Russel Wilson"]<-"Russell Wilson"
  x[x==  "Everson Griffin"]<-"Everson Griffen"
  x[x==  "Buck Allen"]<-"Javorius Allen"
  x[x==  "Reuben Randle"]<-"Rueben Randle"
  x[x==  "Derrick Jonhson"]<-"Derrick Johnson"
  x[x==  "Mo Wilkerson"]<-"Muhammad Wilkerson"
  x[x==  "Mcmanus"]<-"Brandon Mcmanus"
  x[x==  "Ryan Shaziwer"]<-"Ryan Shazier"
  x[x==  "Larry Donnel"]<-"Larry Donnell"
  x[x==  "Martellus Bennet"]<-"Martellus Bennett"
  x[x==  "Daniel Herron"]<-"Dan Herron"
  x[x==  "Juju Smithschuster"]<-"Juju Smith Schuster"
  x[x==  "Maurice Jonesdrew"]<-"Maurice Jones Drew"
  x[x==  "Steve Smith Sr"]<-"Steve Smith"
  x[x==  "Austin Seferianjenkins"]<-"Austin Seferian Jenkins"
  x[x==  "Jermain Kearse"]<-"Jermaine Kearse"
  x[x=='Lester Jean']<-'Lestar Jean'
  x[x=='Jeffery Wilson']<-'Jeff Wilson'
  x[endsWith( x," Sr")]<-gsub(" Sr", "", x[endsWith( x," Sr")])
  
  
  #madden data has lots of erors
  x[x=='Carnell Williams']<-"Cadillac Williams"
  x[x=='Benjamin Roethlisbergr']<-"Benjamin Roethlisberger"
  x[x=='Maurice Drew Jones']<-"Maurice Jones Drew"
  x[x=='Domanick Davis']<-"Domanick Williams"
  x[x=='Tj Houshmandz']<-"Tj Houshmandzadeh"
  x[x=='Chris Wells']<-"Tj Houshmandzadeh"
  x[x%in% c("London Fletcher Baker", "Londom Fletcher")]<-"London Fletcher"
  x[x=="Chis Long"]<-"Chris Long"
  x[x=='Arenas Williams']<-"Aeneas Williams"
  x[x=='Roosevelt Colvin']<-"Rosevelt Colvin"
  x[x=='Antonie Winfield']<-"Antoine Winfield"
  x[x=='Aquib Talib']<-"Aqib Talib"
  x[x=='Michael Barrow']<-"Micheal Barrow"
  x[x=='Freddie Keiaho']<-"Freddy Keiaho"
  x[x=='Lethon Flowers']<-"Lee Flowers"
  x[x=='Marcus Polland']<-"Marcus Pollard"
  x[x=='Andry Goodman']<-"Andre Goodman"
  x[x=='Al Singleton']<-"Alshermond Singleton"
  x[x=='Kimo Voelhoffen']<-"Kimo Von Oelhoffen"
  x[x=='Johnny Morton']<-"Johnnie Morton"
  x[x=='Greg White'|x=="Stylez White"]<-"Stylez G White"
  x[x=='Ndukwe Kalu']<-"Nd Kalu"
  x[x=='Ryan Lindell']<-"Rian Lindell"
  x[x=='Benard Pollard']<-"Bernard Pollard"
  x[x=='Amos Zereque']<-"Amos Zereoue"
  x[x=='Ryan Lindell']<-"Rian Lindell"
  x[x=='Donovan Darius']<-"Donovin Darius"
  x[x=='Willie Green']<-"Will Green"
  x[x=='Daymeion Hughes']<-"Dante Hughes"
  x[x=='Gregory Toler']<-"Greg Toler"
  x[x=='Darney Scott']<-"Darnay Scott"
  x[x=='Chris Fuamatu Mafala']<-"Chris Fuamatu Maafala"
  x[x=='Demetrius Bell']<-"Demetress Bell"
  x[x=='Matthew Mcbriar'|x=='Matt Mcbriar']<-"Mat Mcbriar"
  x[x=='Willie Henderson']<-"Will Henderson"
  x[x=='Vonte Leach']<-"Vonta Leach"
  x[x=='Phillip Wheeler']<-"Philip Wheeler"
  x[x=='Siitupe Peko']<-"Tupe Peko"
  x[x=='Chris Fuamatu Ma']<-"Chris Fuamatu Maafala"
  x[x=='Greg R Randall']<-"Greg Randall"
  x[x=='Barrett Robbins']<-"Barret Robbins"
  x[x=='Greg R Randall']<-"Greg Randall"
  x[x=='Owin Schmitt']<-"Owen Schmitt"
  x[x=='Jermaine Mayberry']<-"Jermane Mayberry"
  x[x=='Greg R Randall']<-"Greg Randall"
  x[x=='Clifton Ryan']<-"Cliff Ryan"
  x[x=='Marvin Smith']<-"Marvel Smith"
  x[x==  "David Alexander Gettis"]<-"David Gettis"
  x[x==  "Caleb Jeffrey Hanie"]<-"Caleb Hanie"
  x[x=="Willie Snead Iv"|x=="Willie Snead IV"]<-"Willie Snead"
  x[grepl("Chris Herndon", x)]<-'Chris Herndon'
  
  
  x[x=="Ne"]<-"NWE"
  x<-gsub(" Defense", "", x)
  x[x=="Ne"| grepl("Patriots", x)|x=="Nep"|x=="NEP"]<-"NWE"
  x[x=="Kc"| grepl("Chiefs", x)|x=="Kcc"|x=="KCC"]<-"KAN"
  x[x=="Gb" | grepl("Packers", x)|x=="GBP"|x=="Gbp"]<-"GNB"
  x[x=="Sd"| x=="Lac"|x=="LAC"| grepl("Chargers", x)| (grepl("ngeles", x)& grepl("LAC|lac|Lac", x))]<-"SDG"
  x[x=="No" |grepl("Saints",x)|x=="Nos"|x=="NOS"]<-"NOR"
  x[x=="Tb" | grepl("Buccaneers", x)|x=="Tbb"|x=="TBB"]<-"TAM"
  x[x=="Sf"| grepl("49ers", x)| grepl("San Francisco", x)]<-"SFO"
  x[x=="La"]<-"LAR"
  x[x%in% c("Rams", "St Louis", "Stl Rams", "Saint Louis Rams", "St Louis Rams", "La Rams", "Los Angeles Rams", "STL", "Stl")| 
      (grepl("ngeles", x)& grepl("lar|Lar|LAR", x))| grepl("Louis Rams|Angeles Rams", x)| grepl("Rams ", x)]<-"Lar"
  
  x[x=="Jac"|x=="Jacksonville Jagaurs"]<-"JAX"
  x[grepl("Cardinals", x)]<-"ARI"
  x[grepl("Falcons", x)]<-"ATL"
  x[grepl("Ravens", x)|x%in% c("Blt", "BLT")]<-"BAL"
  x[grepl("Bills", x)]<-"BUF"
  x[grepl("Carolina", x)]<-"CAR"
  x[grepl("Bears", x)]<-"CHI"
  x[grepl("Bengals", x)]<-"CIN"
  x[grepl("Browns", x)|x%in% c("CLV", "Clv")]<-"CLE"
  x[grepl("Cowboys", x)]<-"DAL"
  x[grepl("Broncos", x)]<-"DEN"
  x[grepl("Lions", x)]<-"DET"
  x[grepl("Packers", x)]<-"GNB"
  x[grepl("Texans", x)|x=="Hst"|x=="HST"]<-"HOU"
  x[grepl("Colts", x)]<-"IND"
  x[grepl("Jaguars", x)| x=="JAC"]<-"JAX"
  x[grepl("Dolphins", x)]<-"MIA"
  x[grepl("Vikings", x)]<-"MIN"
  x[grepl("Giants", x)| grepl("Nyg", x)| grepl("nyg", x)]<-"NYG"
  x[grepl("Jets", x)| grepl("Nyj", x)| grepl("nyj", x)]<-"NYJ"
  x[grepl("Raiders", x)]<-"OAK"
  x[grepl("Panthers", x)]<-"CAR"
  x[grepl("Eagles", x)]<-"PHI"
  x[grepl("Steelers", x)]<-"PIT"
  x[grepl("Seahawks", x)]<-"SEA"
  x[grepl("Titans", x)]<-"TEN"
  x[grepl("Redskins", x)|x=='wsh'|x=="Wsh"]<-"WAS"
  x[x%in% c("Arz", "ARZ")]<-"Ari"
  
  x[x%in% abbrev$Abbrev]<-abbrev$Abbrev[match(x[x%in% abbrev$Abbrev], abbrev$Abbrev)]
  x[x%in% abbrev$Abbrev2]<-abbrev$Abbrev[match(x[x%in% abbrev$Abbrev2], abbrev$Abbrev2)]
  x[x%in% abbrev$Abbrev3]<-abbrev$Abbrev[match(x[x%in% abbrev$Abbrev3], abbrev$Abbrev3)]
  x[x%in% abbrev$FullName]<-abbrev$Abbrev[match(x[x%in% abbrev$FullName], abbrev$FullName)]
  
  x<-sapply(x,simpleCap)
  x
}


