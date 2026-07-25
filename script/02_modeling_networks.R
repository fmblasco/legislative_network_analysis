##############################################################################-
## Project: New Fiscal Framework (Novo Arcabouço Fiscal - PLP 93/2023) - Chamber Open Data
## Script purpose: Relational network modeling and centrality calculation (Jaccard)
## Date: JULY 16 2026 ------------------------------

## Author: Francisco Blasco
##############################################################################-

##  Overview ----
##############################################################################-
# This script loads the structured binary matrix, calculates the Jaccard
# similarity to isolate real voting behavior, models the relational graph 
# (igraph), and extracts centrality and influence metrics.

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
  select(starts_with("voto_")) |> # Isolating votes for algebraic calculation
  as.matrix()

rownames(matriz_votos) <- df_matriz$deputado


## Similarity Calculation (Jaccard Index) ----
##############################################################################-

cat("Calculating Jaccard Similarity Index...\n")

dist_jaccard <- dist(matriz_votos, method = "binary")
matriz_sim_jaccard <- 1 - as.matrix(dist_jaccard)


## Data Cleaning & Threshold Definition ----
##############################################################################-

threshold <- 0.80 # Defining network threshold rigor

matriz_sim_jaccard[is.na(matriz_sim_jaccard)] <- 0

matriz_sim_jaccard[matriz_sim_jaccard < threshold] <- 0
diag(matriz_sim_jaccard) <- 0 # Removing self-loops


## Network Construction (Graph) & Metadata ----
##############################################################################-

rede_camara <- graph_from_adjacency_matrix(
  matriz_sim_jaccard, 
  mode = "undirected", 
  weighted = TRUE
)

# Reattaching node metadata
V(rede_camara)$partido <- df_matriz$partido
V(rede_camara)$uf <- df_matriz$uf
V(rede_camara)$label <- df_matriz$deputado


## Power and Influence Metrics ----
##############################################################################-

cat("Calculating centrality and modularity metrics...\n")

# Betweenness Centrality
V(rede_camara)$betweenness <- betweenness(rede_camara, normalized = TRUE)

# Degree Centrality
V(rede_camara)$degree <- degree(rede_camara)

# Clusters (Community detection algorithm)
comunidades <- cluster_louvain(rede_camara)
V(rede_camara)$comunidade_louvain <- membership(comunidades)


## Exporting to Gephi ----
##############################################################################-

write_graph(rede_camara, fs::path(path_data_root, "rede_plp93_estruturada.graphml"), format = "graphml")

cat("Success! Network exported.\n")


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


# --- TOP 10 BROKERS (Betweenness) ---

tab_articuladores <- df_resultados |>
  arrange(desc(articulacao)) |>
  select(Deputado = deputado, Partido = partido, UF = uf, 
         `Grau de Articulação` = articulacao, `Bloco Informal` = bloco_informal) |>
  head(10)

write_excel_csv(tab_articuladores, fs::path(path_tables_folder, "top_10_articuladores.csv"))

cat("--- TOP 10 BROKERS (Bridges between Blocks) ---\n")
print(knitr::kable(tab_articuladores, format = "markdown", digits = 4))
cat("\n")


# --- INFORMAL BLOCKS SIZE ---

tab_blocos <- df_resultados |>
  count(bloco_informal, name = "numero_de_deputados") |>
  arrange(desc(numero_de_deputados)) |>
  rename(`Bloco Informal` = bloco_informal, `Total de Deputados` = numero_de_deputados)

write_excel_csv(tab_blocos, fs::path(path_tables_folder, "tamanho_blocos_informais.csv"))

cat("--- INFORMAL BLOCKS SIZE (Communities) ---\n")
print(knitr::kable(tab_blocos, format = "markdown"))
cat("\n")


# --- PARTY COMPOSITION OF INFORMAL BLOCKS ---

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

cat("--- BLOCKS IDENTITY (Top 4 Parties per Block) ---\n")
print(knitr::kable(tab_composicao, format = "markdown", digits = 1))

cat("\nCSV files saved successfully!\n")

