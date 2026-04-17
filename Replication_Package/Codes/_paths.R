resolve_current_source_path <- function() {
  frames <- sys.frames()
  ofiles <- vapply(
    frames,
    function(frame) {
      ofile <- frame$ofile
      if (is.null(ofile)) {
        return(NA_character_)
      }
      normalizePath(ofile, winslash = "/", mustWork = FALSE)
    },
    character(1)
  )

  if (any(!is.na(ofiles))) {
    return(tail(ofiles[!is.na(ofiles)], 1))
  }

  file_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  if (length(file_arg)) {
    return(
      normalizePath(
        sub("^--file=", "", file_arg[1]),
        winslash = "/",
        mustWork = FALSE
      )
    )
  }

  stop("Could not determine the current script path.", call. = FALSE)
}

replication_helper_path <- resolve_current_source_path()
replication_root <- normalizePath(
  file.path(dirname(replication_helper_path), ".."),
  winslash = "/",
  mustWork = TRUE
)

rp_path <- function(...) {
  file.path(replication_root, ...)
}

rp_require_dir <- function(...) {
  path <- rp_path(...)
  if (!dir.exists(path)) {
    stop(sprintf("Required directory not found: %s", path), call. = FALSE)
  }
  path
}

rp_require_file <- function(...) {
  path <- rp_path(...)
  if (!file.exists(path)) {
    stop(sprintf("Required file not found: %s", path), call. = FALSE)
  }
  path
}

dir.create(rp_path("Figures"), recursive = TRUE, showWarnings = FALSE)
dir.create(rp_path("Tables"), recursive = TRUE, showWarnings = FALSE)

Sys.setenv(REPLICATION_PACKAGE_ROOT = replication_root)
