## Start of function definitions ##########################################

source("rpca.R") # extracted rpca from pbdML without pbdDMAT

## prints elapsed time since ltime
deltime <- function(ltime=proc.time()["elapsed"], text=NULL) {
  time <- proc.time()["elapsed"]
  if(!is.null(text))
    cat(text, time - ltime, "\n")
  invisible(time)
}

## plots a path of centroid moves or the structure as point cloud
gg3d = function(dat, type = c("path", "struct"), xl = NULL, yl = NULL) {
  library(ggforce)
  dat = cbind(as.data.frame(dat), time = 1:nrow(dat))
  names(dat) = c("x", "y", "z", "time")
  s = function(p) {
    p = p + geom_point(alpha = 0.25)
    if(type =="path") p = p + geom_path()
    p + coord_fixed() + theme(legend.position = "none")
  }
  pyx = s(ggplot(dat, aes(y, x, color = z)))
  if(!is.null(xl)) pyx = pyx + xlim(xl[1], xl[2])
  if(!is.null(yl)) pyx = pyx + ylim(yl[1], yl[2])
  pzx = s(ggplot(dat, aes(z, x, color = y)))
  if(!is.null(xl)) pzx = pzx + xlim(xl[1], xl[2])
  if(!is.null(yl)) pzx = pzx + ylim(yl[1], yl[2])
  pyz = s(ggplot(dat, aes(y, z, color = x)))
  if(!is.null(xl)) pyz = pyz + xlim(xl[1], xl[2])
  if(!is.null(yl)) pyz = pyz + scale_y_reverse(limits = c(yl[2], yl[1]))
  wx = diff(range(dat$x))
  wy = diff(range(dat$y))
  wz = diff(range(dat$z))
  egg::ggarrange(pyx, pzx, pyz, widths = c(wy, wz), heights =c(wx, wy), draw = FALSE )
}

## makes a movie from point cloud structures
gg3dmovie = function(file, time, dat, type, xl, yl) {
  step3d = function(i, file, dat, type, xl, yl, device) {
    fl = paste0(file, sprintf("%05d", i), ".pdf")
    pdf(fl, width = 8, height = 8)
    print(gg3d(t(dat[, , i]), type, xl, yl))
    invisible(dev.off())
  }
  parallel::mclapply(time, step3d, file = file, dat = dat, type = "struct",
                     xl = xl, yl = yl, device = "png", mc.cores = 1)
  ## !! parallel plotting is not possible with mclapply because the plotting device is a "state" in R that is turned off by dev.off(). Meaning that all output goes to the same file!!!
  #  for(i in time) {
  #    fl = paste0(file, sprintf("%05d", i), ".png")
  #    ggsave(fl, gg3d(t(dat[, , i]), "struct", xl, yl), device = "png")
  #  }
}

## constructs point clouds from PCA components and calls movie maker
gg3d_svdPlay = function(prc, comp, dir = "mov") {
  file = paste0(dir, "/gg3d_svdPlay")
  u = prc$rotation[, comp]
  vt = prc$x[comp, ]
  d = prc$sdev[comp]
  drem = prc$sdev[-comp]
  if(length(comp) == 1) {
    dim(u) = c(length(u), 1)
    dim(vt) = c(1, length(vt))
  }
  xyzt = t(u %*% diag(d, nrow = length(comp)) %*% vt)
  dim(xyzt) = c(3, np, nt)
  dim(prc$center) = c(3, np)
  xyzt = sweep(xyzt, c(1,2), prc$center, FUN = "+")
  #  gg3d(t(xyzt[, , 1]), "xyzt", c(-4, 4), c(-4, 4))
  gg3dmovie(file, 1:nt, xyzt, "struct", c(-4, 4), c(-4, 4))
}

