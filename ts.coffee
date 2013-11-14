###
ts.js - version 0.9.0

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

  buffer: (data=[]) ->
    new Buffer(data)

factory = new TimeseriesFactory()


# Small buffer class used for limiting the rate of appending
class Buffer
  constructor: (@data=[]) ->

  append: (data) ->
    unless data instanceof Array
      throw "Buffer.append expects array: [t,v] or [[t,v],[t,v]]"
    
    if data[0] instanceof Array
      @data = @data.concat(data)
    else
      @data.push data

  shift: (count) ->
    result = @data.slice(0, count)
    @data  = @data.slice(count, @size())
    result

  size: () ->
    @data.length

###
#
#
###
class Timeseries
  constructor: (@data) ->
    @squelched = false
    @listeners = []

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

  # shift the first item off the list and update stats
  shift: () ->
    shift = @data.shift()
    @notify()
    shift

  # see shift
  pop: () ->
    @shift()

  # append another timerseries item
  append: (t, v) ->
    if t < @end()
      throw "Can't append sample with past timestamp"
    @data.push [t, v]
    @notify()

  # see append
  push: (t, v) ->
    @append(t, v)

  # see append
  add: (t, v) ->
    @append(t, v)

  # push a value, and pop the head if the size > limit (0=no limit)
  pushpop: (t, v, limit=0) ->
    @squelched = true
    @append(t, v)
    if limit > 0
      while @size() > limit
        @shift()
    @squelched = false
    @notify

  # create a streaming buffer which limits the rate
  # at which points are added to the data set
  streambuf: (pps=60, maxEvents=0) ->
    @buffer = $ts.buffer()
    @interval = setInterval () =>
      return if @buffer.size() == 0
      @squelched = true
      for [t, v] in @buffer.shift(Math.ceil(@buffer.size() / pps))
        @append(t, v)
      if @size() > maxEvents
        for x in [0..(@size() - maxEvents)]
          @shift()
      @squelched = false
      @notify()
    , 1000 / pps
    @buffer

  # notify listeners of a change
  notify: () ->
    if @squelched
      return

    for listener in @listeners
      listener()

  listen: (fn) ->
    @listeners.push(fn)

  # values as 1d array
  values: () ->
    r = []
    for [t, v] in @data
      r.push v
    r

  # The total duration of the series
  duration: () ->
    @end() - @start()

  # The start time
  start: () ->
    @first()[0]

  # The end time
  end: () ->
    @last()[0]

  # scan timeseries and get the range of events between
  # time nearest values of t1 and time t2
  scan: (t1, t2) ->
    idx1 = @nearest(t1)
    idx2 = @nearest(t2)

    # don't include a value not in range
    if @time(idx1) < t1
      ++idx1

    # slice goes up to, but doesn't include, so only
    # add if the nearest is less than
    if @time(idx2) < t2
      ++idx2

    new @constructor(@data.slice(idx1, idx2))

  # filter out items and return new
  # timeseries
  filter: (fn) ->
    r = []
    for tv in @data
      if fn(tv[0], tv[1])
        r.push tv
    new @constructor(r)

  # split the series into two series
  split: (time) ->
    r1 = []
    r2 = []
    for tv in @data
      if tv[0] <= time
        r1.push(tv)
      else
        r2.push(tv)
    [new @constructor(r1), new @constructor(r2)]


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
    min  = Infinity
    max  = -Infinity

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

  # shift the first item off the list and update stats
  shift: () ->
    first = @data.shift()
    v = first[1]
    if @_stats
      @_stats.sum -= v
      @_stats.sum2 -= v * v
      if v == @_stats.min
        min = Infinity
        for [t, v] in @data
          min = Math.min(v, min)
        @_stats.min = min
      if v == @_stats.max
        max = -Infinity
        for [t, v] in @data
          max = Math.max(v, max)
        @_stats.max = max
    @notify()
    first

  # append another timerseries item, updating calcs
  append: (t, v) ->
    if t < @end()
      throw "Can't append sample with past timestamp"
    if @_stats
      @_stats.sum += v
      @_stats.sum2 += v * v
      @_stats.min = Math.min(@_stats.min, v)
      @_stats.max = Math.max(@_stats.max, v)
    super(t, v)

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

  # value range (min, max)
  span: () ->
    @max() - @min()

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

  # return a sorted set of values
  valuesSorted: () ->
    return @_valuesSorted if @_valuesSorted
    @_valuesSorted = @values().sort((a, b) -> a - b)

  median: () ->
    half = Math.floor(@size() / 2)
    if @size() % 2
      @valuesSorted()[half]
    else
      (@valuesSorted()[half - 1] + @valuesSorted()[half]) / 2

  # takes a duration and function.  The function must 
  # accept a timestamp and data array parameter
  # eg: function(time, values) and return a single value
  rollup: (duration, fn) ->
    offset = duration / 2
    result = []
    t1 = @start()
    block = [] 
    for [t, v] in @data
      if t - t1 >= duration
        result.push [t1 + offset, fn(t1, block)]
        block = []
        t1 = t
      block.push v

    if block.length > 0
      result.push [t1 + offset, fn(t1, block)]

    new @constructor(result)


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
    if ts1.length != ts2.length
      throw "Array lengths must match for distance"
    sum = 0.0
    for i in [0..ts1.length - 1]
      diff = ts2[i] - ts1[i]
      sum += diff * diff
    Math.sqrt(sum)

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
        @lookup[key] = factory.numeric(@lookup[key])
      else
        @lookup[key] = factory.multi(@lookup[key])

  # find a series by name or path
  # eg: mts.series("hits")
  # eg: mts.series("hostname.com/hits")
  series: (name) ->
    if name[0] == "/"
      return @series(name.substr(1))

    if name.indexOf("/") > 0
      parts = name.split("/")
      head  = parts.shift()
      unless @lookup[head]
        throw "Can't get attribute #{head} of multi time series"
      return @lookup[head].series(parts.join("/"))

    # base case...
    unless @lookup[name]
      throw "Can't get attribute #{name} of multi time series"
    @lookup[name]

  append: (t, v) ->
    for key, value of v
      @lookup[key].append(t, value)
    super(t, v)

  shift: () ->
    for attr in @attrs
      @lookup[attr].shift()
    super()

  attr: (name) ->
    @series(name)

# expose the factory
root = if typeof module != "undefined" && module.exports
  module.exports
else
  window

root.$ts = factory
