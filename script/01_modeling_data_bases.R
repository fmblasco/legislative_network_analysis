##############################################################################-
## Project: Novo Arcabouço Fiscal (PLP 93/2023) - Dados Abertos Câmara
## Script purpose: Manipulação das bases e matriz bruta de votações (API da Câmara)
## Date: JULY 07 2026 ------------------------------

## Author: Francisco Blasco
##############################################################################-

##  Overview ----
##############################################################################-
# Este script coleta os dados brutos da API da Câmara dos Deputados, extrai 
# todas as votações nominais referentes ao PLP 93/2023 e pivoteia os votos 
# em uma matriz binária para análise de redes sociais.

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


## Loading API Câmara and Getting Proposal ID  ----
##############################################################################-

url_prop <- "https://dadosabertos.camara.leg.br/api/v2/proposicoes"

# Preenchimento com informações da proposição
res_prop <- GET(url_prop, query = list(siglaTipo = "PLP", numero = 93, ano = 2023)) 

dados_prop <- fromJSON(content(res_prop, "text", encoding = "UTF-8"))$dados

id_proposicao <- dados_prop |> 
  arrange(dataApresentacao) |> 
  slice(1) |> # Apenas para garantir que coletamos o ID da proposição raiz
  pull(id)

cat("ID da Proposição encontrado:", id_proposicao, "\n")


## Gathering all Relevant Votes  ----
##############################################################################-

url_votacoes <- paste0("https://dadosabertos.camara.leg.br/api/v2/proposicoes/", id_proposicao, "/votacoes")

cat("Buscando votações. Isso pode levar alguns segundos devido à instabilidade da API...\n")

res_votacoes <- RETRY("GET", url_votacoes, times = 5, pause_base = 2) 

if (status_code(res_votacoes) == 200) {
  
  dados_votacoes <- fromJSON(content(res_votacoes, "text", encoding = "UTF-8"))$dados
  ids_votacoes <- dados_votacoes$id 
  
  cat("Sucesso! Total de votações encontradas para esta proposição:", length(ids_votacoes), "\n")
  
} else {
  stop("A API da Câmara não respondeu. Status Code: ", status_code(res_votacoes))
}


## Extracting the Individual Votes  ----
##############################################################################-

# Função para entrar em cada votação e raspar os votos
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

# Aplicando a função para empilhar os resultados
df_longo_votos <- map_dfr(ids_votacoes, function(id) {
  Sys.sleep(0.5)
  extrair_votos(id)
})


## Treatment and Pivoting for the Matrix  ----
##############################################################################-

df_matriz <- df_longo_votos |>
  mutate(voto_binario = case_when(
    voto_texto == "Sim" ~ 1,
    
    # Votos considerados como posição de rejeição à matéria
    voto_texto %in% c("Não", "Abstenção", "Obstrução") ~ 0, 
    
    # Abstenção institucional convertida em NA para cálculo matemático isolado
    voto_texto == "Artigo 17" ~ NA_real_, 
    
    TRUE ~ NA_real_ 
  )) |> 
  select(-voto_texto) |> 
  distinct(deputado, partido, uf, id_votacao, .keep_all = TRUE) |>
  
  # Pivoteamento da base para estrutura matricial (Deputados x Votações)
  pivot_wider(
    names_from = id_votacao,
    names_prefix = "voto_",
    values_from = voto_binario
  )


## Saving the matrix  ----
##############################################################################-

write_excel_csv(df_matriz, fs::path(path_data_root, "matriz_votacoes_plp93.csv"))

cat("Processo finalizado com sucesso! Matriz salva localmente.\n")

