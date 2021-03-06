#' Turn an \code{\link[spatstat]{envelope}} object into a curve_set object.
#'
#' @param env An \code{\link[spatstat]{envelope}} object. The envelope()
#'   functions must have been called with savefuns = TRUE.
#' @return A corresponding curve_set object.
#' @param ... Do not use. (For internal use only.)
#' @export
envelope_to_curve_set <- function(env, ...) {
    if (!inherits(env, 'envelope')) {
        stop('env is not an envelope object.')
    }

    r <- env[['r']]
    n_r <- length(r)
    if (n_r < 1L) {
        stop('env[["r"]] must exist.')
    }

    obs <- env[['obs']]
    if (length(obs) != n_r) {
        stop('env[["obs"]] and env[["r"]] must have the same length.')
    }

    simfuns_fv <- attr(env, 'simfuns', exact = TRUE)
    if (length(simfuns_fv) < 1L) {
        stop('env did not include the simulated curve set. envelope must ',
             'be run with savefuns = TRUE.')
    }
    simulation_df <- as.data.frame(simfuns_fv)
    simulation_df_names <- names(simulation_df)

    if (!('r' %in% simulation_df_names)) {
        stop('The env attribute simfuns did not include r.')
    }
    if (!identical(r, simulation_df[['r']])) {
        stop('env[["r"]] must be equal to ',
             'attributes(env)[["simfuns"]][["r"]].')
    }

    # Dimensions: r_idx, sim_idx.
    sim_m <- as.matrix(simulation_df[, !(simulation_df_names %in% 'r')])
    if (nrow(sim_m) != n_r) {
        stop('simulated curves must have the same length as r.')
    }

    theo <- env[['theo']]
    n_theo <- length(theo)
    # If theo exists it must be correct.
    if (n_theo > 0L && n_theo != n_r) {
        stop('env[["theo"]] and env[["r"]] must have the same length.')
    }

    res <- list(r = r, obs = obs, sim_m = sim_m)
    if (n_theo > 0L) {
        res[['theo']] <- theo
    }
    res[['is_residual']] <- FALSE

    res <- create_curve_set(res, ...)
    res
}

#' Check the content validity of a potential curve_set object.
#'
#' @param curve_set A curve_set object to be checked.
#' @param allow_Inf_values Logical, for internal use. Can be used to allow infinite or nonnumeric
#' values in an \code{\link[spatstat]{envelope}} object at the first place, if those are cropped
#' away (in \code{\link{crop_curves}}).
check_curve_set_content <- function(curve_set, allow_Inf_values = FALSE) {
    possible_names <- c('r', 'obs', 'sim_m', 'theo', 'is_residual')

    n <- length(curve_set)
    if (n < 1L) {
        stop('curve_set must have some elements.')
    }
    if (!is.list(curve_set)) {
        stop('curve_set must be a list.')
    }

    name_vec <- names(curve_set)
    if (length(name_vec) != n) {
        stop('Every element of curve_set must be named.')
    }
    if (!all(name_vec %in% possible_names)) {
        stop('curve_set should contain only elements with some of these ',
             ' names: ', paste(possible_names, collapse = ', '))
    }

    r <- curve_set[['r']]
    n_r <- length(r)
    if (n_r < 1L) {
        stop('curve_set[["r"]] must have at least one element.')
    }
    if (!is.vector(r)) {
        stop('curve_set[["r"]] must be a vector.')
    }
    if (!all(is.numeric(r)) || !all(is.finite(r))) {
        stop('curve_set[["r"]] must have only finite numeric values.')
    }

    obs <- curve_set[['obs']]
    if (length(obs) != n_r) {
        stop('curve_set[["obs"]] must have as many values as ',
             'curve_set[["r"]].')
    }
    if (!is.vector(obs)) {
        stop('curve_set[["obs"]] must be a vector.')
    }
    if (!(allow_Inf_values | ( all(is.numeric(obs)) && all(is.finite(obs)) ))) {
        stop('curve_set[["obs"]] must have only finite numeric values.')
    }

    sim_m <- curve_set[['sim_m']]
    dim_sim_m <- dim(sim_m)
    if (!is.matrix(sim_m)) {
        stop('curve_set[["sim_m"]] must be a matrix.')
    }
    if (dim_sim_m[1] != n_r) {
        stop('curve_set[["sim_m"]] must have as many rows as there are ',
             'elements in curve_set[["r"]].')
    }
    if (dim_sim_m[2] < 1L) {
        stop('curve_set[["sim_m"]] must have at least one column.')
    }
    if (!(allow_Inf_values | ( all(is.numeric(sim_m)) && all(is.finite(sim_m)) ))) {
        stop('curve_set[["sim_m"]] must have only finite numeric values.')
    }

    theo <- curve_set[['theo']]
    n_theo <- length(theo)
    if (n_theo > 0L) {
        if (n_theo != n_r) {
            stop('curve_set[["theo"]] must have as many values as ',
                 'curve_set[["r"]].')
        }
        if (!is.vector(theo)) {
            stop('curve_set[["theo"]] must be a vector.')
        }
        if (!(allow_Inf_values | ( all(is.numeric(theo)) && all(is.finite(theo)) ))) {
            stop('curve_set[["theo"]] must have only finite numeric ',
                 'values.')
        }
    }

    is_residual <- curve_set[['is_residual']]
    n_is_residual <- length(is_residual)
    if (n_is_residual > 0L && (n_is_residual != 1L ||
                               !is.logical(is_residual) ||
                               !is.finite(is_residual))) {
        stop('curve_set[["is_residual"]] must be either TRUE or FALSE.')
    }

    if (n_is_residual > 0L && is_residual && n_theo > 0L) {
        stop('A residual curve set must not contain a theoretical curve.')
    }

    curve_set
}

