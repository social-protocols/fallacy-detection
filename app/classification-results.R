library(shiny)
library(DBI)
library(dplyr)

db <- function() {
  con <- dbConnect(
    RSQLite::SQLite(),
    file.path("..", Sys.getenv("DATABASE_PATH"))
  )
  return(con)
}

classificationResultsUI <- function(id) {
  fluidPage(
    DT::DTOutput(NS(id, "classification_results")),
  )
}

classificationResultsServer <- function(id) {
  moduleServer(id, function(input, output, session) {
    output$test <- renderText("Halo weld, i bims, 1 test lol!")

    output$classification_results <- DT::renderDT({
      con <- db()
      data <- tbl(con, "test_cases") %>%
        data.frame() %>% 
        inner_join(
          tbl(con, "gpt_detected_fallacies") %>%
            data.frame() %>%
            rename(id = test_case_id),
          by = "id"
        ) %>%
        left_join(
          tbl(con, "human_annotated_fallacies") %>%
            data.frame() %>%
            rename(id = test_case_id) %>%
            mutate(annotated_label = label),
          by = c("id", "label")
        ) %>%
        mutate(correctly_predicted = !is.na(annotated_label)) %>%
        select(-annotated_label)
      DBI::dbDisconnect(con)
      data
    })
  })
}
