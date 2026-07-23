##############################################################################-
## Project: Novo Arcabouço Fiscal (PLP 93/2023) - Dados Abertos Câmara
## Script purpose: Modelagem da rede relacional e cálculo de centralidades (Jaccard)
## Date: JULY 16 2026 ------------------------------

## Author: Francisco Blasco
##############################################################################-

##  Overview ----
##############################################################################-
# Este script carrega a matriz binária estruturada, calcula a similaridade
# de Jaccard para isolar o comportamento real de votação, modela o grafo 
# relacional (igraph) e extrai métricas de centralidade e influência.

## Packages, Parameters, & Input Data ----
##############################################################################-
suppressPackageStartupMessages(library(conflicted))
suppressPackageStartupMessages(library(readr))
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(tibble))
suppressPackageStartupMessages(library(igraph))
suppressPackageStartupMessages(library(knitr))

conflict_prefer("filter", "dplyr")
conflict_prefer("select", "dplyr")
conflict_prefer("arrange", "dplyr")
conflict_prefer("as_data_frame", "igraph")

# Paths -------------------------------------------------------------------

source("file_paths.R")


## Data Import ----
##############################################################################-

df_matriz <- read_csv(fs::path(path_data_root, "matriz_votacoes_plp93.csv"), show_col_types = FALSE)


## Mathematical Matrix Preparation ----
##############################################################################-

matriz_votos <- df_matriz |>
  select(starts_with("voto_")) |> # Isolando os votos para o cálculo algébrico
  as.matrix()

rownames(matriz_votos) <- df_matriz$deputado


## Similarity Calculation (Jaccard Index) ----
##############################################################################-

cat("Calculando Índice de Similaridade de Jaccard...\n")

dist_jaccard <- dist(matriz_votos, method = "binary")
matriz_sim_jaccard <- 1 - as.matrix(dist_jaccard)


## Data Cleaning & Threshold Definition ----
##############################################################################-

threshold <- 0.80 # Definição do rigor da rede

matriz_sim_jaccard[is.na(matriz_sim_jaccard)] <- 0

matriz_sim_jaccard[matriz_sim_jaccard < threshold] <- 0
diag(matriz_sim_jaccard) <- 0 # Removendo as autoconexões


## Network Construction (Graph) & Metadata ----
##############################################################################-

rede_camara <- graph_from_adjacency_matrix(
  matriz_sim_jaccard, 
  mode = "undirected", 
  weighted = TRUE
)

# Voltando com os metadados dos nodos
V(rede_camara)$partido <- df_matriz$partido
V(rede_camara)$uf <- df_matriz$uf
V(rede_camara)$label <- df_matriz$deputado


## Power and Influence Metrics ----
##############################################################################-

cat("Calculando métricas de centralidade e modularidade...\n")

# Betweenness (Intermediação)
V(rede_camara)$betweenness <- betweenness(rede_camara, normalized = TRUE)

# Degree (Grau)
V(rede_camara)$degree <- degree(rede_camara)

# Clusters (Algoritmo de comunidades)
comunidades <- cluster_louvain(rede_camara)
V(rede_camara)$comunidade_louvain <- membership(comunidades)


## Exporting to Gephi ----
##############################################################################-

write_graph(rede_camara, fs::path(path_data_root, "rede_plp93_estruturada.graphml"), format = "graphml")

cat("Sucesso! Rede exportada.\n")


## Centralities Extraction & Analysis ----
##############################################################################-

df_resultados <- tibble(
  deputado    = V(rede_camara)$name,
  partido     = V(rede_camara)$partido,
  uf          = V(rede_camara)$uf,
  bloco_informal = V(rede_camara)$comunidade_louvain,
  articulacao = V(rede_camara)$betweenness,
  total_aliados = V(rede_camara)$degree
)

write_excel_csv(df_resultados, fs::path(path_data_root, "resultados_centralidades_plp93.csv"))


# --- TOP 10 ARTICULADORES (Betweenness) ---

tab_articuladores <- df_resultados |>
  arrange(desc(articulacao)) |>
  select(Deputado = deputado, Partido = partido, UF = uf, 
         `Grau de Articulação` = articulacao, `Bloco Informal` = bloco_informal) |>
  head(10)

write_excel_csv(tab_articuladores, fs::path(path_tables_folder, "top_10_articuladores.csv"))

cat("--- TOP 10 ARTICULADORES (Pontes entre Blocos) ---\n")
print(knitr::kable(tab_articuladores, format = "markdown", digits = 4))
cat("\n")


# --- TAMANHO DOS BLOCOS INFORMAIS ---

tab_blocos <- df_resultados |>
  count(bloco_informal, name = "numero_de_deputados") |>
  arrange(desc(numero_de_deputados)) |>
  rename(`Bloco Informal` = bloco_informal, `Total de Deputados` = numero_de_deputados)

write_excel_csv(tab_blocos, fs::path(path_tables_folder, "tamanho_blocos_informais.csv"))

cat("--- TAMANHO DAS BANCADAS INFORMAIS (Comunidades) ---\n")
print(knitr::kable(tab_blocos, format = "markdown"))
cat("\n")


# --- COMPOSIÇÃO PARTIDÁRIA DOS BLOCOS INFORMAIS ---

tab_composicao <- df_resultados |>
  count(bloco_informal, partido) |>
  group_by(bloco_informal) |>
  mutate(percentual = n / sum(n) * 100) |>
  arrange(bloco_informal, desc(n)) |>
  slice_head(n = 4) |> 
  ungroup() |>
  rename(`Bloco Informal` = bloco_informal, Partido = partido, 
         `Qtd Deputados` = n, `Peso no Bloco (%)` = percentual)

write_excel_csv(tab_composicao, fs::path(path_tables_folder, "composicao_partidaria_blocos.csv"))

cat("--- IDENTIDADE DOS BLOCOS (Top 4 Partidos por Bloco) ---\n")
print(knitr::kable(tab_composicao, format = "markdown", digits = 1))

cat("\nArquivos CSV salvos com sucesso!\n")

