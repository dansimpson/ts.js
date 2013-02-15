###
ts.coffee - version 0.0.1

Copyright 2012 Dan Simpson

MIT License: http://opensource.org/licenses/MIT
###


class TimeseriesFactory

  constructor: () ->

  validate: (data) ->
    if data.length == 0
      throw "Timeseries expects an array of data."
    
    if data[0].length != 2
      throw "Timeseries expects input like [[timestamp, value]...]"

    if typeof(data[0][0]) != "number"
      throw "Timeseries expects timestamps; eg: [[timestamp, value]...]"

  # Convert a 1-dimensional array to a 2d arry with
  # timestamps and values
  # +data+ the array of objects to timestamp
  # +start+ the start time (defaults to now)
  # +step+ the number of milliseconds between each
  timestamp: (data, start=(new Date().getTime()), step=60000) ->
    i = 0
    r = []
    for v in data
      r.push [start + (i++ * step), v]
    r

  # Wrap 2d array of timeseries data in a Timeseries object
  wrap: (data) ->
    @validate(data)
    new Timeseries(data)

  # Create a numeric timeseries, capable basic plotting, etc
  numeric: (data) ->
    @validate(data)
    if typeof(data[0][1]) != "number"
      throw "NumericTimeseries expects timestamps and numbers; eg: [[timestamp, number]...]"
    new NumericTimeseries(data)

  multi: (data) ->
    @validate(data)
    new MultiTimeseries(data)

###
#
#
###
class Timeseries
  constructor: (@data) ->

  # the number of samples
  size: () -> 
    @data.length

  # the first sample
  first: () ->
    @data[0]

  # the last sample
  last: () ->
    @data[@size() - 1]

  # get the sample at index idx
  sample: (idx) ->
    @data[idx]

  # get the time at index idx
  time: (idx) ->
    @data[idx][0]

  # get the value at index idx
  value: (idx) ->
    @data[idx][1]

  # time domain (earliest, latest)
  domain: () ->
    [@first()[0], @last()[0]]

  # values as 1d array
  values: () ->
    r = []
    for [t, v] in @data
      r.push v
    r

  # filter out items and return new
  # timeseries
  filter: (fn) ->
    r = []
    for tv in @data
      if fn(tv[0], tv[1])
        r.push tv
    @clone()(r)

  map: (fn) ->
    r = []
    for tv in @data
      r.push fn(tv[0], tv[1])
    @clone()(r)


  # timestamps as 1d array
  timestamps: () ->
    r = []
    for [t, v] in @data
      r.push t
    r
 
  # finds the nearest index in the domain using
  # a binary search
  nearest: (timestamp) ->
    @bsearch(timestamp, 0, @size() - 1)

  # binary search for a timestamp with some fuzzy
  # matching if we don't get the exact idx
  bsearch: (timestamp, idx1, idx2) ->
    mid = Math.floor((idx2 - idx1) / 2.0) + idx1
    if idx1 == mid
      diff1 = Math.abs(@time(idx1) - timestamp)
      diff2 = Math.abs(@time(idx2) - timestamp)
      if diff2 > diff1 then idx1 else idx2
    else if timestamp < @time(mid)
      @bsearch timestamp, idx1, mid
    else if timestamp > @time(mid)
      @bsearch timestamp, mid, idx2
    else
      mid

  # report
  toString: () ->
    """
    Timeseries
    items   : #{@size()}
    domain  : #{@domain()}
    """

  type: () ->
    "ts"

  clone: () ->
    $ts.wrap

