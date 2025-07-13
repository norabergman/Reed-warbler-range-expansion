### RINGING DATA ANALYSIS WORKFLOW ###
# Author: Petteri Lehikoinen (translated by Nora Bergman)

## Packages and data preparation

# Reading in the data file (re-encounter data of reed warblers ringed in Finland in years 1969-2023)
asci <- read.csv2("Acrsci_results_20240926.txt", header = TRUE, dec = ".", sep = "|")

# Checking the data
str(asci)
# Formatting dates
asci$EVENTDATE <- as.Date(as.character(asci$EVENTDATE), format = "%Y-%m-%d")
asci$EVENTDATE.RINGING <- as.Date(as.character(asci$EVENTDATE.RINGING), format = "%m/%d/%Y")

# Mean longitude of ringings
mean(asci$WGS84DECIMALLON.RINGING)
# Splitting the ringings into "eastern" and "western" based on the mean longitude
easci =  asci[which(asci$WGS84DECIMALLON.RINGING > mean(asci$WGS84DECIMALLON.RINGING)),]
wasci =  asci[which(asci$WGS84DECIMALLON.RINGING < mean(asci$WGS84DECIMALLON.RINGING)),]
# Checking
str(easci)

# Loading packages
library(ggmap)
library(gplots)
library(rgeos)
library(devtools)
library(ggplot2)
library(sf)
library(rnaturalearth)
library(rnaturalearthdata)
col2hex("grey60")
col2hex("tan2")

# Calculating new directions for drawing the mean re-encounter direction, as ggplot uses a specific format for it
easci$newdir <- ((-easci$DIRECTIONTORINGINGINDEGREES+90)/360)*2*pi
wasci$newdir <- ((-wasci$DIRECTIONTORINGINGINDEGREES+90)/360)*2*pi

# Calculating the direction for all eastern and western data points based on re-encounters south of 49°N
easci49 <- easci[which(easci$WGS84DEGREELAT<490000),]
str(easci49)
wasci49 <- wasci[which(wasci$WGS84DEGREELAT<490000),]
str(easci49)

# Transforming into degrees
mean(easci49$DIRECTIONTORINGINGINDEGREES) #226.8788
mean(wasci49$DIRECTIONTORINGINGINDEGREES) #225.6154

# Checking that the mean is the same both ways
mean(easci49$newdir)
((-(mean(easci49$DIRECTIONTORINGINGINDEGREES))+90)/360)*2*pi

# Defining map values
world <- ne_countries(scale = "large", returnclass = "sf")
class(world)


## Drawing the map (all re-encounters)

# Drawing the map containing all ringing and re-encounter locations (spring & autumn), ringing centroids, and mean re-encounter directions of both the eastern and western group

# Base map
a <- ggplot(data = world)
# Axis labels 
a <- a + xlab("Longitude") + ylab("Latitude")
# Title
#a <- a + ggtitle("All recoveries")
# Cropping the map
a <- a + 
  geom_sf() +
  coord_sf(xlim = c(min(asci$WGS84DECIMALLON),max(asci$WGS84DECIMALLON.RINGING)), ylim = c(28,65), expand = TRUE)

# Adding the western re-encounter points 
a <- a + geom_point(data = wasci, 
                    aes(y = WGS84DECIMALLAT, x = WGS84DECIMALLON,
                        shape = "Western recovery",
                        colour="Western recovery"),
                    size = 3, stroke = 2, alpha=0.5)
# Adding the eastern re-encounter points
a <- a + geom_point(data = easci, 
                    aes(y = WGS84DECIMALLAT, x = WGS84DECIMALLON,
                        shape = "Eastern recovery",
                        colour="Eastern recovery"),
                    size = 3, alpha=0.6)
# Adding the eastern ringing points
a <- a + geom_point(data = easci, 
                    aes(y = WGS84DECIMALLAT.RINGING, x = WGS84DECIMALLON.RINGING,
                        shape = "Eastern ringing",
                        colour="Eastern ringing"),
                    size = 1.5, alpha=0.6)
# Adding the western ringing points
a <- a + geom_point(data = wasci, 
                    aes(y = WGS84DECIMALLAT.RINGING, x = WGS84DECIMALLON.RINGING,
                        shape = "Western ringing",
                        colour="Western ringing"),
                    size = 1.5, alpha=0.5)

