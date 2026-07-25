# Análise de Redes Sociais (ARS) para Mapeamento de Stakeholders: Padrões de Votação para o Arcabouço Fiscal

![R](https://img.shields.io/badge/R-276DC3?style=for-the-badge&logo=r&logoColor=white)
![Gephi](https://img.shields.io/badge/Gephi-000000?style=for-the-badge&logo=gephi&logoColor=white)
![API](https://img.shields.io/badge/Câmara_dos_Deputados-API-green?style=for-the-badge)

## Sobre o Projeto
Na intersecção entre a Macroeconomia e a Análise Política, mensurar o risco legislativo de uma pauta complexa exige precisão. Para avaliar a previsibilidade institucional, não basta mapear todos os 513 deputados, é necessário identificar quem são os principais influenciadores, qual o **custo de transação** das negociações e como os blocos de interesse se comportam na prática, para além de suas legendas partidárias.

Este projeto utiliza **Análise de Redes Sociais Computacional** para mapear as redes de influência na Câmara dos Deputados. Como estudo de caso, modelou-se as votações do **Novo Arcabouço Fiscal (PLP 93/2023)**, demonstrando como a matemática pode esclarecer alianças informais, revelar a divisão pragmática do Centrão e identificar os *stakeholders* críticos com poder de travar ou acelerar a principal âncora econômica do país.

## Metodologia e Modelagem
O pipeline dos dados foi construído com foco em reprodutibilidade:
1. **Extração:** Raspagem automatizada via API Aberta da Câmara dos Deputados.
2. **Modelagem Algébrica:** Em vez da simples contagem de votos, aplicou-se o **Índice de Similaridade de Jaccard** para construir a matriz de adjacência, permitindo que o grafo reflita a coesão tática entre os parlamentares. Tratamento de abstenções institucionais e ausências, além da aplicação de um *threshold* restrito (0.80+) para eliminar ruídos procedimentais.
3. **Inteligência Analítica (Métricas de Rede):**
   * **Algoritmo Não-Supervisionado (Clustering):** Uso do Algoritmo de Louvain para detecção de comunidades (bancadas informais).
   * **Betweenness Centrality (Intermediação):** Cálculo para elencar os parlamentares-chave que atuam como pontes.
4. **Visualização:** Renderização topológica via Gephi (*ForceAtlas 2*).

---

## Data Storytelling: Interpretando o Arcabouço Fiscal

![Grafo Arcabouço](analysis/figures/co-voting_graph.png)

A topologia gerada pelo algoritmo é alheia à dimensão ideológica, portanto, ela agrupa parlamentares estritamente pelo comportamento. Isso nos permitiu extrair três *insights* fundamentais:

### 1. Oposição Comportamental
O **Bloco 1 (Azul)** revelou um fenômeno interessante: a união tática de extremidades. O algoritmo agrupou a direita (**PL**, 60,2% do bloco) e a esquerda (**PSOL**, 10,2%) na mesma comunidade. Embora em diferentes pontas ideológicas, ambos votaram para rejeitar a pauta em questão (o PL por oposição sistemática, o PSOL por rejeição ao teto de gastos).

### 2. Base Governista
O **Bloco 3 (Vermelho)** representa a coalizão governista orgânica. Formado majoritariamente por **PT, PDT e PSB**, é o núcleo duro de apoio operando em alta densidade e sincronia em defesa do projeto original do Ministério da Fazenda.

### 3. Fisiologia do Centrão
O grafo demonstra matematicamente que o "Centrão" (partidos fisiológicos, discutidos amplamente na literatura de comportamento partidário brasileiro) não operou como um bloco monolítico durante as rodadas de votação do Arcabouço. Eles se dividiram em duas grandes massas de negociação para aprovar emendas específicas:
*   **Bloco 4 (Laranja):** A força motriz liderada pela base de Arthur Lira (**UNIÃO Brasil e PP**).
*   **Bloco 2 (Verde):** Uma segunda ala pragmática forte, ancorada no **MDB, Republicanos e PSD**.

---

## Resultados Analíticos do Mapeamento

A métrica de *Betweenness Centrality* (Grau de Articulação) nos auxilia a identificar os stakeholders ocultos da rede.

> Na literatura institucional clássica, o "tomador de decisão" é geralmente aquele que detém o poder formal de pauta (como a Presidência da Casa). No entanto, a Teoria dos Grafos nos permite mapear uma outra camada: os **brokers**, em outras palavras, os **mediadores estratégicos**. 
>
> São deputados que não necessariamente ocupam lideranças oficiais ou aparecem nos jornais todo dia, mas que matematicamente controlam o fluxo de informação e negociação entre blocos rivais. Ao atuarem como 'pontes' (gargalos da rede), se tornam atores que detêm o poder prático de destravar ou travar a formação de maiorias.

#### Top 10 Articuladores (Brokers entre Blocos):

|Deputado            |Partido      |UF | Grau de Articulação| Bloco Informal|
|:-------------------|:------------|:--|-------------------:|--------------:|
|Gilberto Nascimento |PSD          |SP |              0.0544|              1|
|Cleber Verde        |MDB          |MA |              0.0392|              4|
|Márcio Correa       |MDB          |GO |              0.0325|              2|
|Professora Goreth   |PDT          |AP |              0.0304|              3|
|Dr. Daniel Soranz   |PSD          |RJ |              0.0292|              4|
|Any Ortiz           |CIDADANIA    |RS |              0.0292|              4|
|Pedro Westphalen    |PP           |RS |              0.0270|              1|
|Duda Ramos          |MDB          |RR |              0.0265|              2|
|Zé Vitor            |PL           |MG |              0.0249|              3|
|Messias Donato      |REPUBLICANOS |ES |              0.0215|              1|

#### Dimensionamento das Bancadas (Comunidades):

Para entender o peso e a proporção de cada grupo na negociação, o algoritmo agrupou o plenário nas seguintes densidades comportamentais:

| Bloco Informal| Total de Deputados|
|--------------:|------------------:|
|              4|                138|
|              2|                132|
|              3|                132|
|              1|                128|

#### Composição Partidária (Análise interna dos Blocos):

Desagregando as comunidades, podemos visualizar as alianças tranversais entre partidos:

| Bloco Informal|Partido      | Qtd Deputados| Peso no Bloco (%)|
|--------------:|:------------|-------------:|-----------------:|
|              1|PL           |            77|              60.2|
|              1|PSOL         |            13|              10.2|
|              1|UNIÃO        |            10|               7.8|
|              1|PP           |             6|               4.7|
|              2|MDB          |            36|              27.3|
|              2|REPUBLICANOS |            36|              27.3|
|              2|PSD          |            24|              18.2|
|              2|PODE         |             9|               6.8|
|              3|PT           |            59|              44.7|
|              3|PDT          |            17|              12.9|
|              3|PSB          |            14|              10.6|
|              3|PSD          |            12|               9.1|
|              4|UNIÃO        |            46|              33.3|
|              4|PP           |            36|              26.1|
|              4|PL           |            17|              12.3|
|              4|PSD          |             8|               5.8|


## 💻 Estrutura do Projeto e Reprodutibilidade

O repositório está organizado da seguinte forma para garantir o acompanhamento da análise e a transparência do código:

```text
legislative_network_analysis/
├── analysis/                             # Resultados exportados da modelagem
│   ├── figures/                          # Visualização gerada (grafo)
│   └── tables/                           # Tabelas consolidadas com métricas e blocos
├── data/                                 # Diretório para armazenamento das bases brutas e tratadas
├── gephi_workspaces/      
│   └── Network_Gephi.gephi               # Workspace com a topologia final modelada (basta abrir diretamente no software Gephi)
├── script/                
│   ├── 01_modeling_data_bases.R          # Extração via API, tratamento e matriz two-mode
│   └── 02_modeling_networks.R            # Matriz de adjacência, algoritmos de rede (igraph)
├── file_paths.R                          # Gerenciamento dinâmico de diretórios locais
├── legislative_network_analysis.Rproj    # Arquivo principal do ambiente RStudio
└── README.md                             # Documentação analítica
```

Para reproduzir a análise, basta clonar o repositório e abrir o projeto no RStudio através do arquivo `legislative_network_analysis.Rproj`. Antes de rodar os scripts, certifique-se de ter os pacotes necessários. Você pode executar o bloco abaixo no seu console do R para verificar e instalar automaticamente apenas o que estiver faltando no seu ambiente:

```R
# Lista de dependências exatas do projeto
pacotes <- c("conflicted", "httr", "jsonlite", "dplyr", "tidyr", 
             "purrr", "readr", "tibble", "igraph", "knitr")

# Verificando
pacotes_faltantes <- pacotes[!(pacotes %in% installed.packages()[,"Package"])]
if(length(pacotes_faltantes)) install.packages(pacotes_faltantes)
lapply(pacotes, library, character.only = TRUE)
```

---

## Autor
**Francisco Blasco**  
*Graduando em Relações Econômicas Internacionais e Pesquisador no Centro de Estudos Legislativos (CEL-DCP/UFMG).*
