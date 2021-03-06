############################################################################
# Plotting.
############################################################################

#' A plain ggplot2 theme.
#'
#' @param base_size base font size
#' @param base_family base font family
ThemePlain <- function(base_size=15, base_family='') {
    got_req <- require(ggplot2)
    if (!got_req) {
        stop('ggplot2 must be installed to use ThemePlain.')
    }
    # Starts with theme_bw and then modify some parts
    ggplot2::theme_grey(base_size=base_size, base_family=base_family) %+replace%
            ggplot2::theme(
                    panel.background=ggplot2::element_blank(),
                    panel.grid.major=ggplot2::element_line(colour='grey90', size=ggplot2::rel(0.2)),
                    panel.grid.minor=ggplot2::element_line(colour='grey95', size=ggplot2::rel(0.5)),
                    axis.text.x=ggplot2::element_text(lineheight=0.9, vjust=0.5, angle=-90,
                            hjust=0),
                    axis.ticks=ggplot2::element_line(size=ggplot2::rel(0.2), colour='grey90'),
                    legend.key=ggplot2::element_blank(),
                    legend.position='bottom',
                    legend.key.height=grid::unit(0, "inches"),
                    legend.margin=grid::unit(0, "inches"),
                    plot.margin=grid::unit(c(0.01,0.01,0,0), "inches")
            )
}
