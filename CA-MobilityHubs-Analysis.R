#################################
####### CDS 301 - lab 5/6 #######
########Hyeonjeong Park#########
################################

library(ggplot2)
library(sf)
library(dplyr)
library(tidyverse)
library(RColorBrewer)
library(plotly)
library(leaflet)
library(readxl)
library(htmlwidgets)
library(cartogram)


# Data processing --------------------------------------------------------------

# Data source: https://catalog.data.gov/dataset/park-and-ride-364a9
# About Park and ride data: provide a location 'administered' by California Department of Transportation for individuals to park their vehicles to join carpools and to access bus and rail services. 
# The initial data contains 20 columns(variables) with 335objects. Moreover, it has 11 different owner types including unknown(NA).

df <- read_csv('Park_and_Ride.csv')
str(df)
summary(df)
df <- df[,-c(1:3,5,11,12)]
colnames(df) <- c("District","Lot_ID","Route","County","Mobility_hub","Address","Owner","Lat","Long","City","Zipcode","N_of_bikelockers","N_of_spaces","EV_chargers")

unique(df$Owner)


df2 <- df %>% select("District","Lot_ID","County","Mobility_hub","Address","Owner","Lat","Long","City","Zipcode","N_of_bikelockers","N_of_spaces","EV_chargers") %>% 
  filter(Lat > 0 | Long > 0) %>%
  filter(Owner %in% c('State','State/City','State/County'))
unique(df2$Owner)

# Visualization via Leaflet ----------------------------------------------------
# popup
mytext <- paste(
  "Owner: ", df2$Owner, "<br/>",
  "District: ", df2$District, "<br/>", 
  "Lot ID: ", df2$Lot_ID, "<br/>", 
  "County: ", df2$County,"<br/>",
  "Mobility hub name: ", df2$Mobility_hub, "<br/>",
  "Bicycle lockers: ", df2$N_of_bikelockers,"<br/>",
  "EV chargers: ",df2$EV_chargers,"<br/>",
  "Address: ", df2$Address, sep=""
  ) %>%
  lapply(htmltools::HTML)

# color
col <- colorFactor(c("#b2182b","#f6e84d", "#457557"), domain=c('State','State/City','State/County'), ordered = TRUE, alpha = 0.7)

m <- leaflet(df2)  %>% 
  addProviderTiles(providers$CartoDB.Positron) %>%      # providers function
  setView(mean(df2$Long), mean(df2$Lat), zoom = 7) %>%
  addCircleMarkers(~Long, ~Lat, popup=mytext, weight = 3, radius=3, 
                   color=~col(Owner), stroke = 'black', fillOpacity = 0.7)  %>%
  addLegend("bottomright", colors= c("#b2182b","#f6e84d", "#457557"), labels=c('State','State/City','State/County'))%>%
  addControl(                              #adding the title
    html = "<h2>Mobility Hubs in CA</h2>",
    position = "bottomleft"
  )%>%
 addMiniMap(width = 130, height = 130)     #adding a minimap

m

saveWidget(m, file="m.html")


# merging with a polygon data to visualize count value -------------------------


# polygon data
counties <- read_sf("CA_Counties.shp")
st_crs(counties)
plot(counties['NAME'])
 


# aggregate the point data into county unit
df_t <- df2 %>% filter(Owner %in% c('State','State/City','State/County'))
df_t <- df_t %>%
  group_by(County) %>% summarize(n = n())


# merge sf data with the count information
County <- merge(counties, df_t, by.x = 'NAME', by.y = 'County', all=T)
County$n[is.na(County$n)] <- 1

County.sf <- st_transform(County, crs=23038) # or 23038
# visualization ----------------------------------------------------------------

# Create the cartogram

county_carto <- cartogram_cont(County.sf, "n", itermax = 5)


plot(county_carto['n'])



ggplot() +
  geom_sf(county_carto, mapping = aes(fill = n)) +
  scale_fill_gradient(low = "#E6E6FA", high = "#4B0082")+ #color scheme
  ggtitle("The number of Mobility Hubs in CA")+ #title
  geom_sf_text(county_carto, mapping = aes(label = NAME), color = "white", size = 2) + 
  theme_void() #theme of cartogram

# Interpretation
# The interactive map with leaftlet shows geographical accuracy in which the mobility hubs are located
# in the California counties. It was easy to distinguish it by owners as I assigned the colors differently.
# Spatial relationships between the mobility hubs were easily seen as shown in dots. Interaction such as zooming 
# in and out was possible clicking on map features which enhanced the exploratory nature of data analysis. ALso, the interactive map
# displayed information for each mobility hubs when clicking each location.
# The cartogram showed distortion where the mobility hubs were located the most. The number of mobility hubs(facilities) were 
# distinguished by the most densed region in dark purple and the less densed regions in light purple. By emphasizing the area(distortions) interested
# and de-emphasizing some area(less hubs located), it was easier to spot patterns. It was easier to focus on the California counties where mobility hubs were located the most and less by distortions and colors.
# The cartogram simply shows the locations of the mobility hubs without further information. THe maps can be used differently depending on the purpose of the usage.