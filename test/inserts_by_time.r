data <- read.csv('inserts_by_time.csv',header=T)
pdf(file='inserts_by_time.pdf', onefile=T, paper='A4r', width=11, height=8.5)
plot(data$timeinc,data$inserts,ylab="")
title('Inserts per time increment')

