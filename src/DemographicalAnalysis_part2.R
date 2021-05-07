library(rstudioapi)
current_path <- getSourceEditorContext()$path
setwd(dirname(current_path))
library(gender)
library(ggplot2)
library(scales)

# Gender
data = read.csv("Disney_name.csv", stringsAsFactors = FALSE)
gender = c()
for(i in 1:nrow(data)){
  res = gender(data$first_name[i], years = c(1970,2010), method = "ssa")
  if(nrow(res)>0){
    gender[i] = res$gender
  }else{
    gender[i] = NA
  }
}
data$gender = gender
#write.csv(data,file="Disney_gender.csv")

data = data[!duplicated(data[ , c("user_id")]),]
table(data$gender)/nrow(data)*100
df <- data.frame(
  group = c("male", "female", "NA"),
  value = c(44,43,13)
)
ggplot(df, aes(x="", y=value, fill=group))+
  geom_bar(width = 1, stat = "identity")+
  coord_polar("y", start=0)+
  theme(axis.text.x=element_blank())+
  geom_text(aes(label = paste(round(value / sum(value) * 100, 1), "%")),
            position = position_stack(vjust = 0.5)) 


# Race
data2 = read.csv("Disney_race.csv", stringsAsFactors = FALSE)
data2 = data2[!duplicated(data2[ , c("user_id")]),]
table(data2$race)/nrow(data2)*100
df2 <- data.frame(
  group = c("Asian/Pacific Islander", "Black", "Hispanic","White"),
  value = c(8,1,10,81)
)
ggplot(df2, aes(x="", y=value, fill=group))+
  geom_bar(width = 1, stat = "identity")+
  coord_polar("y", start=0)+
  theme(axis.text.x=element_blank())+
  geom_text(aes(label = paste(round(value / sum(value) * 100, 1), "%")),
            position = position_stack(vjust = 0.5))


# Location
data3 = read.csv("Disney_location.csv", stringsAsFactors = FALSE)
data3 = data3[!duplicated(data3[ , c("user_id")]),]
#write.csv(data3, file="Disney_location_nodupid.csv")
data3$state = toupper(data3$state)
location = data.frame(table(data3$state))
ggplot(location, aes(x=reorder(Var1, -Freq), y=Freq)) +
  geom_bar(stat="identity") +
  xlab("State") + 
  ylab("Number of Users")

location2 = location[location$Var1!="FL",]
ggplot(location2, aes(x=reorder(Var1, -Freq), y=Freq)) +
  geom_bar(stat="identity") +
  xlab("State") + 
  ylab("Number of Users")
