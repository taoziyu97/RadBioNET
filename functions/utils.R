box_voronoys <- function(texto, cor) {
  HTML(paste('<div class = "box_voronoys" style = "border:1px solid',
             cor, '; background-color: ',
             cor, ';">',
             h3(texto), '</div>'))
}

tab_voronoys <- function(texto, cor, icon, id) {
  HTML(paste0('<a id="', id,'" href="#" class="action-button">
                  <div class = "voronoys-block" style = "background-color:', cor, ';">
                  <span class = "name">', texto, '</span>
                  <div class="img_block">
                    <div class="img_block_conteiner">
                      <img src="img/',icon,'">
                    </div>
                  </div>
              </div></a>'))
}

nav_block <- function(title, subtitle, cor, icon, id) {
  HTML(paste0('<div class = "voronoys-block" style = "background-color:', cor, ';" onclick="Shiny.setInputValue(\'', id, '\', \'click\', {priority: \'event\'});">
                  <span class = "name">', title, '<br><span style="font-size:10px;font-weight:400;text-transform:none;opacity:0.9;">', subtitle, '</span></span>
                  <div class="img_block">
                    <div class="img_block_conteiner">
                      <img src="img/',icon,'">
                    </div>
                  </div>
              </div>'))
}

render_markdown <- function(text) {
  if (is.null(text) || is.na(text)) return("")
  text <- gsub("\\*\\*(\\S.*?\\S)\\*\\*", "<strong>\\1</strong>", text)
  text <- gsub("\\*(\\S.*?\\S)\\*", "<em>\\1</em>", text)
  text <- gsub("`([^`]+)`", "<code>\\1</code>", text)
  text <- gsub("\\[([^]]+)\\]\\(([^)]+)\\)", "<a href='\\2' target='_blank'>\\1</a>", text)
  text <- gsub("\n{2,}", "</p><p>", text)
  text <- gsub("\n", "<br>", text)
  text <- paste0("<p>", text, "</p>")
  text
}
