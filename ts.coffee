###
ts.coffee - version 0.9.0

Copyright 2012 Dan Simpson, Mike Countis

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

  # Create a NumericTimeseries object, capable basic plotting, etc
  numeric: (data) ->
    @validate(data)
    if typeof(data[0][1]) != "number"
      throw "NumericTimeseries expects timestamps and numbers; eg: [[timestamp, number]...]"
    new NumericTimeseries(data)

  # create a MultiTimeseries object with the data
  multi: (data) ->
    @validate(data)
    new MultiTimeseries(data)

  # Guess what kind of data we are working with
  build: (data) ->
    @validate(data)
    if typeof(data[0][1]) == "number"
      @numeric(data)
    else if typeof(data[0][1]) == "string"
      @wrap(data)
    else
      @multi(data)

###
#
#
###
class Timeseries
  constructor: (@data) ->

  # the number of samples
  size: () -> 
    @data.length

  # the number of samples
  length: () ->
    @data.length

  # the number of samples
  count: () -> 
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

  # append another timerseries item
  append: (t, v) ->
    @data.push [t, v]

  # values as 1d array
  values: () ->
    r = []
    for [t, v] in @data
      r.push v
    r

  # scan timeseries and get the range of events between
  # time nearest values of t1 and time t2
  scan: (t1, t2) ->
    idx1 = @nearest(t1)
    idx2 = @nearest(t2)
    if idx1 == @size() - 1
      idx1++
    if idx2 == @size() - 1
      idx2++
    new @constructor(@data.slice(idx1, idx2))

  # filter out items and return new
  # timeseries
  filter: (fn) ->
    r = []
    for tv in @data
      if fn(tv[0], tv[1])
        r.push tv
    new @constructor(r)

  map: (fn) ->
    r = []
    for tv in @data
      r.push fn(tv[0], tv[1])
    new @constructor(r)

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
      distance = @_distance(query, source[i..(i + query.length)])

      if distance < best
        best = distance
        idx = i
      
    idx
      
  # Euclidean distance function for one timeseries on another
  # used for pattern searching
  _distance: (ts1, ts2) ->
    sum = 0.0
    idx = 0
    for v in ts1
      sum += (ts2[idx] - v) * (ts2[idx] - v)
      idx++
    sum

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
MultiTimeseries class

A wrapper of many timeseries which share a timeline.

The underlying structure ends up being a simple spanning tree, which you can
query by path or name.

Example... one of your data values looks like this:
data = [timestamp, {
  dan: {
    drinks: 2,
    calories: 160
  },
  mike: {
    drinks: 1,
    calories: -1
  }
}, ...]

var tree = $ts.multi(data)
tree.series("dan/drinks").max(); // -> 2
tree.series("dan/calories").max(); // -> 160
tree.series("mike/drinks").max(); // -> 1
tree.series("mike/calories").max(); // -> -1

tree.series("dan") -> MultiTimeseries

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
      if typeof(@lookup[key][0][1]) == "number"
        @lookup[key] = $ts.numeric(@lookup[key])
      else
        @lookup[key] = $ts.multi(@lookup[key])

  # find a series by name or path
  # eg: mts.series("hits")
  # eg: mts.series("hostname.com/hits")
  series: (name) ->
    if name.indexOf("/") > -1
      parts = name.split("/")
      if parts[0] == ""
        parts.shift()

      head = parts.shift()
      unless @lookup[head]
        throw "Can't get attribute #{name} of multi time series"
      return @lookup[head].series(parts.join("/"))


    # base case...
    unless @lookup[name]
      throw "Can't get attribute #{name} of multi time series"
    @lookup[name]

  attr: (name) ->
    @series(name)


# expose the factory
root.$ts = new TimeseriesFactory()