#' Convert an envelope object to a curve_set object.
#'
#' If given an envelope object, convert it into a curve_set object. If given
#' a curve_set object, check its correctness and give it back.
#'
#' @param curve_set A curve_set or an \code{\link[spatstat]{envelope}}
#'   object. If an envelope object is given, it must contain the summary
#'   functions from the simulated patterns which can be achieved by setting
#'   savefuns = TRUE when calling envelope().
#' @param ... Allows to pass arguments to \code{\link{check_curve_set_content}}
#' and \code{\link{envelope_to_curve_set}} (to be passed further through
#' \code{\link{create_curve_set}} to \code{\link{check_curve_set_content}}).
#' @return If an \code{\link[spatstat]{envelope}} object was given, return a
#'   corresponding curve_set object. If a curve_set object was given, return
#'   it unharmed.
convert_envelope <- function(curve_set, ...) {
    if (inherits(curve_set, 'envelope')) {
        curve_set <- envelope_to_curve_set(curve_set, ...)
    } else if (!is(curve_set, 'curve_set')) {
        stop('curve_set must either have class "envelope" (from spatstat) ',
             'or class "curve_set".')
    }
    check_curve_set_content(curve_set, ...)
    curve_set
}

#' Check that the curve_set object portrays residual curves.
#' @param curve_set A 'curve_set' object
check_residualness <- function(curve_set) {
    is_residual <- curve_set[['is_residual']]
    if (length(is_residual) < 1L || !is_residual) {
        stop('curve_set must consist of residual curves. Run function ',
             'residual first.')
    }
    invisible(curve_set)
}

#' Create a curve set out of a list in the right form.
#'
#' @param curve_set A list containing elements r, obs, sim_m and optionally
#'   the element theo. r must be a vector describing the radius vector. obs
#'   must be a vector containing the summary function values for the
#'   observed pattern. obs must have same length as r. sim_m must be a
#'   matrix containing summary function values for all the simulated
#'   patterns. Each column corresponds to a pattern. The number of rows must
#'   match the length of r. If included, theo corresponds to the theoretical
#'   summary function curve. If present, its length must match the length of
#'   r.
#' @param ... Do not use. (For internal use only.)
#' @return The given list adorned with the proper class name.
#' @export
create_curve_set <- function(curve_set, ...) {
    check_curve_set_content(curve_set, ...)
    class(curve_set) <- 'curve_set'
    curve_set
}

#' Check class.
#'
#' @param x An object to be checked.
#' @export
is.curve_set <- function(x) inherits(x, 'curve_set')


#' Print method for the class 'curve_set'
#' @usage \method{print}{curve_set}(x, ...)
#'
#' @param x an 'curve_set' object
#' @param ... Ignored.
#'
#' @method print curve_set
#' @export
print.curve_set <- function(x, ...) {
    cat("curve_set object containing :\n")
    str(x)
}

