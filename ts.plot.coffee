
class SeriesRenderer

  defaults:
    color: "#ff0000"

  constructor: (opts) ->

  # Assume scale
  render: (ts, graph) ->
    graph.save()
    graph.beginPath()
    graph.strokeStyle = "#ff0000"

    # let's try to translate and scale
    # graph.scale(0.000001, 5)
    # graph.translate(-ts.data[0][0], 2)
    # graph.translate(100, 2)

    # console.log ts.data[0]

    # graph.moveTo scale.x(ts.data[0][0]), scale.y(ts.data[0][1])
    # for point in ts.data
    #   graph.lineTo scale.x(point[0]), scale.y(point[1])

    graph.moveTo ts.data[0][0], ts.data[0][1]
    for point in ts.data
      graph.lineTo point[0], point[1]

    graph.stroke()
    graph.closePath()
    graph.restore()

class LineRenderer

  defaults:
    color: "#ff0000"

  constructor: (opts) ->

  # Assume scale
  render: (ts, graph, scale) ->
    graph.save()
    graph.beginPath()
    graph.strokeStyle = "#ff0000"

    graph.moveTo scale.x(ts.data[0][0]), scale.y(ts.data[0][1])
    for point in ts.data
      graph.lineTo scale.x(point[0]), scale.y(point[1])

    graph.stroke()
    graph.closePath()
    graph.restore()

renderLine = (ts, graph, scale, opts) ->
  graph.save()
  graph.beginPath()
  graph.strokeStyle = "#ff0000"



  # let's try to translate and scale
  graph.scale(0.000001, 5)
  graph.translate(-ts.data[0][0], 2)
  # graph.translate(100, 2)

  console.log ts.data[0]

  # graph.moveTo scale.x(ts.data[0][0]), scale.y(ts.data[0][1])
  # for point in ts.data
  #   graph.lineTo scale.x(point[0]), scale.y(point[1])

  graph.moveTo ts.data[0][0], ts.data[0][1]
  for point in ts.data
    graph.lineTo point[0], point[1]

  graph.stroke()
  graph.closePath()
  graph.restore()

renderArea = (ts, graph, scale, opts) ->

  yval = if chart.get("fill", "bot") == "top" then 0 else chart.height()

  graph.save()
  graph.beginPath()
  graph.fillStyle = chart.get("color")

  graph.moveTo 0, yval
  for point in data
    graph.lineTo scale.x(point[0]), scale.y(point[1])
  graph.lineTo chart.width(), yval
  
  graph.fill()
  graph.closePath()
  graph.restore()

###
#
# Structure
#
###
###
Component

Events (hooks)

visit = (chart, x, y) ->
  # when the mouse be moving

###

class Component

  defaults:
    name: "component"

  constructor: (opts) ->
    console.log "s", opts
    merge @, @defaults, opts
    console.log "s", @
    @el = $(@el)
    @el.height(@height() || 100)




###
Canvas

Base class for all canvas renderables

Events (hooks)

prerender = (chart) ->
  # called before render of canvas

render = (chart) ->
  # called during render (non cached)

postrender = (chart) ->
  # called after render

select = (chart, x, y, idx, point) ->
  # when an item is selected

----------------
###
class Chart

  defaults:
    name: "component",
    renderers: [new SeriesRenderer(), new LineRenderer()]

  constructor: (opts) ->
    merge @, @defaults, opts
    @el = $(@el)
    # @el.height(@height() || 100)
    @build()
    console.log @

  build: () ->
    unless @context
      @canvas = document.createElement("canvas")
      @el.append(@canvas)
      if window.G_vmlCanvasManager
        @canvas = G_vmlCanvasManager.initElement(@canvas)
      @context = @canvas.getContext("2d")
      @resize()

  invalidate: () ->
    @_cache = @_scale = null

  resize: () ->
    @invalidate()
    @canvas.setAttribute "width" , @width()
    @canvas.setAttribute "height", @height()
    @render()

  render: () ->
    @context.clearRect(0, 0, @width(), @height())

    if @_cache
      @context.putImageData(@_cache, 0, 0)
    else

    
      ys = @height() / (@ts.max() - @ts.min())
      xs = @width()  / (@ts.last()[0] - @ts.first()[0])

      @context.save()

      # @context.lineWidth = 1 / Math.abs((xs + ys) / 2.0)
      @context.scale(xs, -ys)
      
      @context.translate(-@ts.data[0][0], -@ts.max() + 2)
      @context.lineWidth = 0.1
      # @context.rotate(0.01)
      # for renderer in @renderers
      #   renderer.render(@ts, @context, @scale())
      # for x in [1..100]
      new SeriesRenderer().render(@ts, @context, @scale())
      @context.restore()

      # for renderer in @renderers
      #   renderer.render(@ts, @context, @scale())

      # for x in [1..100]
      # new LineRenderer().render(@ts, @context, @scale())

      # Store the cache
      if @context.getImageData
        @_cache = @context.getImageData(0, 0, @width(), @height())


  width: () ->
    @el.width()

  height: () ->
    @el.height()

  visit: (x, y) ->
    #

  xscale: () ->
    [x1,x2] = @ts.domain()
    w = @width()
    (time) -> 
      ((time - x1) / (x2 - x1)) * w

  yscale: () ->
    [y1, y2] = @ts.range()
    h = @height()
    (v) -> 
      h - ((v - y1) / (y2 - y1)) * h

  scale: () ->
    unless @_scale
      w = @width()
      h = @height()
      xdomain = @ts.domain()
      ydomain = @ts.range()
      @_scale = 
        x: @xscale()
        y: @yscale()
        rx: (v) ->
          (v / w) * (xdomain[1] - xdomain[0]) + xdomain[0]

    @_scale





