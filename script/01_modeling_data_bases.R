##############################################################################-
## Project: New Fiscal Framework (Novo Arcabouço Fiscal - PLP 93/2023) - Chamber Open Data
## Script purpose: Data manipulation and raw voting matrix creation (Chamber API)
## Date: JULY 07 2026 ------------------------------

## Author: Francisco Blasco
##############################################################################-

##  Overview ----
##############################################################################-
# This script collects raw data from the Chamber of Deputies API, extracts 
# all roll-call votes regarding PLP 93/2023, and pivots the votes 
# into a binary matrix for social network analysis.

## Packages, Parameters, & Input Data ----
##############################################################################-
suppressPackageStartupMessages(library(conflicted))
suppressPackageStartupMessages(library(httr))
suppressPackageStartupMessages(library(jsonlite))
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(tidyr))
suppressPackageStartupMessages(library(purrr))
suppressPackageStartupMessages(library(readr))

conflict_prefer("filter", "dplyr")

# Paths -------------------------------------------------------------------

source("file_paths.R")


## Loading API Câmara and Getting Proposition ID  ----
##############################################################################-

url_prop <- "https://dadosabertos.camara.leg.br/api/v2/proposicoes"

# Fetching proposition information
res_prop <- GET(url_prop, query = list(siglaTipo = "PLP", numero = 93, ano = 2023)) 

dados_prop <- fromJSON(content(res_prop, "text", encoding = "UTF-8"))$dados

id_proposicao <- dados_prop |> 
  arrange(dataApresentacao) |> 
  slice(1) |> # Just to ensure we collect the root proposition ID
  pull(id)

cat("Proposition ID found:", id_proposicao, "\n")


## Gathering all Relevant Votes  ----
##############################################################################-

url_votacoes <- paste0("https://dadosabertos.camara.leg.br/api/v2/proposicoes/", id_proposicao, "/votacoes")

cat("Fetching votes. This may take a few seconds due to API instability...\n")

res_votacoes <- RETRY("GET", url_votacoes, times = 5, pause_base = 2) 

if (status_code(res_votacoes) == 200) {
  
  dados_votacoes <- fromJSON(content(res_votacoes, "text", encoding = "UTF-8"))$dados
  ids_votacoes <- dados_votacoes$id 
  
  cat("Success! Total roll-call votes found for this proposition:", length(ids_votacoes), "\n")
  
} else {
  stop("Chamber API did not respond. Status Code: ", status_code(res_votacoes))
}


## Extracting the Individual Votes  ----
##############################################################################-

# Function to access each roll-call and scrape the votes
extrair_votos <- function(id_votacao) {
  url_votos <- paste0("https://dadosabertos.camara.leg.br/api/v2/votacoes/", id_votacao, "/votos")
  res_votos <- GET(url_votos)
  
  if (status_code(res_votos) == 200) {
    conteudo <- fromJSON(content(res_votos, "text", encoding = "UTF-8"))$dados
    
    if (length(conteudo) > 0) { 
      df_votos <- tibble(
        id_votacao = id_votacao,
        deputado = conteudo$deputado_$nome,
        partido = conteudo$deputado_$siglaPartido,
        uf = conteudo$deputado_$siglaUf,
        voto_texto = conteudo$tipoVoto
      )
      return(df_votos)
    }
  }
  return(NULL)
}

# Applying the function to bind the results
df_longo_votos <- map_dfr(ids_votacoes, function(id) {
  Sys.sleep(0.5)
  extrair_votos(id)
})


## Treatment and Pivoting for the Matrix  ----
##############################################################################-

df_matriz <- df_longo_votos |>
  mutate(voto_binario = case_when(
    voto_texto == "Sim" ~ 1,
    
    # Votes considered as a rejection of the matter
    voto_texto %in% c("Não", "Abstenção", "Obstrução") ~ 0, 
    
    # Institutional abstention converted to NA for isolated mathematical calculation
    voto_texto == "Artigo 17" ~ NA_real_, 
    
    TRUE ~ NA_real_ 
  )) |> 
  select(-voto_texto) |> 
  distinct(deputado, partido, uf, id_votacao, .keep_all = TRUE) |>
  
  # Pivoting the dataframe to a matrix structure (Deputies x Votes)
  pivot_wider(
    names_from = id_votacao,
    names_prefix = "voto_",
    values_from = voto_binario
  )


## Saving the matrix  ----
##############################################################################-

write_excel_csv(df_matriz, fs::path(path_data_root, "matriz_votacoes_plp93.csv"))

cat("Process successfully finished! Matrix saved locally.\n")

