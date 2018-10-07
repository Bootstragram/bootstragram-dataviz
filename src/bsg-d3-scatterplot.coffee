class Bootstragram.Scatterplot extends Bootstragram.D3Common

  constructor: (@csvURL, opts) ->
    super(opts)

    @verbose = true

    # false is the only possible option otherwise it evaluates as (false or true) => ie always true
    @showRegressionLine = opts.showRegressionLine or false

    # TODO: what is is?
    # Answer: it's in case two dots are in the same location
    @dataFilteredTooltip = opts.dataFilteredTooltip or false

    # Choose dots, regression line dimensions
    @dotRadius = 6
    @regLineStrokeWidth = 2

    this

  _regLine: (slope, intercept, x) ->
    slope * x + intercept

  _regLineInverse: (slope, intercept, y) ->
    (1 / slope) * (y - intercept)

  draw: (callback = null) ->
    this._initSVG()

    self = this

    # Load data, rest is wrapped in
    # TODO: error management
    d3.csv(@csvURL).then (dataset) ->
      # Change xVar, yVar to num
      dataset.forEach (d) ->
        d[self.xVar] = +d[self.xVar]
        d[self.yVar] = +d[self.yVar]

      # Set up x y variables
      xData = dataset.map (d) ->
        d[self.xVar]
      yData = dataset.map (d) ->
        d[self.yVar]

      # Copy for later use
      yDataOriginal = yData

      # Compute domains with extra room, making sure 0 is always included
      xLength = d3.max(xData) - Math.min(0, d3.min(xData))
      yLength = d3.max(yData) - Math.min(0, d3.min(yData))

      xMin = Math.min(0, d3.min(xData) - self.innerPadding.left * xLength)
      xMax = Math.max(0, d3.max(xData) + self.innerPadding.right * xLength)

      yMin = Math.min(0, d3.min(yData) - self.innerPadding.bottom * yLength)
      yMax = Math.max(0, d3.max(yData) + self.innerPadding.top * yLength)

      # Set scales domains according to min max dimensions
      self.xScale.domain([xMin, xMax])
      self.yScale.domain([yMin, yMax])

      self._drawGrid()
      self._drawAxis()

      # Add axes names attached to svg
      # TODO: too much fudging with paddings?

      self.svg.append("text")
        .attr("class", "bsg-d3__axis-name bsg-d3__axis-name--x")
        .attr("id", "x-axis-name")
        .attr("x", (self.svgWidth - self.padding.left - self.padding.right) / 2 + self.padding.left)
        .attr("y", (self.svgHeight))
        .attr("dy", "-0.75em") # adapts distance to bottom in term of font size
        .text(self.xAxisName)

      self.svg.append("text")
        .attr("class", "bsg-d3__axis-name bsg-d3__axis-name--y")
        .attr("id", "y-axis-name")
        .attr("x", 0 - (self.svgHeight - self.padding.top - self.padding.bottom) / 2 - self.padding.top)
        .attr("y", 0)
        .attr("dy", "1.25em") # adapts distance to left in term of font size
        .text(self.yAxisName)

      # Create scatter points, attached to graph
      scatterPoints = self.graph.selectAll("circle")
        .data(xData)
        .enter()
        .append("circle")
        .attr("class", "bsg-d3__scatter-point")
        .attr("cx", (d) ->
          self.xScale(d)
        )
        .attr("cy", (d, i) ->
          self.yScale(yData[i])
        )
        .attr("r", self.dotRadius)

      # Add tooltip on mouseover and change stroke of selected point
      scatterPoints.on("mouseover", (d, i) ->
        # Create tooltip
        d3.select(this).attr("class", "bsg-d3__scatter-point bsg-d3__scatter-point--highlighted")
        self.tooltip.transition()
          .duration(self.tooltipTransitionOn)
          .style("opacity", self.tooltipOpacity)

        # Filter data for overlapping points
        dataFiltered = dataset.filter((d) ->
          d[self.xVar] == dataset[i][self.xVar] and d[self.yVar] == dataset[i][self.yVar]
        )

        # Create tooltip html
        tooltipHtml = "<span>" + self.xAlias + " = " + xData[i] + ", " + self.yAlias + " = " + yData[i]

        if self.dataFilteredTooltip
          dataFiltered.map((d,i) ->
            tooltipHtml = tooltipHtml + "<br/>" + " " + "Average rating diff. = " + dataFiltered[i]["Mean"] + "</span>"
          )

        # Fill and position tooltip, separate case when too close to right side #(instead could check for 'collision'?)
        if d3.event.pageX < self.svgWidth - self.tooltipInbound
          self.tooltip.html(tooltipHtml)
            .style("left", (d3.event.pageX + self.xTooltipShift) + "px")
            .style("top", (d3.event.pageY + self.yTooltipShift) + "px")
        else
          self.tooltip.html(tooltipHtml)
            .style("left", (d3.event.pageX + self.xTooltipShiftAlt) + "px")
            .style("top", (d3.event.pageY + self.yTooltipShiftAlt) + "px")
      )

      # Remove tooltip on mouseout
      scatterPoints.on("mouseout", (d) ->
        d3.select(this).attr("class", "bsg-d3__scatter-point")
        self.tooltip.transition()
          .duration(self.tooltipTransitionOff)
          .style("opacity", 0)
      )

      if self.showRegressionLine
        # Compute regression line data
        lr = self._linearRegression(yData, xData)
        regLineSlope = +lr["slope"]
        regLineIntercept = +lr["intercept"]

        # Create regression line, attached to graph
        # Compute x-coord intersection with graph area TODO: other method?
        xIntMin = 0
        xIntMax = 0
        if regLineSlope < 0
          xIntMin = Math.max(xMin, self._regLineInverse(regLineSlope, regLineIntercept, yMax))
          xIntMax = Math.min(xMax, self._regLineInverse(regLineSlope, regLineIntercept, yMin))
        else
          xIntMin = Math.max(xMin, self._regLineInverse(regLineSlope, regLineIntercept, yMin))
          xIntMax = Math.min(xMax, self._regLineInverse(regLineSlope, regLineIntercept, yMax))

        self.graph.append("line")
          .attr("id", "reg-line")
          .attr("x1", self.xScale(xIntMin))
          .attr("y1", self.yScale(self._regLine(regLineSlope, regLineIntercept, xIntMin)))
          .attr("x2", self.xScale(xIntMax))
          .attr("y2", self.yScale(self._regLine(regLineSlope, regLineIntercept, xIntMax)))
          .attr("class", "bsg-d3__line bsg-d3__line--regression")
          .attr("stroke-width", self.regLineStrokeWidth)

        # Add line equation
        equationLatex = $('<p class="math" id="static-equation">' + '$$' + 'P=' + regLineSlope.toFixed(2) + '\\times GD+' + regLineIntercept.toFixed(2) + '$$' + '</p>')
        $("#static-equation-container").append(equationLatex)
        if MathJax?
          MathJax.Hub.Typeset("static-equation")
        else
          console.warn 'MathJax is not available here'

      if callback?
        console.debug 'Calling callback' if self.verbose
        callback()

    .catch (error) ->
      console.log error

    this

  # Linear regression function, returns "slope", "intercept", "r2"
  _linearRegression: (y, x) ->
    lr = {}
    n = y.length
    sum_x = 0
    sum_y = 0
    sum_xy = 0
    sum_xx = 0
    sum_yy = 0

    i = 0
    while i < y.length
      sum_x += x[i]
      sum_y += y[i]
      sum_xy += x[i] * y[i]
      sum_xx += x[i] * x[i]
      sum_yy += y[i] * y[i]
      i++

    lr['slope'] = (n * sum_xy - sum_x * sum_y) / (n * sum_xx - sum_x * sum_x)
    lr['intercept'] = (sum_y - lr.slope * sum_x) / n
    lr['r2'] = Math.pow( (n * sum_xy - sum_x * sum_y) / Math.sqrt((n * sum_xx - sum_x * sum_x) * (n * sum_yy - sum_y * sum_y)), 2)
    lr


  # TODO: parametrize this better
  drawExtraCurveForDraws: () ->
    console.debug 'drawExtraCurveForDraws' if @verbose

    z1Var = []
    z2Var = []

    i = 0
    while i < 1370 # TODO! Why 1370? number of data points?
      z1Var.push(-720 + i)
      z2Var.push(400 * Math.pow(10, (-720 + i) / 200) / Math.pow((1 + Math.pow(10, (-720 + i) / 400)), 4))
      i++

    self = this
    @graph.selectAll("circle")
      .data(z1Var)
      .enter()
      .append("circle")
      .attr("class", "bsg-d3__scatter-point bsg-d3__scatter-point--lining")
      .attr("cx", (d) ->
        self.xScale(d)
      )
      .attr("cy", (d, i) ->
        self.yScale(z2Var[i])
      )
      .attr("r", 2)

    this