## Compute the Euler angles from a 3d rotation matrix
## from Directional package
rot2eul = function (X) 
{
  v1 = numeric(3)
  v2 = numeric(3)
  x1.13 = asin(X[3, 1])
  x2.13 = pi - x1.13
  x1.23 = atan2(X[3, 2]/cos(x1.13), X[3, 3]/cos(x1.13))
  x2.23 = atan2(X[3, 2]/cos(x2.13), X[3, 3]/cos(x2.13))
  x1.12 = atan2(X[2, 1]/cos(x1.13), X[1, 1]/cos(x1.13))
  x2.12 = atan2(X[2, 1]/cos(x2.13), X[1, 1]/cos(x2.13))
  v1 = c(x1.13, x1.23, x1.12)
  v2 = c(x2.13, x2.23, x2.12)
  list(v1 = v1, v2 = v2)
}

## compute size of a point cloud
size_xyz = function(xyz, centroid, type = c("frobenius", "centroid")) {
  vsq = sweep(xyz, 1, centroid)^2 # sweep out centroid and square
  if(type[1] == "frobenius") {
    return(sqrt(sum(vsq)))  # sqrt of total sum of squares
  } else if(type[1] == "centroid") {
    ## check if vsq is same dimension as xyz
    return(sum(sqrt(apply(vsq, 2, sum)))) # sum of distances to centroid
  } else stop("size_xyz: unknown type")
}

#' Procrustes PCA of a spatio-temporal cloud
#' Follows description in "A Brief Introduction to Statistical Shape Analysis"
#'        (#) refer to steps in 3.2 Generalized Procrustes Analysis
#' @param xyzt List of xyz point clouds
#' @param mccores Number of cores for mclapply and mcmapply forks
#' @param size Method to use in point cloud size alignment ("none" for no
#' alignment)
proc_pca = function(xyzt, mccores, size = c("frobenius", "centroid", "none")) {
  nt = length(xyzt) # number of time steps
  np = dim(xyzt[[1]])[2] # number of points
  s0 = size_xyz(xyzt[[1]], rowSums(xyzt[[1]])/np, size[1]) # size of first cloud
  
  if(size != "none") { 
    ## Scale all to be the same size
    centroids = lapply(xyzt, function(x) rowSums(x)/np)
    xyzt_s = mapply(function(x, c, s, t) x*(s/size_xyz(x, c, t)),
                    xyzt, centroids, MoreArgs = list(s = s0, t = size[1]),
                    SIMPLIFY = FALSE)
  }

  ## Align centroids to origin
  centroids = lapply(xyzt_s, function(x) rowSums(x)/np)
  xyzt_cs = mapply(function(xyz, centroid) sweep(xyz, 1, centroid),
                  xyzt_s, centroids, SIMPLIFY = FALSE)
    
  ## Iterate to get mean shape
  xyz_mi = xyzt_cs[[1]] # (1) use first shape to start
  for(i in 1:5) {
    ## find mean shape and translate + rotate all shapes to mean shape
    svdlist = parallel::mclapply(xyzt_cs,
                     function(xyz, mean) La.svd(tcrossprod(mean, xyz)),
                     mean = xyz_mi, mc.cores = mccores)
    ## get rotations from SVD
    rots = parallel::mclapply(svdlist, function(svd) t(svd$u %*% svd$vt),
                              mc.cores = mccores)
    xyzt_csr = parallel::mcmapply(function(rot, xyz) t(rot) %*% xyz,
                                  rots, xyzt_cs, mc.cores = mccores,
                                  SIMPLIFY = FALSE)
    ## recompute mean shape
    xyz_m = Reduce("+", xyzt_csr)/nt
    
    ## break if relative change within machine epsilon
    if(sum((xyz_mi - xyz_m)^2)/s0 < .Machine$double.eps) break
    xyz_mi = xyz_m
  }
  
  ## get Euler angles from final rotation
  euler = sapply(rots, function(x) rot2eul(x)$v1)

  ## combine list back into an array
  xyztmat = do.call(c, xyzt_csr)
  dim(xyztmat) = c(3*np, nt)

  ## get top components using randomized PCA
  xyztpca = rpca(t(xyztmat), k = 5)

  list(xyztpca = xyztpca, xyztmat = xyztmat,
       mean = xyz_m, centroids = centroids, angles = euler)
}

