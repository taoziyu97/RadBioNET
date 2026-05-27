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

get_factor_links <- function(factor_name, factor_type) {
  links <- list()

  encoded <- URLencode(factor_name, reserved = TRUE)

  links[["GeneCards"]] <- paste0("https://www.genecards.org/Search/Keyword?queryString=", encoded)

  if (grepl("Gene/Protein|Transcription factor", factor_type)) {
    links[["NCBI Gene"]] <- paste0("https://www.ncbi.nlm.nih.gov/gene/?term=", encoded)
    links[["UniProt"]] <- paste0("https://www.uniprot.org/uniprotkb?query=", encoded)
    links[["STRING"]] <- paste0("https://string-db.org/api/network?identifier=", encoded)
  }

  if (grepl("Pathway", factor_type)) {
    links[["KEGG"]] <- paste0("https://www.kegg.jp/kegg-bin/search?mode=pathway&keyword=", encoded)
    links[["Reactome"]] <- paste0("https://reactome.org/content/query?q=", encoded)
  }

  if (grepl("Drug|Nanoparticle|Small molecule|Inhibitor", factor_type)) {
    links[["DrugBank"]] <- paste0("https://go.drugbank.com/unearth/q?query=", encoded)
  }

  links
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
