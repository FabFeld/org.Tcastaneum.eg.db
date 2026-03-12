# org.Tcastaneum.eg.db

`org.Tcastaneum.eg.db` is an organism-specific Bioconductor-style annotation package for _Tribolium castaneum_. It provides a local SQLite-backed `OrgDb` object that can be queried through `AnnotationDbi` and related Bioconductor tooling.

The package was generated from local NCBI annotation resources using `AnnotationForge::makeOrgPackage()`. The build workflow combines structural genome annotation from a RefSeq GFF3 file with Gene Ontology mappings from both NCBI `gene2go` and a RefSeq-specific GAF file.

## Overview

This repository contains the built package source for _Tribolium castaneum_ gene annotation. The main purpose of the package is to make gene-centered annotation data available through the standard Bioconductor interfaces, especially:

- `select()`
- `keys()`
- `columns()`
- `keytypes()`

The package is designed for downstream analyses that require stable mappings between NCBI Gene IDs and annotations such as:

- gene symbols
- gene names
- chromosome assignments
- Gene Ontology terms

## Data Sources

The package was created from local copies of the following NCBI resources:

- RefSeq genome annotation in GFF3 format
- NCBI `gene2go` file
- RefSeq assembly-specific GO annotation in GAF format

The build script shown for this repository used these concrete inputs:

- `ncbi_dataset/ncbi_dataset/data/GCF_031307605.1/genomic.gff`
- `gene2go.gz`
- `GCF_031307605.1-RS_2024_04_gene_ontology.gaf.gz`

Organism metadata used during package generation:

- NCBI taxonomy ID: `7070`
- Genus: `Tribolium`
- Species: `castaneum`
- Package version: `1.0.0`

## How The Package Was Built

The package was generated with an R workflow that follows these steps:

1. Import the genomic GFF3 annotation with `rtracklayer`.
2. Extract all features of type `gene`.
3. Parse the `Dbxref` field to recover the NCBI `GeneID`, which becomes the primary key `GID`.
4. Extract gene symbol, gene description, and chromosome information from the GFF metadata.
5. Read `gene2go`, restrict it to the target taxon, and convert it into a `GID` / `GO` / `EVIDENCE` table.
6. Read the RefSeq GAF file and extract additional GO mappings.
7. Merge `gene2go` and GAF-derived GO annotations, remove duplicates, and restrict them to genes present in the GFF.
8. Standardize and clean the tables so they can be passed to `AnnotationForge::makeOrgPackage()`.
9. Build the package with `gene_info`, `chromosome`, `symbol`, and `go` tables.

Important conventions in the build process:

- `GID` is the central primary key across all tables.
- `GID` corresponds to the NCBI Gene ID parsed from the GFF3 `Dbxref` field.
- Missing symbols are replaced with synthetic values of the form `GID_<id>`.
- Missing gene names are replaced with synthetic values of the form `Gene <id>`.
- GO annotations are collected from two local sources and then deduplicated.

## Package Contents

The package installs a local annotation database in:

- `inst/extdata/org.Tcastaneum.eg.sqlite`

At load time, the package opens the SQLite database and exposes the organism annotation object through the package namespace.

The repository currently contains:

- package metadata in `DESCRIPTION` and `NAMESPACE`
- runtime loader code in `R/zzz.R`
- the SQLite annotation database in `inst/extdata/`
- manual pages in `man/`

## Installation

### Install From The Package Source Directory

From an R session in the parent directory of this repository:

```r
install.packages("org.Tcastaneum.eg.db", repos = NULL, type = "source")
```

### Build And Install Manually

```r
system("R CMD build org.Tcastaneum.eg.db")
system("R CMD INSTALL org.Tcastaneum.eg.db_1.0.0.tar.gz")
```

On Windows, installation from source may require the usual R tools setup if the environment is not already configured for package building.

### Install From GitHub

Using `remotes`:

```r
install.packages("remotes")
remotes::install_github("FabFeld/org.Tcastaneum.eg.db")
```

Using `pak`:

```r
install.packages("pak")
pak::pkg_install("FabFeld/org.Tcastaneum.eg.db")
```

## Basic Usage

Load the package together with `AnnotationDbi`:

```r
library(org.Tcastaneum.eg.db)
library(AnnotationDbi)
```

Inspect the available key types and columns:

```r
keytypes(org.Tcastaneum.eg.db)
columns(org.Tcastaneum.eg.db)
```

List example keys:

```r
head(keys(org.Tcastaneum.eg.db, keytype = "GID"))
```

Retrieve annotations for selected genes:

```r
select(
	org.Tcastaneum.eg.db,
	keys = c("660050", "660051"),
	keytype = "GID",
	columns = c("SYMBOL", "GENENAME", "GO", "EVIDENCE")
)
```

Open the underlying SQLite connection:

```r
con <- org.Tcastaneum.eg_dbconn()
DBI::dbGetQuery(con, "SELECT COUNT(*) AS n FROM genes")
```

Inspect package-level metadata:

```r
org.Tcastaneum.eg_dbfile()
org.Tcastaneum.eg_dbschema()
org.Tcastaneum.eg_dbInfo()
org.Tcastaneum.egORGANISM
```

## Rebuilding The Package

To regenerate the package from local annotation files, the build environment needs at least these R packages:

- `AnnotationForge`
- `rtracklayer`
- `GO.db`
- `dplyr`
- `readr`
- `stringr`

The generation script used for this package follows the pattern below:

1. Install and load the required packages.
2. Read the genome annotation from the local GFF3 file.
3. Build the `gene_info` table with `GID`, `SYMBOL`, `GENENAME`, and chromosome data.
4. Build the GO table by merging taxon-filtered `gene2go` with assembly-specific GAF annotations.
5. Pass the cleaned tables into `AnnotationForge::makeOrgPackage()` with the organism metadata.

The key `makeOrgPackage()` inputs in this repository were:

- `gene_info = gene_info_clean`
- `chromosome = chromosome`
- `symbol = symbol_tbl`
- `go = go_out`
- `tax_id = "7070"`
- `genus = "Tribolium"`
- `species = "castaneum"`

## Adapting The Workflow To Another Organism

The generation workflow can be reused for other non-model organisms if the corresponding local NCBI files are available. The required changes are:

1. Replace the GFF3 path with the target organism's genome annotation.
2. Change the NCBI taxonomy ID used to filter `gene2go`.
3. Use the appropriate assembly-specific GAF file.
4. Update the `genus`, `species`, and package naming metadata.

The most important assumption is that the GFF3 file contains a `Dbxref` field with an NCBI `GeneID:<id>` entry that can be parsed into the primary key.

## Limitations And Assumptions

- The package is only as complete as the local NCBI files used during package generation.
- Gene identifiers are derived from the GFF3 `Dbxref` field; entries without a recoverable `GeneID` are excluded.
- Missing symbols and names are filled with placeholders to satisfy `makeOrgPackage()` input requirements.
- GO annotations are the union of `gene2go` and the assembly-specific GAF after duplicate removal.
- The package currently focuses on core gene and GO annotation rather than a broader set of external identifier mappings.

## Repository Structure

```text
DESCRIPTION            Package metadata
NAMESPACE              Namespace declarations and exports
R/zzz.R                Package startup and database connection code
inst/extdata/          Bundled SQLite annotation database
man/                   Package manual pages
README.md              Project documentation
```

## Validation

The package can be checked with standard R package tooling:

```r
system("R CMD build .")
system("R CMD check --no-manual org.Tcastaneum.eg.db_1.0.0.tar.gz")
```

The `--no-manual` flag is useful on systems without a LaTeX installation.

## Maintainer

Fabian Essfeld  
fabian.essfeld@ime.fraunhofer.de