# Adding the centroid of the eastern ringings
a <- a + geom_point(data = easci, 
                    aes(y = mean(WGS84DECIMALLAT.RINGING), x = mean(WGS84DECIMALLON.RINGING),
                        shape = "Eastern centroid",
                        colour= "Eastern centroid"),
                    size = 5, stroke = 1.5)
# Adding the centroid of the western ringings
a <- a + geom_point(data = wasci, 
                    aes(y = mean(WGS84DECIMALLAT.RINGING), x = mean(WGS84DECIMALLON.RINGING),
                        shape = "Western centroid",
                        colour= "Western centroid"),
                    size = 5, stroke = 1.5)
# Adding a line for the mean direction of the eastern group
a <- a + geom_spoke(data = easci49, 
                    aes(angle = mean(newdir),
                    y = mean(WGS84DECIMALLAT.RINGING), x = mean(WGS84DECIMALLON.RINGING)),
                    radius = 40.8, size=1.2, colour = "cadetblue4")
# Adding a line for the mean direction of the western group
a <- a + geom_spoke(data = wasci49, 
                    aes(angle = mean(newdir),
                        y = mean(WGS84DECIMALLAT.RINGING), x = mean(WGS84DECIMALLON.RINGING)),
                    radius = 40, size = 1.2, colour = "tan2")
# Point styles and legend
a <- a + scale_shape_manual(name="Eastern",
                                    values=c("Eastern recovery"=16, "Western recovery"=1, "Eastern centroid" = 6, "Western centroid" = 6, 
                                             "Western ringing" = 16, "Eastern ringing" = 17))
# Point colours
a <- a + scale_colour_manual(name="Eastern",
                             values=c("Eastern recovery"="cadetblue4", "Western recovery"="tan2", "Eastern centroid" = "cadetblue4", 
                                      "Western centroid" = "tan2", "Western ringing" = "tan2", "Eastern ringing" = "cadetblue4"))
a <- a + theme_bw()
a <- a + theme(panel.background = element_rect(fill = "white"))
a <- a + theme(legend.text=element_text(size=12))
a <- a + theme(legend.justification = "top")

# Plotting
a


## Map of the spring re-encounters

library(tidyverse)

# Extracting the month from dates to separate spring and autumn re-encounters
asci$month <- month(asci$EVENTDATE)
head(asci)
unique(asci$month)

# Limiting the spring data to January-June
spring_asci = asci[which(asci$month < 7),]
spring_asci = spring_asci[which(spring_asci$month >= 1),]

# Checking
str(spring_asci)
min(spring_asci$month)
max(spring_asci$month)

# Separating the ringings and selecting only the columns we need
springing <- spring_asci %>% select(ID, WGS84DECIMALLAT.RINGING, WGS84DECIMALLON.RINGING, month, DIRECTIONTORINGINGINDEGREES)
# New field with values "ringing"
springing$type <- "RINGING"

# Renaming some columns to work with the re-encounters
colnames(springing)[colnames(springing) %in% c("WGS84DECIMALLAT.RINGING", "WGS84DECIMALLON.RINGING")] <- c("WGS84DECIMALLAT", "WGS84DECIMALLON")
str(springing)

# Doing the same for re-encounters
sprecovery  <- spring_asci %>% select(ID, WGS84DECIMALLAT, WGS84DECIMALLON, month, DIRECTIONTORINGINGINDEGREES)
sprecovery$type <- "recovery"
str(sprecovery)

# Merging the re-encounters and ringings again
spr = rbind(springing, sprecovery)
str(spr)

# Shortening the column name
colnames(spr)[colnames(spr) %in% c("DIRECTIONTORINGINGINDEGREES")] <- c("Direction")

# Checking
str(spr)
head(world)

world_coordinates <- map_data("world") 

