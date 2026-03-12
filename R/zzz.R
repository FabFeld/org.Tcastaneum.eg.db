datacache <- new.env(hash=TRUE, parent=emptyenv())

org.Tcastaneum.eg <- function() showQCData("org.Tcastaneum.eg", datacache)
org.Tcastaneum.eg_dbconn <- function() dbconn(datacache)
org.Tcastaneum.eg_dbfile <- function() dbfile(datacache)
org.Tcastaneum.eg_dbschema <- function(file="", show.indices=FALSE) dbschema(datacache, file=file, show.indices=show.indices)
org.Tcastaneum.eg_dbInfo <- function() dbInfo(datacache)

org.Tcastaneum.egORGANISM <- "Tribolium castaneum"

.onLoad <- function(libname, pkgname)
{
    ## Connect to the SQLite DB
    dbfile <- system.file("extdata", "org.Tcastaneum.eg.sqlite", package=pkgname, lib.loc=libname)
    assign("dbfile", dbfile, envir=datacache)
    dbconn <- dbFileConnect(dbfile)
    assign("dbconn", dbconn, envir=datacache)

    ## Create the OrgDb object
    sPkgname <- sub(".db$","",pkgname)
    db <- loadDb(system.file("extdata", paste(sPkgname,
      ".sqlite",sep=""), package=pkgname, lib.loc=libname),
                                     packageName=pkgname)
        dbNewname <- pkgname
    ns <- asNamespace(pkgname)
    assign(dbNewname, db, envir=ns)
    namespaceExport(ns, dbNewname)
}

.onUnload <- function(libpath)
{
    dbFileDisconnect(org.Tcastaneum.eg_dbconn())
}

