

##' Riccati-Bessel function psi and its derivative
##'
##' Obtained from BesselJ, converted to spherical Bessel, and scaled
##' @title psi
##' @param rho complex vector, argument
##' @param nmax integer, maximum order
##' @return a list with psi_n and psi'_n
##' @author Baptiste Auguie
##' @export
psi <- function(rho, nmax){

  nvec <- seq.int(nmax)
  nmat <- matrix(nvec, ncol=nmax, nrow=length(rho), byrow=TRUE)
  rhomat <- matrix(rho, ncol=nmax, nrow=length(rho), byrow=FALSE)
  psi <- sqrt(rho * pi/2) * BesselJ(rho, 1/2, expon.scaled = FALSE, nSeq = nmax+1)
  psip <- psi[ , nvec] - nmat * psi[ , nvec + 1] / rhomat
  
  list(psi = psi[ , -1], psip = psip)
  
}


##' Riccati-Bessel function xi and its derivative
##'
##' Obtained from BesselH (Hankel function), converted to spherical Hankel, and scaled
##' @title xi
##' @param rho complex vector, argument
##' @param nmax integer, maximum order
##' @return a list with psi_n and psi'_n
##' @author Baptiste Auguie
##' @export
xi <- function(rho, nmax){
  
  nvec <- seq.int(nmax)
  nmat <- matrix(nvec, ncol=nmax, nrow=length(rho), byrow=TRUE)
  rhomat <- matrix(rho, ncol=nmax, nrow=length(rho), byrow=FALSE)
  xi <- sqrt(rho * pi/2) * BesselH(1, rho+0i, 1/2, expon.scaled = FALSE, nSeq = nmax+1)
  xip <- xi[ , nvec] - nmat * xi[ , nvec + 1] / rhomat
  
  list(xi = xi[ , -1], xip = xip)

  
}
##' Generalised susceptibility for the Mie theory
##'
##' Corresponds to the usual coefficients a_n, b_n, c_n, d_n
##' @title susceptibility
##' @param nmax integer, maximum order
##' @param s complex vector, relative refractive index
##' @param x real vector, size parameter
##' @return list with Gamma, Delta, A, B
##' @author Baptiste Auguie
##' @export
susceptibility <- function(nmax, s, x){

  z <- s * x
  
  RBx <- c(psi(x, nmax), xi(x, nmax))
  RBz <- psi(z, nmax)
  
  smat <- matrix(s, ncol=nmax, nrow=length(x), byrow=FALSE)

  PP1 <- RBz$psi * RBx$psip
  PP2 <- RBx$psi * RBz$psip
  PP3 <- RBz$psi * RBx$xip
  PP4 <- RBx$xi  * RBz$psip
    
  G_numerator   <-  - PP1 + smat * PP2
  D_numerator   <-    PP2 - smat * PP1
  B_denominator <-  - PP4 + smat * PP3
  A_denominator <-    PP3 - smat * PP4


list(G = G_numerator / A_denominator,
     D = D_numerator / B_denominator,
     A = 1i * smat   / A_denominator,
     B = 1i * smat   / B_denominator)
     
}

##' Efficiencies
##'
##' Calculates the far-field efficiencies for plane-wave illumination
##' @title efficiencies
##' @param x real vector, size parameter
##' @param GD list with Gamma, Delta, A, B
##' @return matrix of Qext, Qsca, Qabs
##' @author Baptiste Auguie
##' @export
efficiencies <- function(x, GD){

  nmax <- ncol(GD$G)
  nvec <- seq.int(nmax)
  nvec2 <- 2 * nvec + 1
  
  G2 <- Mod(GD$G)^2
  D2 <- Mod(GD$D)^2
  scatmat <- G2 + D2

  GR <- Re(GD$G)
  DR <- Re(GD$D)

  Qsca <- 2 / x^2 * scatmat %*% nvec2
  Qext <- - 2 / x^2 *  (GR + DR) %*% nvec2
  Qabs <- Qext - Qsca

  cbind(Qext = Qext, Qsca = Qsca, Qabs = Qabs)
}

##' Far-field cross-sections
##'
##' Homogeneous sphere illuminated by a plane wave
##' @title mie
##' @param wavelength real vector
##' @param epsilon complex vector
##' @param radius scalar
##' @param medium scalar, refractive index of surrounding medium
##' @param nmax truncation order
##' @param efficiency logical, scale by geometrical cross-sections
##' @return data.frame
##' @author Baptiste Auguie
##' @family user
##' @export
##' @examples 
##' gold <- epsAu(seq(400, 800))
##' cross_sections <- with(gold, mie(wavelength, epsilon, radius=0.05, medium=1.33, efficiency=FALSE))
##' matplot(cross_sections$wavelength, cross_sections[, -1], type="l", lty=1,
##'         xlab=expression(lambda/mu*m), ylab=expression(sigma/mu*m^2))
##' legend("topright", names(cross_sections)[-1], col=1:3, lty=1)
mie <- function(wavelength, epsilon, radius, medium = 1.0,
                nmax=ceiling(2 + max(x) + 4 * max(x)^(1/3)),
                efficiency = TRUE){

  s <- sqrt(epsilon) / medium
  x <- 2 * pi / wavelength * medium * radius
  
  ## lazy evaluation rules.. default nmax evaluated now
  coeffs <- susceptibility(nmax, s, x)
  Q <- efficiencies(x, coeffs)
  if(!efficiency) Q <- Q * (pi*radius^2)
  results <- data.frame(wavelength, Q)
  names(results) <- c("wavelength", "extinction", "scattering", "absorption")
  invisible(results)
}
