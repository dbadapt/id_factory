data <- read.csv('inserts_by_hrmin.csv',header=T)
pdf(file='inserts_by_hrmin.pdf', onefile=T, paper='A4r', width=11, height=8.5)
plot(data$hrmin,data$inserts,ylab="")
title('Inserts by hour:minute')

