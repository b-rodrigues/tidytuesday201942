# Module UI

#' @title   mod_dataviz_ui and mod_dataviz_server
#' @description  A shiny Module.
#'
#' @param id shiny id
#' @param input internal
#' @param output internal
#' @param session internal
#'
#' @rdname mod_dataviz
#'
#' @keywords internal
#' @export 
#' @import shiny
#' @importFrom htmltools tags
mod_dataviz_ui <- function(id, type = c("point", "hist", "boxplot", "barplot")){
  ns <- NS(id)
  tagList(
    col_12(
      h3(
        sprintf(
          "Create a geom_%s", type
        )
      ) 
    ), 
    col_3(
      if (type == "boxplot" | type =="barplot") {
        selectInput(
          ns("x"),
          "x", 
          choices = names_that_are(c("logical", "character"))
        )
      } else {
        selectInput(
          ns("x"),
          "x", 
          choices = names_that_are("numeric")
        )
      }
      ,
      if (type == "point" | type == "boxplot"){
        selectInput(
          ns("y"),
          "y", 
          choices = names_that_are("numeric")
        )
      } else if (type == "hist") {
        numericInput(
          ns("bins"), 
          "bins", 
          30, 
          1, 
          150,
          1
        )
      }, 
      if (type != "boxplot" & type != "barplot"){
        selectInput(
          ns("color"),
          "color", 
          choices = names_that_are(c("logical", "character"))
        )
      } else if (type == "barplot"){
        selectInput(
          ns("fill"),
          "fill", 
          choices = names_that_are(c("logical", "character"))
        )
      }, 
      if (type == "barplot"){
        checkboxInput(
          ns("coord_flip"),
          "coord_flip"
        )
      },
      selectInput(
        ns("theme"),
        "theme", 
        choices = themess()
      ), 
      selectInput(
        ns("palette"),
        "palette", 
        choices = colourvalues::colour_palettes()
      ), 
      textInput(
        ns("title"),
        "Title",
        value = ""
      ), 
      actionButton(
        ns("go"), 
        "Render plot"
      ) %>%
        tags$div(align = "right")
    ),
    column(
      9, 
      plotOutput(ns("plot")) %>%
        tagAppendAttributes(
          onclick = sprintf(
            "Shiny.setInputValue('%s', true, {priority : 'event'})", 
            ns("show")
          )
        ), 
      HTML("&nbsp;"),
      col_6(
        tags$p(
          "Click on the graph to see the code"
        )
      ), 
      col_6(
        downloadButton(ns("dl")) %>%
          tags$div(align = "right") 
      )
    )
  )
}

# Module Server

#' @rdname mod_dataviz
#' @export
#' @import ggplot2
#' @import shiny
#' @importFrom colourvalues color_values
#' @importFrom rlang sym
#' @importFrom dplyr pull
#' @importFrom styler style_text
#' @keywords internal

mod_dataviz_server <- function(input, output, session, type){
  ns <- session$ns
  
  r <- rv(
    plot = ggplot(big_epa_cars), 
    code = "ggplot(big_epa_cars)"
  )
  
  observeEvent( input$go , {
    
    x <- rlang::sym(input$x)
    
    if (type == "point"){
      y <- sym(input$y)
      color <- sym(input$color)
      r$plot <- ggplot(big_epa_cars, aes(!!x, !!y, color = !!color))  +
        geom_point()+ 
        scale_color_manual(
          values = color_values(
            1:length(unique(pull(big_epa_cars, !!color))), 
            palette = input$palette
          )
        )
      r$code <- sprintf(
        "ggplot(big_epa_cars, aes(%s, %s, color = %s)) + 
        geom_point() +
        scale_color_manual(
        values = color_values(
        1:length(unique(dplyr::pull(big_epa_cars, %s))),
        palette = '%s' 
        )
        )", 
        input$x, 
        input$y,  
        input$color, 
        input$color, 
        input$palette 
      )
    } 
    
    if (type == "hist"){
      color <- sym(input$color)
      r$plot <- ggplot(big_epa_cars, aes(!!x, fill = !!color)) +
        geom_histogram(bins = input$bins)+ 
        scale_fill_manual(
          values = color_values(
            1:length(unique(dplyr::pull(big_epa_cars, !!color))), 
            palette = input$palette
          )
        )
      
      r$code <- sprintf(
        "ggplot(big_epa_cars, aes(%s, fill = %s)) +
        geom_histogram(bins = %s)+ 
        scale_fill_manual(
          values = color_values(
            1:length(unique(dplyr::pull(big_epa_cars, %s))), 
            palette = '%s'
          )
        )", 
        input$x, 
        input$color, 
        input$bins, 
        input$color, 
        input$palette 
      )
    } 
    
    if (type == "boxplot"){
      y <- sym(input$y)
      r$plot <- ggplot(big_epa_cars, aes(x = !!x, y = !!y)) +
        geom_boxplot() 
      r$code <- sprintf(
        "ggplot(big_epa_cars, aes(x = %s, y = %s)) + 
        geom_boxplot()", 
        input$x, 
        input$y
      )
      
    }
    
    if (type == "barplot"){
      fill <- sym(input$fill)
      r$plot <- ggplot(big_epa_cars, aes(!!x, fill = !!fill)) +
        geom_bar()+ 
        scale_fill_manual(
          values = color_values(
            1:length(unique(dplyr::pull(big_epa_cars, !!fill))), 
            palette = input$palette
          )
        )
      
      r$code <- sprintf(
        "ggplot(big_epa_cars, aes(%s, fill = %s)) +
        geom_bar()+ 
        scale_fill_manual(
          values = color_values(
            1:length(unique(dplyr::pull(big_epa_cars, %s))), 
            palette = '%s'
          )
        )", 
        input$x, 
        input$fill, 
        input$fill, 
        input$palette 
      )
      
      if (input$coord_flip){
        r$plot <-  r$plot + coord_flip()
        
        r$code <- sprintf(
          "%s
          + coord_flip()", 
          r$code
        )
      }
    } 
    
    r$plot <- r$plot +  
      labs(caption = "via https://connect.thinkr.fr/tidytuesday201942") + 
      get(input$theme)()
    
    r$code <- sprintf(
      '%s + 
      labs(caption = "via https://connect.thinkr.fr/tidytuesday201942") +  
      %s()', 
      r$code, input$theme
    )
    
    if (input$title != ""){
      r$plot <- r$plot + 
        labs(title = input$title)
      r$code <- sprintf(
        '%s +\n  labs(title = "%s")', 
        r$code, input$title
      )
    }
  })
  
  
  output$plot <- renderPlot({
    r$plot
  })
  
  mod <- function() {
    modalDialog(
      tagList(
        tags$code(
          id = ns("codeinner"),
          tags$pre(
            paste(style_text(r$code), collapse = "\n")
          )
        )
      ),
      footer = tagList(
        modalButton("Cancel"),
        actionButton(ns("ok"), "OK")
      )
    )
  }
  
  # Show modal when button is clicked.
  observeEvent(input$show, {
    showModal(mod())
  })
  observeEvent(input$ok, {
    removeModal()
  })
  
  output$code <- renderPlot({
    r$code
  })
  
  output$dl <- downloadHandler(
    filename = function() {
      paste('plot-', Sys.Date(), '.png', sep='')
    },
    content = function(con) {
      ggsave(con,r$plot, device = "png", width = 16, height = 8)
    }
  )
}

