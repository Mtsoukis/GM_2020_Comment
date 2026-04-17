rm(list = ls())

bootstrap_paths <- local({
  cmd_args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", cmd_args, value = TRUE)
  candidate_dirs <- character(0)

  if (length(file_arg)) {
    candidate_dirs <- c(
      candidate_dirs,
      dirname(normalizePath(sub("^--file=", "", file_arg[1]), winslash = "/", mustWork = FALSE))
    )
  }

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
    candidate_dirs <- c(candidate_dirs, dirname(tail(ofiles[!is.na(ofiles)], 1)))
  }

  candidate_dirs <- unique(c(candidate_dirs, getwd()))
  helper_candidates <- unique(c(
    file.path(candidate_dirs, "..", "R", "replication_paths.R"),
    file.path(candidate_dirs, "R", "replication_paths.R")
  ))
  helper_path <- helper_candidates[file.exists(helper_candidates)][1]

  if (!length(helper_path) || is.na(helper_path)) {
    stop("Could not locate Replication_Package/R/replication_paths.R.", call. = FALSE)
  }

  helper_path
})
source(bootstrap_paths, local = TRUE)
rm(bootstrap_paths)

codes_dir <- rp_require_dir("Codes")
scripts <- sort(list.files(codes_dir, pattern = "\\.[Rr]$", recursive = TRUE, full.names = TRUE))
scripts <- scripts[basename(scripts) != "Master.R"]

cat("Replication package root:", replication_root, "\n")

for (s in scripts) {
  cat(">>> Running:", s, "\n")
  source(
    s,
    local = new.env(parent = globalenv()),
    chdir = TRUE,
    echo = TRUE,
    max.deparse.length = Inf
  )
}

cat("All R scripts completed successfully.\n")
