###*
Basic comment so that JSDoc recognizes this.
###
class Bootstragram.D3Common

  ###*
  # This is a description of the constructor
  # @class
  # @classdesc This is a description of the Bootstragram.D3Common class.
  # @memberof Bootstragram
  ###
  constructor: (opts) ->
    console.error "lang not set" unless lang?

    @verbose = false

    # Overridable variables
    @parentId = opts.parentId or 'defaultPlotID'

    ###*
    # The key for the X variable in the source data
    # @member {string}
    # @default 'x'
    ###
    @xVar = opts.csvHeaderForX or 'x'

    ###*
    # The key for the Y variable in the source data
    # @member {string}
    # @default 'y'
    ###
    @yVar = opts.csvHeaderForY or 'y'

    # Axes names
    @xAxisName = @_localizedString(opts.xLegend, lang) ? 'x'
    @yAxisName = @_localizedString(opts.yLegend, lang) ? 'y'
    # Alisases for tooltip
    @xAlias = opts.xLegendAlias or 'x'
    @yAlias = opts.yLegendAlias or 'y'

    @margin =
      top: (opts.margin and opts.margin.top) or 5
      right: (opts.margin and opts.margin.right) or 5
      bottom: (opts.margin and opts.margin.bottom) or 5
      left: (opts.margin and opts.margin.left) or 5
    @padding =
      top: (opts.padding and opts.padding.top) or 20
      right: (opts.padding and opts.padding.right) or 20
      bottom: (opts.padding and opts.padding.bottom) or 60
      left: (opts.padding and opts.padding.left) or 60
    @displayRatio = opts.displayRatio or 1.61803 # Golden number

    # Computed variables
    @parentSel = '#' + @parentId
    @plotId = "svg" + @parentId
    @plotSel = '#' + @plotId

    # Dimensions of the SVG
    @svgWidth = parseInt($(@parentSel).width()) - @margin.left - @margin.right
    if opts.forceGraphHeight
      @svgHeight = opts.forceGraphHeight + @padding.top + @padding.bottom
    else
      @svgHeight = parseInt(@svgWidth / @displayRatio) - @margin.top - @margin.bottom

    @graphWidth = @svgWidth - @padding.left - @padding.right
    @graphHeight = @svgHeight - @padding.top - @padding.bottom

    # Padding between points and edges of graph, as a proportion of domain
    #TODO: add to options?
    @innerPadding =
      top: 0.02
      right: 0.02
      bottom: 0.02
      left: 0.02

    # Padding between tick labels and axis, grid
    #TODO: add to options?
    @xPaddingLabels = 10
    @yPaddingLabels = 10

    # Shift tooltip from pointer in px, changed when near right border
    #TODO: add to options?
    @xTooltipShift = 16
    @yTooltipShift = 0

    # When pointer distance from right side less than tooltipInbound uses Alt
    #TODO: add to options?
    @tooltipInbound = 100

    @xTooltipShiftAlt = -50
    @yTooltipShiftAlt = 20

    # Tooltip opacity, time to transition on-off
    @tooltipOpacity = 0.9
    @tooltipTransitionOn = 500
    @tooltipTransitionOff = 200

    # Choose number of ticks on axes and their size
    # TODO: make ticks dynamic for smartphones
    @xTicks = 10
    @yTicks = 5

    @tickDimension = 5

    # Create svg translated by margin

    # Create tooltip, attached to div

    @tooltip = d3
      .select(@parentSel)
      .append("div")
      .attr("class", "bsg-d3__tooltip")
      .style("opacity", 0)

    # Define scales ranges using dimensions of graph
    @xScale = d3.scale.linear().range([0, @graphWidth])
    @yScale = d3.scale.linear().range([@graphHeight, 0])



    this


  ###*
  Draw a grid based on the values of @xScale / @yScale
  and @xTicks / @yTicks
  ###
  _drawGrid: () ->
    @xGrid = d3.svg.axis()
      .scale(@xScale)
      .orient("bottom")
      .ticks(@xTicks)
    @yGrid = d3.svg.axis()
      .scale(@yScale)
      .orient("left")
      .ticks(@yTicks)

    # Create grid and tick labels attached to graph
    @graph.append("g")
      .attr("class", "bsg-d3__grid bsg-d3__grid--x")
      .attr("id", "x-grid")
      .attr("transform", "translate(0," + @graphHeight + ")")
      .call(@xGrid.tickSize(- @graphHeight, 0, 0).tickPadding(@xPaddingLabels))

    @graph.append("g")
      .attr("class", "bsg-d3__grid bsg-d3__grid--y")
      .attr("id", "y-grid")
      .call(@yGrid.tickSize(- @graphWidth, 0, 0).tickPadding(@yPaddingLabels))


  _drawAxis: (yRefValueForXAxis = 0, xRefValueForYAxis = 0) ->
    # Define axes
    @xAxis = d3.svg.axis()
      .scale(@xScale)
      .orient("bottom")
      .ticks(@xTicks)
    @yAxis = d3.svg.axis()
      .scale(@yScale)
      .orient("left")
      .ticks(@yTicks)

    # Create axes, no tick labels attached to graph
    @graph.append("g")
      .attr("class", "bsg-d3__axis bsg-d3__axis-x")
      .attr("id", "x-axis")
      .attr("transform", "translate(0," + @yScale(yRefValueForXAxis) + ")")
      .call(@xAxis.tickSize(@tickDimension, 0, 0).tickFormat(""))

    @graph.append("g")
      .attr("class", "bsg-d3__axis bsg-d3__axis-y")
      .attr("id", "y-axis")
      .attr("transform", "translate(" + @xScale(xRefValueForYAxis) + ",0)")
      .call(@yAxis.tickSize(@tickDimension, 0, 0).tickFormat(""))



  _initSVG: () ->
    @svg = d3
      .select(@parentSel)
      .append("svg")
      .attr("id", @plotId)
      .attr("width", @svgWidth)
      .attr("height", @svgHeight)
      .append("g")
      .attr("transform", "translate(" + @margin.left + "," + @margin.top + ")")

    # Create background, attached to svg
    @svg.append("rect")
      .attr("width", @svgWidth)
      .attr("height", @svgHeight)
      .attr("class", "bsg-d3__background-rect")

    # Create graph group translated by padding
    @graph = @svg.append("g")
      .attr("transform", "translate(" + @padding.left + "," + @padding.top + ")")


  _localizedString: (opt, lang = 'en') ->
    return null unless opt?

    myString = "myString"
    myObject =
      fr: "monObjet"
      en: "myObject"
    if typeof opt == 'object' && lang?
      return opt[lang]
    if typeof opt == 'string'
      return opt
    console.error 'Invalid opt: ', opt, ', lang: ', lang
    return null
