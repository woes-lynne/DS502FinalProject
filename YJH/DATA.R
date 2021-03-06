install.packages("pander")
install.packages("knitr")
install.packages("skimr")
install.packages("kableExtra")
library(pander)
library(knitr)
library(skimr)
library(kableExtra)
library(tinytex)
library(dplyr)
library(purrr)
library(pls)
library(randomForest)
library(gam)
library(glmnet)
library(ggplot2)
library(corrplot)

### Read in Data
setwd("C:\\users\\huawe\\Desktop\\DS502FinalProject")
vault = read.csv("./SourceData/test.csv")
HousePricing = read.csv("./SourceData/train.csv")

### Feature Engineering

# remove the irrational data point
ggplot(HousePricing,aes(x=GrLivArea,y=SalePrice))+geom_point()
HousePricing = HousePricing[HousePricing$GrLivArea<4500,]

# find which variables contain NA
NAcol <- which(colSums(is.na(HousePricing)) > 0)
sort(colSums(sapply(HousePricing[NAcol], is.na)), decreasing = TRUE)

# remove NA 
HousePricing$PoolQC[is.na(HousePricing$PoolQC)] = 'None'

quailty = c('None'=0,'Fa' = 1,'TA' = 2,'Gd' = 3,'Ex' = 4)
HousePricing$PoolQC<-recode(HousePricing$PoolQC,'None'=0,'Fa' = 1,'TA' = 2,'Gd' = 3,'Ex' = 4)

HousePricing$MiscFeature[is.na(HousePricing$MiscFeature)] = 'None'
HousePricing$MiscFeature = as.factor(HousePricing$MiscFeature)

HousePricing$Alley[is.na(HousePricing$Alley)] = 'None'
HousePricing$Alley=recode(HousePricing$Alley,'None' = 0,'Pave' = 1,'Grvl' = 2)

HousePricing$Fence[is.na(HousePricing$Fence)] = 'None'
HousePricing$Fence=recode(HousePricing$Fence,'None' = 0,'MnWw' = 1,'GdWo' = 2,'MnPrv' = 3,'GdPrv' = 4)

HousePricing$FireplaceQu[is.na(HousePricing$FireplaceQu)] = 'None'
HousePricing$FireplaceQu=recode(HousePricing$FireplaceQu,'None' = 0,'Po' = 1,'Fa' = 2,'TA' = 3,'Gd' = 4,'Ex' = 5)


HousePricing$LotFrontage[is.na(HousePricing$LotFrontage)]
for (i in 1:nrow(HousePricing)){
  if (is.na(HousePricing$LotFrontage[i])){
    HousePricing$LotFrontage[i] = as.integer(median(HousePricing$LotFrontage[HousePricing$Neighborhood==HousePricing$Neighborhood[i]],na.rm = TRUE))
  }
}


HousePricing$GarageType[is.na(HousePricing$GarageType)] = 'None'
HousePricing$GarageYrBlt[is.na(HousePricing$GarageYrBlt)] <- HousePricing$YearBuilt[is.na(HousePricing$GarageYrBlt)]
HousePricing$GarageFinish[is.na(HousePricing$GarageFinish)] = 'None'
HousePricing$GarageQual[is.na(HousePricing$GarageQual)] = 'None'
HousePricing$GarageCond[is.na(HousePricing$GarageCond)] = 'None'

length(which(is.na(HousePricing$BsmtQual) & is.na(HousePricing$BsmtCond) & is.na(HousePricing$BsmtExposure) & is.na(HousePricing$BsmtFinType1) & is.na(HousePricing$BsmtFinType2)))
HousePricing[!is.na(HousePricing$BsmtFinType1) & (is.na(HousePricing$BsmtCond)|is.na(HousePricing$BsmtQual)|is.na(HousePricing$BsmtExposure)|is.na(HousePricing$BsmtFinType2)), c('BsmtQual', 'BsmtCond', 'BsmtExposure', 'BsmtFinType1', 'BsmtFinType2')]

HousePricing$BsmtFinType2[333] = names(sort(table(HousePricing$BsmtFinType2),decreasing = TRUE))[1]
HousePricing$BsmtExposure[949] = names(sort(table(HousePricing$BsmtExposure),decreasing = TRUE))[1]

HousePricing$BsmtQual[is.na(HousePricing$BsmtQual)] = 'None'
HousePricing$BsmtQual=recode(HousePricing$BsmtQual,'None' = 0,'Po' = 1,'Fa' = 2,'TA' = 3,'Gd' = 4,'Ex' = 5)

HousePricing$BsmtCond[is.na(HousePricing$BsmtCond)] = 'None'
HousePricing$BsmtCond=recode(HousePricing$BsmtCond,'None' = 0,'Po' = 1,'Fa' = 2,'TA' = 3,'Gd' = 4,'Ex' = 5)

HousePricing$BsmtExposure[is.na(HousePricing$BsmtExposure)]='None'
HousePricing$BsmtExposure=recode(HousePricing$BsmtExposure,'None' = 0,'No' = 1,'Mn' = 2,'Av' = 3,'Gd' = 4)

HousePricing$BsmtFinType1[is.na(HousePricing$BsmtFinType1)] = 'None'
HousePricing$BsmtFinType1=recode(HousePricing$BsmtFinType1,'None' = 0,'Unf' = 1,'LwQ' = 2,'Rec' = 3,'BLQ' = 4,'ALQ' = 5,'GLQ' = 6)

HousePricing$BsmtFinType2[is.na(HousePricing$BsmtFinType2)] = 'None'
HousePricing$BsmtFinType2=recode(HousePricing$BsmtFinType2,'None' = 0,'Unf' = 1,'LwQ' = 2,'Rec' = 3,'BLQ' = 4,'ALQ' = 5,'GLQ' = 6)


