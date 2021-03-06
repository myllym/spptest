% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/combined_envelope_tests.R
\name{combined_scaled_MAD_envelope}
\alias{combined_scaled_MAD_envelope}
\title{Combined global scaled maximum absolute difference (MAD) envelope tests}
\usage{
combined_scaled_MAD_envelope(curve_sets, test = c("qdir", "st"),
  alpha = 0.05, probs = c(0.025, 0.975), ...)
}
\arguments{
\item{curve_sets}{A list of objects of type \code{\link{curve_set}} or \code{\link[spatstat]{envelope}}.}

\item{test}{Either "qdir" for the \code{\link{qdir_envelope}} test or
"st" for the \code{\link{st_envelope}} test.}

\item{alpha}{The significance level. The 100(1-alpha)\% global envelope will be calculated.}

\item{probs}{A two-element vector containing the lower and upper
quantiles for the envelope, in that order and on the interval [0, 1].
The default values are 0.025 and 0.975.}

\item{...}{Additional parameters to be passed to \code{\link{qdir_envelope}} (if test = "qdir")
or \code{\link{st_envelope}} (if test = "st").}
}
\description{
Given a list of \code{\link{curve_set}} objects, a combined global scaled (directional quantile
or studentized) MAD envelope test is performed with the test functions saved in the curve set objects.
Details of the combined test can be found in Mrkvicka et al.
}
\references{
Mrkvicka, T., Myllymäki, M. and Hahn, U. Multiple Monte Carlo testing, with applications in spatial point processes.
Revision submitted to Statistics & Computing.
}