###
# NumbericTimeseries class
#
# A class for wrapping timed values
#
# data: a 2d array containing
# 
###
class NumericTimeseries extends Timeseries
  constructor: (@data) ->
    super(@data)

  statistics: () ->
    return @_stats if @_stats
    
    sum  = 0.0
    sum2 = 0.0
    min  = 999999999999
    max  = -min

    for [t, v] in @data
      sum  += v
      sum2 += v * v
      if v > max
        max = v
      if v < min
        min = v

    @_stats =
      sum : sum
      min : min
      max : max
      sum2: sum2

  # the sum of all values
  sum: () ->
    @statistics().sum

  # the sum of all squared values
  sumsq: () ->
    @statistics().sum2

  # variance of the values
  variance: () ->
    r = 0
    for [t, v] in @data
      n  = v - @mean()
      r += n * n
    r / (@size() - 1)

  # standard deviation of the values
  stddev: () ->
    Math.sqrt((@sumsq() / @size()) / (@mean() * @mean()))

  # mean of value
  mean: () ->
    @sum() / @size()

  # value range (min, max)
  range: () ->
    [@min(), @max()]

  # minimum of value
  min: () ->
    @statistics().min

  # maximum of values
  max: () ->
    @statistics().max

  # values as 1d array
  values: () ->
    r = []
    for [t, v] in @data
      r.push v
    r

  # normalized values as 1d array
  norms: () ->
    r = []
    for [t, v] in @data
      r.push((v - @mean()) / @stddev())
    r

  # simplifies the data set based on a percentage change
  # If the range is great, yet the standard deviation is low
  # then we will not reduce much
  # Todo: Douglas Peuker
  simplify: (threshold=0.1) ->
    
    last  = @first()
    range = (@max() - @min())

    r = [last]

    for tv in @data
      if ((Math.abs(tv[1] - last[1])) / range) > threshold
        if last[0] != r[r.length - 1][0]
          r.push last
        r.push tv
      last = tv

    if last[0] != r[r.length - 1][0]
      r.push last

    new Timeseries(r)

  # Find the best fit match for the pattern in the
  # time series.  The data is first normalized
  # Todo: UCR DTW
  match: (pattern) ->
    unless pattern instanceof Timeseries
      throw "Must match against a Timeseries object"

    # best fit
    best = 999999999
    idx  = -1

    query  = pattern.norms()
    source = @norms()

    unless query.length <= source.length
      throw "Query length exceeds source length"

    for i in [0..(source.length - query.length - 1)]
      distance = @distance(query, source[i..(i + query.length)])

      if distance < best
        best = distance
        idx = i
      
    idx
      
  # Euclidean distance function for one timeseries on another
  # used for pattern searching
  distance: (ts1, ts2) ->
    sum = 0.0
    idx = 0
    for v in ts1
      sum += (ts2[idx] - v) * (ts2[idx] - v)
      idx++
    sum

  type: () ->
    "numeric"

  clone: () ->
    $ts.numeric

  plot: (opts) ->
    merge(opts, { ts: @ })
    new Chart(opts);

  # report
  toString: () ->
    """
    Timeseries
    items   : #{@size()}
    mean    : #{@mean()}
    stddev  : #{@stddev()}
    domain  : #{@domain()}
    range   : #{@range()}
    variance: #{@variance()}
    """

###
# Multimeseries class
#
# A mutli-valued timeseries class which wraps
# multiple Timeseries objects and provides the same
# functionality
# 
###
class MultiTimeseries extends Timeseries
  constructor: (@data) ->
    super(@data)

    # At this point we should have a time series
    # with standard object values (key, value).
    # Take those values and split them into singular ts
    @lookup = {}
    @attrs = []
    for key, value of data[0][1]
      @attrs.push(key)
      @lookup[key] = []

    # add items to each sub array
    for point in data
      for key, value of point[1]
        @lookup[key].push([point[0], value])
    
    # Conver array to actual ts, nested if need be
    for key, value of @lookup
      @lookup[key] = $ts.numeric(@lookup[key])

  # Find a series by path
  path: (series) ->
    parts = series.split("/")
    first = @series(parts.shift())

    if first
      if first.type() == "multi"
        first.path(parts.join("/"))
      else
        first
    else
      null

  series: (series) ->
    unless @lookup[series]
      throw "Can't get attribute #{series} of multi time series"
    @lookup[series]

  dispatch: (method, series, args) ->
    # console.log "dispatching:", method, attr, args
    if series
      @series(series)[method](args)
    else
      res = {}
      for attr in @attrs
        res[attr] = @series(attr)[method](args)
      res

  # the sum of all values
  sum: (series) ->
    @dispatch("sum", series)

  # the sum of all squared values
  sumsq: (series) ->
    @dispatch("sumsq", series)

  # variance of the values
  variance: (series) ->
    @dispatch("variance", series)

  # standard deviation of the values
  stddev: (series) ->
    @dispatch("stddev", series)

  # mean of value
  mean: (series) ->
    @dispatch("mean", series)

  # value range (min, max)
  range: (series) ->
    @dispatch("range", series)

  # minimum of value
  min: (series) ->
    @dispatch("min", series)

  # maximum of values
  max: (series) ->
    @dispatch("max", series)

  # values as 1d array
  values: (series) ->
    @dispatch("values", series)

  # normalized values as 1d array
  norms: (series) ->
    @dispatch("norms", series)

  type: () ->
    "multi"

  clone: () ->
    $ts.multi

  plot: () ->
    console.error "Plot not implemented"


# Factory function
root.$ts = new TimeseriesFactory()