HousePricing$MasVnrType[is.na(HousePricing$MasVnrType)] = 'None'
median(HousePricing$SalePrice[HousePricing$MasVnrType=='BrkCmn'])
median(HousePricing$SalePrice[HousePricing$MasVnrType=='BrkFace'])
median(HousePricing$SalePrice[HousePricing$MasVnrType=='None'])
median(HousePricing$SalePrice[HousePricing$MasVnrType=='Stone'])
HousePricing$MasVnrType=recode(HousePricing$MasVnrType,'BrkCmn' = 0,'None' = 0,'BrkFace' = 1,'Stone' = 2)

HousePricing$MasVnrArea[(is.na(HousePricing$MasVnrArea))] = 0
HousePricing$Electrical[is.na(HousePricing$Electrical)] <- names(sort(-table(HousePricing$Electrical)))[1]
HousePricing$Electrical=as.factor(HousePricing$Electrical)

HousePricing$MSZoning = as.factor(HousePricing$MSZoning)
HousePricing$Street=recode(HousePricing$Street,'Pave' = 0,'Grvl' = 1)
HousePricing$LotShape=recode(HousePricing$LotShape,'IR3' = 0,'IR2' = 1,'IR1' = 2,'Reg' =2)
HousePricing$Utilities=recode(HousePricing$Utilities,'ELO' = 0,'NoSeWa' = 1,'NoSewr' = 2,'AllPub' =2)
HousePricing$LotConfig = as.factor(HousePricing$LotConfig)
HousePricing$Condition1 = as.factor(HousePricing$Condition1)
HousePricing$Condition2 = as.factor(HousePricing$Condition2)
HousePricing$LandContour = as.factor(HousePricing$LandContour)
HousePricing$RoofStyle = as.factor(HousePricing$RoofStyle)
HousePricing$LandSlope=recode(HousePricing$LandSlope,'Sev' = 0,'Mod' = 1,'Gtl' = 2)
HousePricing$BldgType = as.factor(HousePricing$BldgType)
HousePricing$HouseStyle=as.factor(HousePricing$HouseStyle)
HousePricing$RoofMatl=as.factor(HousePricing$RoofMatl)
HousePricing$Exterior1st=as.factor(HousePricing$Exterior1st)
HousePricing$Exterior2nd=as.factor(HousePricing$Exterior2nd)
HousePricing$ExterQual=recode(HousePricing$ExterQual,'Po' = 0,'Fa' = 1,'TA' = 2,'Gd' = 3,'Ex' = 4)
HousePricing$ExterCond=recode(HousePricing$ExterCond,'Po' = 0,'Fa' = 1,'TA' = 2,'Gd' = 3,'Ex' = 4)
HousePricing$Foundation = as.factor(HousePricing$Foundation)
HousePricing$Heating = as.factor(HousePricing$Heating)
HousePricing$HeatingQC=recode(HousePricing$HeatingQC,'Po' = 0,'Fa' = 1,'TA' = 2,'Gd' = 3,'Ex' = 4)
HousePricing$CentralAir=recode(HousePricing$CentralAir,'N' = 0,'Y' = 1)
HousePricing$KitchenQual=recode(HousePricing$KitchenQua,'Po' = 0,'Fa' = 1,'TA' = 2,'Gd' = 3,'Ex' = 4)
HousePricing$Functional=recode(HousePricing$Functional,'Sal' = 0,'Sev' = 1,'Maj2' = 2,'Maj1' = 3,'Mod' = 4,'Min2' = 5,'Min1' = 6,'Typ' = 7)
HousePricing$GarageType=as.factor(HousePricing$GarageType)

HousePricing$GarageFinish=recode(HousePricing$GarageFinish,'None' = 0,'Unf' = 1,'RFn' = 2,'Fin' = 3)
HousePricing$GarageCond=recode(HousePricing$GarageCond,'None' = 0,'Po' = 1,'Fa' = 2,'TA' = 3,'Gd' = 4,'Ex' = 5)
HousePricing$PavedDrive=recode(HousePricing$PavedDrive,'N' = 0,'P' = 1,'Y' = 2)
HousePricing$SaleType = as.factor(HousePricing$SaleType)
HousePricing$SaleCondition = as.factor(HousePricing$SaleCondition)
HousePricing$MoSold = as.factor(HousePricing$MoSold)
HousePricing$MSSubClass = as.factor(HousePricing$MSSubClass)

numvar = which(sapply(HousePricing, is.numeric))
catvar = which(sapply(HousePricing, is.factor))
numdata = HousePricing[,numvar]
numcor =(cor(numdata))
corsorted = as.matrix(sort(numcor[,"SalePrice"],decreasing = TRUE))
CorHigh <- names(which(apply(corsorted, 1, function(x) abs(x)>0.5)))
numcor <- numcor[CorHigh, CorHigh]
corrplot.mixed(numcor, tl.col="black", tl.pos = "lt", tl.cex = 0.7,cl.cex = .7, number.cex=.7)

# standardize numerical data 
numeric = select_if(HousePricing,is.numeric)
stnumer = scale(numeric,center = T,scale = T)
factor = select_if(HousePricing,is.factor)
#dim(factor)
#factor
# one hot
factor = model.matrix(~.-1,factor) %>% as.data.frame()

# put standardized numerical data and categorical data in one data
# 这个是合并之后的新的数据 名字你改一改
newdata = cbind(stnumer,factor)

# bootstrap
set.seed(1234)
sample = sample(dim(newdata)[1],dim(newdata)[1],replace = T);sample
# 随机放回抽取的新数据
btnewdata = newdata[sample,]
