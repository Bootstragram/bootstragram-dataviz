import D3Common from './bsg-d3-common'

class Histogram extends D3Common

  constructor: (@csvURL, opts) ->
    super(opts)

    @verbose = true

    @xScale = d3.scaleLinear().range([0, @graphWidth])
    @yScale = d3.scaleBand().rangeRound([0, @graphHeight], .1)

    @xAxis = d3.axisBottom(@xScale)
    @yAxis = d3.axisLeft(@yScale)

    # What column of the CSV file should be used
    @xColumn = @_localizedString(opts.xColumn, lang) ? 'xColumn'
    @yColumn = opts.yColumn or 'yColumn'

    @xScaleDomainPaddingLow = opts.xScaleDomainPaddingLow ? 100
    @xScaleDomainPaddingUp = opts.xScaleDomainPaddingUp ? 0

    @sortFunction = opts.sortFunction

    @histogramBarX = opts.histogramBarX
    @histogramBarWidth = opts.histogramBarWidth
    @barClass = opts.barClass
    @mouseOut = opts.mouseOut

    if @verbose
      console.debug 'opts:', opts

    this


  _type: (value) ->
    value


  _minValue: (data) ->
    self = this
    minValue = d3.min(data, (d) ->
      +self._yValue(d) # + is to do the String -> int conversion
    )
    minValue


  _maxValue: (data) ->
    self = this
    maxValue = d3.max(data, (d) ->
      +self._yValue(d) # + is to do the String -> int conversion
    )
    maxValue


  _setXScaleDomain: (data) ->
    minValue = this._minValue(data)
    maxValue = this._maxValue(data)

    console.debug 'Min value is: ' + minValue if @verbose
    console.debug 'Max value is: ' + maxValue if @verbose

    @xScale.domain([minValue - @xScaleDomainPaddingLow, maxValue + @xScaleDomainPaddingUp])


  _barClass: (data) =>
    if typeof @barClass is 'function'
      return @barClass(data)
    else
      # TODO: Fix this in the Women World Cup page
      if data[@xColumn] == "Canada" or data[@xColumn] == "Canada Home"
        "bsg-d3__bar bsg-d3__bar--highlighted"
      else
        "bsg-d3__bar"


  _mouseOut: (data, elt) =>
    if typeof @mouseOut is 'function'
      return @mouseOut(data, elt)
    else
      if data[@xColumn] == "Canada" or data[@xColumn] == "Canada Home"
        d3.select(elt).attr("class", "bsg-d3__bar bsg-d3__bar--highlighted")
      else
        d3.select(elt).attr("class", "bsg-d3__bar")


  _histogramBarX: (data) =>
    if typeof @histogramBarX is 'function'
      return @histogramBarX(data)
    else
      0 # By default, we start drawing the bar from the left side


  _histogramBarWidth: (data) =>
    if typeof @histogramBarWidth is 'function'
      return @histogramBarWidth(data)
    else
      @xScale(+this._yValue(data))


  _yValue: (data) ->
    if typeof @yColumn is 'function'
      return @yColumn(data)
    else
      return data[@yColumn]


  draw: (callback = null) ->
    this._initSVG()

    self = this

    # Load data, rest is wrapped in
    # TODO: error management
    d3.csv(@csvURL, this._type).then (dataset) ->
      # Sort if necessary
      if self.sortFunction?
        console.debug '[Bootstragram.Histogram] Sorting dataset' if @verbose
        dataset = dataset.sort(self.sortFunction)

      # Adjusting the X domain to (min of dataset, to max of dataset)
      self._setXScaleDomain(dataset)

      # The Y scale is ordinal, and corresponds to a country
      self.yScale.domain(dataset.map((d) ->
        d[self.xColumn]
      ))

      # Draw the X axis
      self.graph.append("g")
        .attr("class", "bsg-d3__axis bsg-d3__axis--x bsg-d3__axis--tiny bsg-d3__axis--nobar")
        .attr("transform", "translate(0, " + self.graphHeight + ")")
        .call(self.xAxis)

      # Draw the bars
      bars = self.graph.selectAll(".bar")
        .data(dataset)
        .enter()
        .append("rect")
        .attr("class", self._barClass)
        .attr("x", self._histogramBarX)
        .attr("y", (d) ->
          self.yScale(d[self.xColumn])
        )
        .attr("width", self._histogramBarWidth)
        .attr("height", self.yScale.bandwidth() - 1)

      # Draw the Y axis
      self.graph.append("g")
        .attr("class", "bsg-d3__axis bsg-d3__axis--y bsg-d3__axis--tiny")
        .call(self.yAxis)

      self.svg.append("text")
        .attr("class", "bsg-d3__axis-name bsg-d3__axis-name--x")
        .attr("id", "x-axis-name")
        .attr("x", (self.svgWidth - self.padding.left - self.padding.right) / 2 + self.padding.left)
        .attr("y", (self.svgHeight))
        .attr("dy", "-0.75em") # adapts distance to bottom in term of font size
        .text(self.xAxisName)

      # Tooltip Management

      # Add tooltip on mouseover and change stroke of selected point
      bars.on("mouseover", (d, i) ->
        console.debug "Data", d, i

        # Create tooltip
        d3.select(this).attr("class", "bsg-d3__bar bsg-d3__bar--highlighted")
        self.tooltip.transition()
          .duration(self.tooltipTransitionOn)
          .style("opacity", self.tooltipOpacity)

        # Create tooltip html
        tooltipHtml = "<span>" + d[self.xColumn] + ": " + self._yValue(d) + "</span>"

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
      bars.on("mouseout", (d) ->
        self._mouseOut(d, this)

        self.tooltip.transition()
          .duration(self.tooltipTransitionOff)
          .style("opacity", 0)
      )

      callback(self) if callback?
    .catch (error) ->
      console.log error


export default Histogram