## manages output from computed PCA
pca_report = function(xyz_struct, k, t, plot) {
#  if(plot) pairs(xyz_struct$xyztpca$x[, 1:k])
  if(plot) {
    nt = nrow(xyz_struct$xyztpca$x)
    pdata = data.frame(xyz_struct$xyztpca$x[, 1:k], time = 1:nt)
    print(GGally::ggpairs(pdata, mapping = ggplot2::aes(color = time),
                          columns = 1:k,
                          upper = list(continuous ="points"),
                          diag = "blank", lower = "blank") +
            ggplot2::scale_color_gradient(low = "blue", high = "red"))
  }
  eig = xyz_struct$xyztpca$sd^2
##  eig_sum = cumsum(eig)
##  eig_pct = 100*eig/eig_sum[length(eig_sum)]
##  sum_pct = 100*eig_sum/eig_sum[length(eig_sum)]
  topeig = xyz_struct$xyztpca$sd[1:k]
  cat("Eigenvalues:   ", eig[1:k], "\n")
##  cat("Explained var: ", eig_pct[1:k], "\n")
##  cat("Cumulative var:", sum_pct[1:k], "\n\n")
  
  ## Create a PCA movie
  ## if(!dir.exists("mov")) dir.create("mov")
  ## gg3d_svdPlay(xyz_struct$xyztpca, c(1), dir = "mov")
}
## End of function definitions ##########################################


library(hola)
sessionInfo()
set.seed(1234971) # reproducibility of rpca

## Get parameters from command line
args = commandArgs(trailingOnly = TRUE)
window = as.numeric(args[1]) # window size for PCA
stride = as.numeric(args[2]) # stride for repeating the PCA
k = as.numeric(args[3]) # keep top PCs
file_bp = args[4] # bp file name
file_xml = args[5] # xml config file name
mccores = as.numeric(args[6]) # cores for fork parallelism
file_pdf = args[7] # output pdf file of pair plots
plot = ifelse(nchar(file_pdf) > 0, TRUE, FALSE) # print if non-empty

if(file.exists(file_xml)) { # adios() uses missing() to check for xml
  ad = adios(file_bp, config = file_xml, io_name = "SortingOutput")
  file_xml
} else {
  ad = adios(file_bp, io_name = "SortingOutput")
  file_bp
}

a0 = deltime()
## Fill a matrix with a window (nt) of steps
nt = window
xyzt = vector("list", nt)
for(i in 1:nt) {
  xyzt[[i]] = ad$read("solute/coords")
  xyztdim = dim(xyzt[[i]])
  dim(xyzt[[i]]) = xyztdim[2:1] # reverse dimensions
  ad$advance() # block until next step is available?
  ## TODO check for eof in case window too big
}
## use the first time step for number of atoms (np)
np = dim(xyzt[[1]])[2]
if(plot) pdf(file_pdf)
a = deltime(a0, "Initial window read")

##
## Generalized Procrustes Analysis aligned PCA by stride steps
##
robin = 0
t = window
while(TRUE) {
  ## GPA aligned PCA
  xyz_struct = proc_pca(xyzt, mccores, size = "frobenius")
  pca_report(xyz_struct, k, t, plot)
  a = deltime(a, "PCA stride")
  
  ## read and round-robin insert next stride steps
  for(i in seq(0, stride - 1)) {
    temp = ad$read("solute/coords")
    if(is.null(temp)) break
    dim(temp) = c(3, np)
    xyzt[[(robin + i) %% window + 1]] = temp
    ad$advance()
  }
  ## break if last read was EOF
  if(is.null(temp)) break
  
  ## next round-robin insertion offset
  robin = (robin + stride) %% window
  t = t + stride # advance time step
}
ad$close()

if(plot) dev.off()
sessionInfo()
deltime(a, "Done. End-of-file .bp")

## TODO
## (1) Improve graphics to include time in the pairs plots
## (2) Test xml interface of hola - need to discuss with Norbert and possibly
##     circle back to Drew
## (3) Consider dynamically changing window size to prepare for control 
##     mechanisms
## (4) Add linearizing projections to alignment
## 
