## ddmatrix-stripped rpca from pbdML

rsvd.checkargs <- function(x, k, q, retu, retvt)
{
  if (k > nrow(x))
    comm.stop("'k' must be no greater than nrow(x)")
  
  invisible(TRUE)
}

rsvd <- function(x, k=1, q=3, retu=TRUE, retvt=TRUE)
{
  rsvd.checkargs(x=x, k=k, q=q, retu=retu, retvt=retvt)
  
  x <- as.matrix(x)
  k <- as.integer(k)
  q <- as.integer(q)
  

  ### Stage A from the paper
  n <- ncol(x)
  
  Omega <- matrix(runif(n*2L*k), nrow=n, ncol=2L*k)
  
  Y <- x %*% Omega
  Q <- qr.Q(qr(Y))
  
  for (i in 1:q)
  {
    Y <- crossprod(x, Q)
    Q <- qr.Q(qr(Y))
    Y <- x %*% Q
    Q <- qr.Q(qr(Y))
  }
  
  
  ### Stage B
  B <- crossprod(Q, x)
  
  if (!retu)
    nu <- 0
  else
    nu <- min(nrow(B), ncol(B))
  
  if (!retvt)
    nv <- 0
  else
    nv <- min(nrow(B), ncol(B))
  
  svd.B <- La.svd(x=B, nu=nu, nv=nv)
  
  d <- svd.B$d
  d <- d[1L:k]
  
  
  # Produce u/vt as desired
  if (retu)
  {
    u <- svd.B$u
    u <- Q %*% u
    
    u <- u[, 1L:k, drop=FALSE]
  }
  
  if (retvt)
  {
    vt <- svd.B$vt[1L:k, , drop=FALSE]
  }
  
  # wrangle return
  if (retu)
  {
    if (retvt)
      svd <- list(d=d, u=u, vt=vt)
    else
      svd <- list(d=d, u=u)
  }
  else
  {
    if (retvt)
      svd <- list(d=d, vt=vt)
    else
      svd <- list(d=d)
  }
  
  return( svd )
}

rpca <- function(x, k=1, q=3, retx=TRUE, center=TRUE, scale=FALSE)
{
  if (center || scale)
    x <- scale(x, center=center, scale=scale)
  
  svd <- rsvd(x=x, k=k, q=q, retu=FALSE, retvt=TRUE)
  svd$d <- svd$d / sqrt(nrow(x) - 1L)
  
  if (center)
    center <- attr(x, "scaled:center")[1:k]
  if (scale)
    scale <- attr(x, "scaled:scale")[1:k]
  
  pca <- list(sdev=svd$d, rotation=t(svd$vt), center=center, scale=scale)
  
  if (is.matrix(x))
    colnames(pca$rotation) <- paste0("PC", 1:ncol(pca$rotation))
  #  else #FIXME
  
  if (retx)
    pca$x <- x %*% pca$rotation
  class(pca) <- "prcomp"
  
  return(pca)
}