# Drawing the map
{
c <- ggplot(data = world) 
c <- c + xlab("Longitude") + ylab("Latitude")
c <- c + ggtitle("Spring recoveries (n=47)")
c <- c + 
  geom_sf(fill="white") +
  coord_sf(xlim = c(-18,31), ylim = c(28,65), expand = FALSE)

# Connecting ringings and re-encounters with lines
c <- c +  geom_line(data = spr, aes(x = WGS84DECIMALLON, y = WGS84DECIMALLAT, 
                                    group = ID), colour = ("grey10"), linewidth = 0.2, alpha=0.5)

# Adding the ringing points
#c <- c + geom_point(data = ringing, 
#                    aes(x = WGS84DECIMALLON, y = WGS84DECIMALLAT), shape = 1, 
#                    colour = "grey40", size = 1, stroke = 1.2)

# Adding the re-encounter points
c <- c + geom_point(data = sprecovery, 
                    aes(x = WGS84DECIMALLON, y = WGS84DECIMALLAT), 
                        shape = 1, stroke = 1.5, colour = "grey60", size = 2, alpha=0.9)

# B&W background
c <- c +  theme_bw()
# White background
c <- c +  theme(panel.background = element_rect(fill = "grey98"))
# Plotting
c
}


## Map of the autumn re-encounters

# Limiting the spring data to July-December
autmn_asci = asci[which(asci$month > 6),]

# Checking
str(autmn_asci)
min(autmn_asci$month)
max(autmn_asci$month)

# Separating the ringings and selecting only the columns we need
ringing <- autmn_asci %>% select(ID, WGS84DECIMALLAT.RINGING, WGS84DECIMALLON.RINGING, month, DIRECTIONTORINGINGINDEGREES)
# New field with values "ringing"
ringing$type <- "RINGING"
# Renaming some columns to work with the re-encounters
colnames(ringing)[colnames(ringing) %in% c("WGS84DECIMALLAT.RINGING", "WGS84DECIMALLON.RINGING")] <- c("WGS84DECIMALLAT", "WGS84DECIMALLON")
str(ringing)

# Doing the same for re-encounters
recovery  <- autmn_asci %>% select(ID, WGS84DECIMALLAT, WGS84DECIMALLON, month, DIRECTIONTORINGINGINDEGREES)
recovery$type <- "recovery"
str(recovery)

# Merging the re-encounters and ringings again
aut = rbind(ringing, recovery)
str(aut)

# Shortening the column name
colnames(aut)[colnames(aut) %in% c("DIRECTIONTORINGINGINDEGREES")] <- c("Direction")

# Checking
str(aut)

# Drawing the map
{
d <- ggplot(data = world) 
d <- d + xlab("Longitude") + ylab("Latitude")
d <- d + ggtitle("Autumn recoveries (n=279)")
d <- d + 
  geom_sf(fill="white") +
  coord_sf(xlim = c(-18,31), ylim = c(28,65), expand = FALSE)

# Connecting ringings and re-encounters with lines
d <- d +  geom_line(data = aut, aes(x = WGS84DECIMALLON, y = WGS84DECIMALLAT, 
                                    group = ID), colour = ("grey25"), linewidth = 0.2, alpha=0.5)

# Adding the ringing points
#d <- d + geom_point(data = ringing, 
#                    aes(x = WGS84DECIMALLON, y = WGS84DECIMALLAT), shape = 1, 
#                    colour = "grey40", size = 1, stroke = 1.2)

# Adding the re-encounter points
d <- d + geom_point(data = recovery, 
                    aes(x = WGS84DECIMALLON, y = WGS84DECIMALLAT), 
                    shape = 1, stroke = 1.5, colour = "grey70", size = 2, alpha=0.9)

# B&W background
d <- d +  theme_bw()
# White background
d <- d +  theme(panel.background = element_rect(fill = "grey98"))
# Plotting
d
}


## Linear models

library(DHARMa)

##### lm tests ####

# Combine data from south of latitude 49 degrees 
asci49 <- rbind(wasci49, easci49)

# Test whether ringing longitude affects recovery longitude (for recoveries south of latiude 49)
lm1 <- lm(WGS84DECIMALLON ~ WGS84DECIMALLON.RINGING, data = asci49)
simulateResiduals(lm1, plot = T) # OK
summary(lm1)  #marginal effect i.e. birds ringed further east tend to be found 
              #at more eastern locations (p = 0.0594)

# Test whether ringing longitude affects recovery direction from ringing (for recoveries south of latiude 49)
lm2 <- lm(DIRECTIONTORINGINGINDEGREES ~ WGS84DECIMALLON.RINGING, data = asci49)
simulateResiduals(lm2, plot = T) # OK
summary(lm2) # NS
