rm(list=ls())

library(tidyr)
library(gtools)
library(WriteXLS)
library(drc)
library(svDialogs)
library(ggplot2)
library(cowplot)
library(readxl)

location=dlg_open("~/Home/",title = "Please select your file")$res
(df=read_xlsx(location,col_names = F))
(df=as.data.frame(df))
colnames(df)=NULL

output=dlg_dir("~/Home/", caption = "Please select output directory")$res
out_of_bounds=dlg_input(message = "Do you want to allow out of bound values? Yes/No", default = "No")$res
out_of_bounds=out_of_bounds=="No"
how_many=round(nrow(df)/10,digits = 0)
experiment=dlg_input(message = "Please name your experiment", default = "experiment")$res
# are all the plates the same or different in regards to STD
same_same=dlg_input(message = "Are all the plates same? (format/standard)", default = "No")$res
if (same_same !="No"){
  STD=dlg_input(message = paste0("STD for all plates starts at (pg/ml)"), default = "2000")$res
  STD_Position=dlg_input(message = paste0("STD position for all plates is vertical/horizontal?"), default = "vertical")$res
  STD=as.numeric(STD)}

plot_list=list()
data_list=list()

for (i in 1:how_many){
  (from=as.numeric(paste0(i-1,2)))
  (to=as.numeric(paste0(i-1,9)))
  (data=df[from:to,1:13])
  (ex_name=df[as.numeric(paste0(i-1,1)),1])
  (colnames(data) = c(ex_name,1:12))
  data
  
  (dilutions=df[from:to,15:27])
  (colnames(dilutions) = c("row",1:12))
  (dilutions$row=LETTERS[1:8])
  dilutions
  
  if (same_same =="No"){
  STD=dlg_input(message = paste0("STD for plate ",i," starts at (pg/ml)"), default = "2000")$res
  STD_Position=dlg_input(message = paste0("STD position for plate ",i ," is vertical/horizontal?"), default = "vertical")$res
  STD=as.numeric(STD)
  }
  
  samples = data
  samples
  colnames(samples)[1]="row"
  samples$row=LETTERS[1:8]
  samples
  
  samples_long <- gather(samples,"col","value",2:13)
  samples_long$value=as.numeric(samples_long$value)
  samples_long
  samples_long$well <- paste0(samples_long$row,samples_long$col)
  samples_long$well
  samples_long <- samples_long[-(1:2)]
  samples_long <- samples_long[mixedorder(samples_long$well),]
  my_plate <- samples_long
  rownames(my_plate)=1:nrow(my_plate)
  
  dilution_long <- gather(dilutions, "col", "value", 2:13)
  dilution_long$value=as.numeric(dilution_long$value)
  dilution_long$well <- paste0(dilution_long$row,dilution_long$col)
  dilution_long$well
  dilution_long <- dilution_long[-(1:2)]
  dilution_long <- dilution_long[mixedorder(dilution_long$well),]
  dilution_long
  rownames(dilution_long)=1:nrow(dilution_long)
  my_plate
  
  if (STD_Position =="vertical"){
    blank <- mean(samples_long$value[95],samples_long$value[96])
  }else{
    blank <- mean(samples_long$value[80],samples_long$value[92])
  }
  
  my_plate$blanked <- my_plate$value-blank
  my_plate$dilution <- dilution_long$value
  my_plate
  
  if (STD_Position =="vertical"){
    my_standard <- data.frame(OD1=my_plate$blanked[c(11, 23, 35, 47, 59, 71, 83, 95)],OD2= my_plate$blanked [c(12, 24, 36, 48, 60, 72, 84, 96)])
    my_standard$mean_OD <- rowMeans(my_standard)
  }else{
    my_standard <- data.frame(OD1=my_plate$blanked[73:80],OD2= my_plate$blanked [85:92])
    my_standard$mean_OD <- rowMeans(my_standard)  
  }
  
  my_standard$Conc=c(STD,STD/2,STD/4,STD/8,STD/16,STD/32,STD/64, 0)
  my_standard
  
  if (sum(is.na(my_standard))>0) {
    nanas=which(is.na(my_standard$mean_OD))
    my_standard[is.na(my_standard)]=0
    sums=my_standard$OD1+my_standard$OD2
    my_standard$mean_OD[nanas]=sums[nanas]
    my_standard  
  }
  
  # if for some reason the STD is all wrong and only zeros appear this part will create a "fake" curve so that it won't break the loop
  # this really should not happen tho as the standard at the very least should work.
  # DRC cannot handle negative numbers 
  my_standard$mean_OD[my_standard$mean_OD<0]=0
  # nor can it handle all zeros - look up
  if (sum(my_standard$mean_OD)==0) {
    my_standard$mean_OD=c(1,rep(0,(length(my_standard$mean_OD)-1)))
  }
  
  my_standard
  
  fit<-drm(formula = mean_OD ~ Conc, data = my_standard, fct = LL.4())
  # Checking the quality of the STD
  somethings_wrong=FALSE
  if ((sum(my_standard$mean_OD==0)>2)|noEffect(fit)[3]>0.01) {
    somethings_wrong=TRUE
  }else{
    somethings_wrong=FALSE
  }
  # Doing the plotting
  x <- seq(0,STD, length=1000)
  y <- (fit$coefficients[2]+ (fit$coefficients[3]- fit$coefficients[2])/(1+(x/fit$coefficients[4])^ fit$coefficients[1]))
  line=data.frame(Conc=x,mean_OD=y)
  
  text=paste0("Standard Curve of ",experiment,", plate ",i," \n ",ex_name)
  p=ggplot(my_standard, aes(Conc,mean_OD))+geom_point()+
    ggtitle(text)+
    xlab("Conc [pg/mL]")+ylab("OD")+
    geom_step(data = line,aes(color="red"))+theme_classic()+theme(legend.position="none")
  
  if (somethings_wrong==TRUE) {
  p=p + annotate(geom="text", x=((max(my_standard$Conc)+min(my_standard$Conc))/2), y=((max(my_standard$mean_OD)+min(my_standard$mean_OD))/2), label="Something is wrong with your standard!!!",
               size=7, fontface="bold",color="red")
  }

  plot_list[[i]]=p
 
  my_plate$conc <- fit$coefficients[4]*(((-1*fit$coefficients[3]+my_plate$blanked)/( fit$coefficients[2]-my_plate$blanked))^(1/ fit$coefficients[1]))
  
  my_plate$conc
  
  my_plate$calculated_conc <- my_plate$conc * my_plate$dilution
  my_plate$calculated_conc=round(my_plate$calculated_conc,3)
  
  # OVER AND under the standard and undefined by the funcion
  
  if (out_of_bounds==T){
    over_values=my_plate$blanked>max(my_standard$mean_OD)
    under_values=my_plate$blanked<=fit$coefficients[2]
    my_plate$calculated_conc[under_values]="under"
    my_plate$calculated_conc[over_values]="over"
  }else{
    over_values=my_plate$blanked>fit$coefficients[3]# Upper limit of ll4 function
    under_values=my_plate$blanked<=fit$coefficients[2]# Lower limit of ll4 function  
    my_plate$calculated_conc[under_values]="under"
    my_plate$calculated_conc[over_values]="over"
  }
  my_plate$calculated_conc
  
  A1_12 <- my_plate$calculated_conc[1:12]
  B1_12 <- my_plate$calculated_conc[13:24]
  C1_12 <- my_plate$calculated_conc[25:36]
  D1_12 <- my_plate$calculated_conc[37:48]
  E1_12 <- my_plate$calculated_conc[49:60]
  F1_12 <- my_plate$calculated_conc[61:72]
  G1_12 <- my_plate$calculated_conc[73:84]
  H1_12 <- my_plate$calculated_conc[85:96]
  
  data_out <- cbind(A1_12,B1_12,C1_12,D1_12,E1_12,F1_12,G1_12,H1_12)
  data_out <- t(data_out)
  (data_out <- as.data.frame(data_out))
  
  (data_out=cbind(data[1],data_out))
  colnames(data_out) <- colnames(data)
  data_out
  first_row=df[(from-1),1:13]
  colnames(first_row)=colnames(data)
  data_out
  data_out=rbind(first_row,data_out)
  colnames(data_out)=paste0("V",seq(1,ncol(data_out)))
  data_out
  (data_out=rbind(data_out,""))
  
  data_list[[paste0(experiment,", plate ",i)]]=data_out
  # WriteXLS(data_out,paste0(output,"/",experiment,", plate ",i," out",".xls"),row.names = T)
}

do.call(plot_grid,plot_list)+ggsave(paste0(output,"/",experiment,"_curve",".pdf"),scale = 3)
(data_out_final=do.call(rbind,data_list))
WriteXLS(data_out_final,paste0(output,"/",experiment," Elisa evaluation",".xls"),row.names = F,col.names = F)