###

TimedChart

Base class for time series metrics.  Same as canvas
except it supports scales.

###
class VisualSeries extends Chart

  defaults: {
    something: true
  }

  constructor: (opts) ->
    super(opts)

    if @get("labels")
      @hook "select", (chart, x, y, idx, point) => @focus(idx)

  build: () ->
    unless @context
      super()
      if @get("labels")
        @value = $("<label />").addClass("value")
        @labelEl = $("<div />").addClass("labels")
        @labelEl.append $("<label />").addClass("name").html(@get("name"))
        @labelEl.append @value
        @el().append @labelEl
      if @get("labelRange", false)
        range = @ydomain()
        @el().append $("<label />").addClass("range low").html(range[0].toFixed(1))
        @el().append $("<label />").addClass("range high").html(range[1].toFixed(1))

  # fetch of build a scale for the graph
  scale: () ->
    unless @_scale
      w = @width()
      h = @height()
      xdomain = @xdomain()
      ydomain = @ydomain()
      @_scale = 
        x: (v) ->
          ((v - xdomain[0]) / (xdomain[1] - xdomain[0])) * w
        y: (v) ->
          h - ((v - ydomain[0]) / (ydomain[1] - ydomain[0])) * h
        rx: (v) ->
          (v / w) * (xdomain[1] - xdomain[0]) + xdomain[0]

    @_scale

  zoom: (x1, x2) ->
    @zrange = [@scale().rx(x1), @scale().rx(x2)]
    @invalidate()
    @render()

  unzoom: () ->
    @zrange = null
    @invalidate()
    @render()

  ydomain: () ->
    r  = Util.range @get("data"), (p) -> p[1]
    r2 = @get("yrange")
    if r2  
      r = [Math.min(r2[0], r[0]), Math.max(r2[1], r[1])]
    r

  xdomain: () ->
    if @zrange
      @zrange
    else if @get("timeframe")
      @get("timeframe")
    else
      Util.range @get("data"), (p) -> p[0]

  visit: (x, y) ->
    super(x, y)

    # TODO: improve
    if @gethooks("select").length > 0
      # idx = @get("ts").nearest @scale().rx(x)
      idx = Util.nearestIndex @get("data"), @scale().rx(x)
      for fn in @gethooks("select")
        fn(@, x, y, idx, @get("data")[idx])

  focus: (idx) ->
    if @value
      @value.html(@format(@get("data")[idx]))

  format: (point) ->
    if @get("format")
      @get("format")(point)
    else
      point[1].toFixed(1)


###
#
# Helpers
#
###

plotRegistry =

  plugins: {}
  renderers: {}

  register: (type, name, object) ->
    switch(type)
      when "plugin"
        this.plugins[name] = object
      when "renderer"
        this.renderers[name] = object
      else
        throw "Unable to register unknown type #{type}"

  lookup: (type, name) ->
    switch(type)
      when "plugin"
        this.plugins[name]
      when "renderer"
        this.renderers[name]
      else
        null

# Line renderer
plotRegistry.register "renderer", "line", (canvas) ->
  data  = canvas.ts
  scale = canvas.scale
  graph = canvas.context

  graph.save()
  graph.beginPath()
  graph.strokeStyle = canvas.get("color")

  graph.moveTo scale.x(data[0][0]), scale.y(data[0][1])
  for point in data
    graph.lineTo scale.x(point[0]), scale.y(point[1])

  graph.stroke()
  graph.closePath()
  graph.restore()