#' Plot method for the class 'curve_set'
#' @usage \method{plot}{curve_set}(x, ylim, ...)
#'
#' @param x an 'curve_set' object
#' @param ylim The y limits of the plot with the default being the minimum and maximum over all curves.
#' @param ... Additional parameters to be passed to plot and lines.
#'
#' @method plot curve_set
#' @export
plot.curve_set <- function(x, ylim, ...) {
    if(missing('ylim')) ylim <- with(x, c(min(obs,sim_m), max(obs,sim_m)))
    rdata <- curve_set_check_r(x)
    if(rdata$retick_xaxis) {
        rvalues <- rdata$new_r_values
    }
    else rvalues <- x$r
    nr <- length(rvalues)
    # Plot
    if(!rdata$retick_xaxis)
        plot(rvalues, x$obs, type="l", ylim=ylim, ...)
    else
        plot(rvalues, x$obs, type="l", ylim=ylim, xaxt="n", ...)
    for(i in 1:ncol(x$sim_m)) lines(rvalues, x$sim_m[,i], col=grey(0.7))
    lines(rvalues, x$obs, type="l", ...)
    if(rdata$retick_xaxis) {
        axis(1, rdata$loc_break_values, labels=paste(round(rdata$r_break_values, digits=2)))
        abline(v = (1:nr)[rdata$r_values_newstart_id], lty=3)
    }
}

#' Combine curve sets.
#'
#' Combine curve sets to a one curve set, e.g. for testing by means of several test functions.
#' @inheritParams check_curve_set_dimensions
#' @return A curve set that is a combination of the curve sets given in 'x'.
#' @export
combine_curve_sets <- function(x) {
    curve_set <- NULL
    # Check that x contains list of curve sets or \code{\link[spatstat]{envelope}} objects.
    # If the latter, then convert the objects to curve sets.
    x <- check_curve_set_dimensions(x)
    name_vec <- lapply(x, FUN=names)
    if('r' %in% name_vec[[1]])
        curve_set$r <- c(sapply(x, FUN=function(curve_set) { curve_set['r'] }), recursive=TRUE)
    if('obs' %in% name_vec[[1]])
        curve_set$obs <- c(sapply(x, FUN=function(curve_set) { curve_set['obs'] }), recursive=TRUE)
    if('sim_m' %in% name_vec[[1]]) {
        # check_curve_set_dimensions was used above to check that dimensions match
        # Combine
        curve_set$sim_m <- matrix(nrow=sum(sapply(x, FUN=function(curve_set) {dim(curve_set$sim_m)[1]})), ncol=dim(x[[1]]$sim_m)[2])
        for(i in 1:dim(x[[1]]$sim_m)[2]) {
            curve_set$sim_m[,i] <- c(sapply(x, FUN=function(curve_set) { curve_set$sim_m[,i] }), recursive=TRUE)
        }
    }
    if('theo' %in% name_vec[[1]])
        curve_set$theo <- c(sapply(x, FUN=function(curve_set) { curve_set['theo'] }), recursive=TRUE)
    # check_curve_set_dimensions has checked that 'is_residual' is the same for all curve sets.
    if('is_residual' %in% name_vec[[1]])
        curve_set$is_residual <- x[[1]]$is_residual

    create_curve_set(curve_set)
}

#' Check curve set dimensions
#' @param x A list of curve sets or \code{\link[spatstat]{envelope}} objects.
check_curve_set_dimensions <- function(x) {
    # Check that x contains list of curve sets or \code{\link[spatstat]{envelope}} objects.
    # If the latter, then convert the objects to curve sets.
    x <- lapply(x, FUN=convert_envelope)
    name_vec <- lapply(x, FUN=names)
    # Possible_names in curve_sets are 'r', 'obs', 'sim_m', 'theo' and 'is_residual'.
    # Check that all curve sets contain the same elements
    if(!all(sapply(name_vec, FUN=identical, y=name_vec[[1]])))
        stop("The curve sets in \'x\' contain different elements.\n")
    # Check that 'is_residual' is the same for all curve sets.
    if('is_residual' %in% name_vec[[1]]) {
        if(!all(sapply(x, FUN=function(curve_set) { curve_set$is_residual == x[[1]]$is_residual })))
            stop("The element \'is_residual\' should be the same for each curve set.\n")
    }
    # Check that the number of simulations in curve sets are equal.
    if('sim_m' %in% name_vec[[1]]) {
        if(!all(sapply(x, FUN=function(curve_set) { dim(curve_set$sim_m)[2] == dim(x[[1]]$sim_m)[2] })))
            stop("The numbers of simulations in curve sets differ.\n")
    }
    x
}
