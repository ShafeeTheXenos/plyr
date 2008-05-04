# To arrays  ----------------------------------------------------------------
# aa = iapply
# al -> ll -> la = iapply
# ad -> dl -> la = iapply
# la, da = ?  (but should hopefully match with aggregate)
#
# da(df, .(a), single.value) = 1 d
# da(df, .(a, b), , single.value) = 2 d
# da(df, .(a, b), vector)  = 3d

laply <-  function(data, fun = NULL, ..., .try = FALSE, .quiet = FALSE, .explode = FALSE, .progress = NULL) {
  f <- robustify(fun, .try = .try, .quiet = .quiet, .explode = .explode)
    
  data <- as.list(data)
  res <- llply(data, f, ..., .progress = .progress)
  
  atomic <- sapply(res, is.atomic)
  if (all(atomic)) {
    # Atomics need to be same size
    dlength <- unique(llply(res, dims))
    if (length(dlength) != 1) stop("Results must have same number of dimensions.")

    dims <- unique(do.call("rbind", llply(res, vdim)))
    if (nrow(dims) != 1) stop("Results must have the same dimensions.")    

    res_dim <- vdim(res[[1]])
    res_labels <- dimnames2(res[[1]])
    res_index <- expand.grid(res_labels)

    res <- unlist(res)
  } else {
    # Lists are degenerate case where every element is a singleton
    res_index <- as.data.frame(matrix(0, 1, 0))
    res_dim <- numeric()
    res_labels <- NULL
    
    attr(res, "split_type") <- NULL
    attr(res, "split_labels") <- NULL
    class(res) <- class(res)[2]
  }

  labels <- attr(data, "split_labels")
  if (is.null(labels)) {
    labels <- data.frame(X = seq_along(data))
    in_labels <- list(NULL)
    in_dim <- length(data)
  } else {
    in_labels <- lapply(labels, unique)
    in_dim <- sapply(in_labels, length)        
  }

  
  index <- cbind(
    labels[rep(seq_len(nrow(labels)), each = nrow(res_index)), , drop = FALSE],
    res_index[rep(seq_len(nrow(res_index)), nrow(labels)), , drop = FALSE]
  )
  
  out_dim <- c(in_dim, res_dim)
  out_labels <- c(in_labels, res_labels)
  n <- prod(out_dim)

  overall <- order(ninteraction(index))
  if (length(overall) < n) overall <- match(1:n, overall, nomatch = NA)
  
  out_array <- res[overall]  
  dim(out_array) <- out_dim
  dimnames(out_array) <- out_labels
  reduce(out_array)
}

#X daply(baseball, .(year), nrow)
#X
#X # Several different ways of summarising by variables that should not be 
#X # included in the summary
#X 
#X daply(baseball[, c(2, 6:9)], .(year), mean)
#X daply(baseball[, 6:9], .(baseball$year), mean)
#X daply(baseball, .(year), function(df) mean(df[, 6:9]))
daply <- function(data, vars, fun = NULL, ..., .try = FALSE, .quiet = FALSE, .explode = FALSE, .progress = NULL) {
  data <- as.data.frame(data)
  pieces <- splitter_d(data, vars)
  
  laply(pieces, fun, .try = .try, .quiet = .quiet, .explode = .explode, .progress = .progress)
}

aaply <- function(data, margins, fun = NULL, ..., .try = FALSE, .quiet = FALSE, .explode = FALSE, .progress = NULL) {
  pieces <- splitter_a(data, margins)
  
  laply(pieces, fun, .try = .try, .quiet = .quiet, .explode = .explode, .progress = .progress)
}