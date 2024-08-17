library(shiny)
library(shinydashboard)
library(DBI)
library(dplyr)
library(tidyr)

source("classification-results.R")

ui <- dashboardPage(
  skin = "black",
  dashboardHeader(title = "Fallacy Classification"),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Classification Results", tabName = "classification-results")
    )
  ),
  dashboardBody(
    tags$head(
      tags$style(HTML(".content-wrapper { background-color: #FFFFFF }"))
    ),
    tabItems(
      tabItem(tabName = "classification-results", classificationResultsUI("classificationResults"))
    )
  ),
)

server <- function(input, output, session) {
  classificationResultsServer("classificationResults")
  
}

shinyApp(ui, server)
