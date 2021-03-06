#' Spatial point process testing
#'
#' The \pkg{spptest} library provides global envelope and deviation tests. Both type of tests are
#' Monte Carlo tests, which demand simulations from the tested null model. Examples are
#' mainly for spatial point processes, but the methods are applicable for any functional (or
#' multivariate vector) data. (In the case of point processes, the functions are typically
#' estimators of summary functions.) The main motivation for this package are the scalings
#' for deviation tests and global envelope tests.
#'
#'
#' The package supports the use of the R library \pkg{spatstat} for generating
#' simulations and calculating estimators of the chosen summary function, but alternatively these
#' can be done by any other methods, thus allowing for any models/functions.
#'
#' @section Typical workflow:
#' In the following, the use of the \pkg{spptest} library is demonstrated by its main function \code{\link{rank_envelope}},
#' but alternatively this step can be replaced by a call of another function for envelope or
#' deviation test (the main options are \code{\link{st_envelope}}, \code{\link{qdir_envelope}},
#' \code{\link{deviation_test}}).
#'
#'
#' 1) The workflow utilizing \pkg{spatstat}:
#'
#' E.g. Say we have a point pattern, for which we would like to test a hypothesis, as a \code{\link[spatstat]{ppp}} object.
#'
#' \code{X <- spruces # an example pattern from spatstat}
#'
#' \itemize{
#'    \item Test complete spatial randomness (CSR):
#'          \itemize{
#'            \item Use \code{\link[spatstat]{envelope}} to create nsim simulations
#'                  under CSR and to calculate the functions you want.
#'                  Important: use the option 'savefuns=TRUE' and
#'                  specify the number of simulations \code{nsim}.
#'                  See the help documentation in \code{\link[spatstat]{spatstat}}
#'                  for possible test functions (if \code{fun} not given, \code{Kest} is used,
#'                  i.e. an estimator of the K function).
#'
#'                  Making 2499 simulations of CSR (note the number of points is not fixed here)
#'                  and estimating K-function for each of them and data:
#'
#'                  \code{
#'                    env <- envelope(X, nsim=2499, savefuns=TRUE)
#'                  }
#'            \item Perform the test
#'
#'                  \code{
#'                    res <- rank_envelope(env)
#'                  }
#'            \item Plot the result
#'
#'                  \code{
#'                    plot(res)
#'                  }
#'          }
#'    \item A goodness-of-fit of a parametric model (composite hypothesis case)
#'          \itemize{
#'            \item Fit the model to your data by means of the function
#'                  \code{\link[spatstat]{ppm}} or \code{\link[spatstat]{kppm}}.
#'                  See the help documentation for possible models.
#'            \item Use \code{\link{dg.global_envelope}} to create nsim simulations
#'                  from the fitted model, to calculate the functions you want,
#'                  and to make an adjusted global envelope test (either rank,
#'                  directional quantile or studentized global envelope test).
#'                  See the detailed example in \code{\link{saplings}}.
#'            \item Plot the result
#'
#'                  \code{
#'                    plot(res)
#'                  }
#'          }
#'
#' }
#'
#' 2) The random labeling test with a mark-weighted K-function
#'\itemize{
#' \item Generate simulations (permuting marks) and estimate the chosen marked K_f-function for each pattern
#'       using the function \code{\link{random_labelling}} (requires R library \code{marksummary} available from
#'       \code{https://github.com/myllym/}).
#'
#'       \code{
#'       curve_set <- random_labelling(mpp, mtf_name = 'm', nsim=2499, r_min=1.5, r_max=9.5)
#'       }
#' \item Then do the test and plot the result
#'
#'       \code{
#'       res <- rank_envelope(curve_set); plot(res)
#'       }
#'}
#'
#'
#' 3) The workflow when using your own programs for simulations:
#'
#' \itemize{
#' \item (Fit the model and) Create nsim simulations from the (fitted) null model.
#' \item Calculate the functions T_1(r), T_2(r), ..., T_{nsim+1}(r).
#' \item Use \code{\link{create_curve_set}} to create a curve_set object
#'       from the functions T_i(r), i=1,...,s+1.
#' \item Perform the test and plot the result
#'
#'       \code{res <- rank_envelope(curve_set) # curve_set is the 'curve_set'-object you created}
#'
#'       \code{plot(res)}
#' \item Note that for calculating an adjusted global envelope test for a composite hypothesis test,
#' you need to write some of your own code as the function \code{\link{dg.global_envelope}}
#' allows just models that can be simulated and fitted using spatstat.
#' }
#'
#'
#' @section Summary:
#' Thus, to perform a test you always first need to obtain the test function T(r)
#' for your data (T_1(r)) and for each simulation (T_2(r), ..., T_{nsim+1}(r)) in one way or another.
#' Given the set of the functions T_i(r), i=1,...,nsim+1, you can perform a test
#' by one of the following functions provided in this library:
#'
#' Envelope tests:
#' \itemize{
#'   \item \code{\link{rank_envelope}}, the completely non-parametric rank envelope test
#'   \item \code{\link{st_envelope}}, the studentised envelope test, protected against unequal variance of T(r) for different distances r
#'   \item \code{\link{qdir_envelope}}, the directional quantile envelope test, protected against unequal variance and asymmetry of T(r) for different distances r
#'   \item \code{\link{normal_envelope}}, a parametric envelope test, which uses a normal approximation of T(r)
#' }
#' Deviation tests (no graphical interpretation):
#' \itemize{
#'   \item \code{\link{deviation_test}}
#' }
#' Note that the recommended minimum number of simulations for the rank
#' envelope test is nsim=2499, while, for the studentised and directional
#' quantile envelope tests and deviation tests, it is nsim=99 (or 999).
#' (For the normal test, see its documentation.)
#'
#' See, in particular, \code{\link{rank_envelope}} for further examples.
#'
#'
#' @section Further options and functions:
#' It is possible to modify the curve set T_1(r), T_2(r), ..., T_{nsim+1}(r) for the test.
#'
#' (i) You can choose the interval of distances [r_min, r_max] by \code{\link{crop_curves}}.
#'
#' (ii) For better visualisation, you can take T(r)-T_0(r) by \code{\link{residual}}.
#' Here T_0(r) is the expectation of T(r) under the null hypothesis.
#'
#' The function \code{\link{envelope_to_curve_set}} can be used to create a curve_set object
#' from the object returned by \code{\link[spatstat]{envelope}}. An \code{envelope} object can also
#' directly be given to the functions \code{\link{crop_curves}} and \code{\link{residual}}.
#'
#'
#' Further, as a further reminder, for composite hypotheses the library provides the function
#' \code{\link{dg.global_envelope}}. See a detailed example in \code{\link{saplings}}.
#'
#' @author
#' Mari Myllymäki (mari.j.myllymaki@@gmail.com, mari.myllymaki@@luke.fi),
#' Henri Seijo (henri.seijo@@aalto.fi, henri.seijo@@iki.fi),
#' Tomáš Mrkvička (mrkvicka.toma@@gmail.com),
#' Pavel Grabarnik (gpya@@rambler.ru),
#' Ute Hahn (ute@@math.au.dk)
#'
#' @references
#' Myllymäki, M., Grabarnik, P., Seijo, H. and Stoyan. D. (2015). Deviation test construction and power comparison for marked spatial point patterns. Spatial Statistics 11, 19-34. doi: 10.1016/j.spasta.2014.11.004
#'
#' Myllymäki, M., Mrkvička, T., Grabarnik, P., Seijo, H. and Hahn, U. (2016). Global envelope tests for spatial point patterns. Journal of the Royal Statistical Society: Series B (Statistical Methodology). doi: 10.1111/rssb.12172
#'
#' Mrkvička, T., Myllymäki, M. and Hahn, U. (2016). Multiple Monte Carlo testing, with applications in spatial point processes. Statistics & Computing, accepted. (Preprint: arXiv:1506.01646 [stat.ME])
#' @name spptest
#' @docType package
#' @aliases spptest-package spptest
NULL
