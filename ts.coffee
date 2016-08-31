###
ts.js - version 0.9.2

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
  wrap: (data, validate=true) ->
    if validate
      @validate(data)
    new Timeseries(data)

  # Create a NumericTimeseries object, capable basic plotting, etc
  numeric: (data, validate=true) ->
    if validate
      @validate(data)
      if typeof(data[0][1]) != "number"
        throw "NumericTimeseries expects timestamps and numbers; eg: [[timestamp, number]...]"
    new NumericTimeseries(data)

  # create a MultiTimeseries object with the data
  multi: (data, validate=true) ->
    if validate
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

factory = new TimeseriesFactory()

###
#
#
###
class Timeseries
  constructor: (@data) ->
    @squelched = false
    @listeners = []
    @init_listeners = []
    @timeframe = null

  # the number of samples
  size: () ->
    @data.length

  empty: () ->
    @data.length == 0

  # the number of samples
  length: () ->
    @data.length

  # the number of samples
  count: () ->
    @data.length

  # given a range of timestamps, find the nearest indices
  # for slicing
  slice_indices: (t1, t2) ->
    idx1 = @nearest(t1)
    idx2 = @nearest(t2)
    # don't include a value not in range
    if @time(idx1) < t1
      ++idx1
    # slice goes up to, but doesn't include, so only
    # add if the nearest is less than
    if @time(idx2) < t2
      ++idx2

    [idx1, idx2]

  # limit the total duration, or time frame of the
  # time series
  limit: (duration) ->
    @timeframe = duration
    @

  # If timeframe is set, trim head of series
  behead: () ->
    if @timeframe == null
      return []
    min = @end() - @timeframe
    count = 0
    while @data[count][0] < min
      count++
    head = @data.slice(0, count)
    @data = @data.slice(count)
    head

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
    if @empty()
      @data.push [t, v]
      return

    if t < @end()
      throw "Can't append sample with past timestamp"

    @data.push [t, v]

    @behead()
    @notify()

  # see append
  push: (t, v) ->
    @append(t, v)

  # see append
  add: (t, v) ->
    @append(t, v)

  # notify listeners of a change
  notify: () ->
    if @squelched
      return

    if @size() == 2
      for listener in @init_listeners
        listener()

    for listener in @listeners
      listener()

  listen: (fn) ->
    @listeners.push(fn)

  on_init: (fn) ->
    @init_listeners.push(fn)

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
    [idx1, idx2] = @slice_indices(t1, t2)
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

  # Break data into windows of a given duration, returning
  # a timeseries of timeseries objects
  partition: (duration) ->
    time = @start() - Math.abs(@start() % duration)
    result = []
    chunk  = []
    for [t, v] in @data
      while t - time >= duration
        result.push [time, factory.build(chunk)]
        chunk = []
        time += duration
      chunk.push [t, v]

    if chunk.length > 0
      result.push [time, factory.build(chunk)]

    # TODO: bind to parent and emit?
    factory.wrap(result, false)

  # map each series tuple to a new tuple via function call
  map: (fn) ->
    r = []
    for tv in @data
      r.push fn(tv[0], tv[1])
    factory.build(r)

  # partition by duration and fold each partitioned sub-series
  # into a new value
  pfold: (duration, fn) ->
    @partition(duration).map(fn)

  # timestamps as 1d array
  timestamps: () ->
    r = []
    for [t, v] in @data
      r.push t
    r

  # finds the nearest index in the domain using
  # a binary search
  # +timestamp+ the time to search for
  # +lbound+ if true, the index will always justify to the past
  nearest: (timestamp, lbound=false) ->
    if timestamp <= @start()
      return 0
    if timestamp >= @end()
      return @size() - 1

    idx = @bsearch(timestamp, 0, @size() - 1)
    if lbound && @time(idx) > timestamp
      idx = Math.max(0, idx - 1)
    idx

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
    min  = Infinity
    max  = -Infinity

    for [t, v] in @data
      sum += v
      if v > max
        max = v
      if v < min
        min = v

    @_stats =
      sum : sum
      min : min
      max : max

  # shift the first item off the list and update stats
  behead: () ->
    head = super()

    if head.length == 0 || !@_stats
      return

    for [t, v] in head
      @_stats.sum -= v
      # if we have the min, or max... just purge the cache
      if v == @_stats.min || v == @_stats.max
        @_stats = false
        return

  # append another timerseries item, updating calcs
  append: (t, v) ->
    if t < @end()
      throw "Can't append sample with past timestamp"
    if @_stats
      @_stats.sum += v
      @_stats.min = Math.min(@_stats.min, v)
      @_stats.max = Math.max(@_stats.max, v)
    super(t, v)

  # the sum of all values
  sum: () ->
    @statistics().sum

  # the sum of squares
  sumsq: () ->
    m = @mean()
    r = 0
    for [t, v] in @data
      n  = v - m
      r += n * n
    r

  # variance of the values
  variance: () ->
    @sumsq() / (@size() - 1)

  # standard deviation of the values
  stddev: () ->
    Math.sqrt(@variance())

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

  quartiles: () ->
    min: @min()
    p25: @p25th()
    mid: @median()
    p75: @p75th()
    max: @max()

  p25th: () ->
    @percentile(0.25)

  p75th: () ->
    @percentile(0.75)

  median: () ->
    @percentile(0.5)

  percentile: (p) ->
    idx = Math.floor(@size() * p)
    if @size() % 2
      @valuesSorted()[idx]
    else
      (@valuesSorted()[idx - 1] + @valuesSorted()[idx]) / 2

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

    factory.build(r)

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

    # add items to each sub array
    for point in @data
      for key, value of point[1]
        unless @lookup.hasOwnProperty(key)
          @lookup[key] = []
          @attrs.push(key)
        @lookup[key].push([point[0], value])

    # Convert array to ts oject, nested if need be
    for key, value of @lookup
      @lookup[key] = factory.build(@lookup[key])

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
        return null
      return @lookup[head].series(parts.join("/"))

    # base case...
    unless @lookup[name]
      return null
    @lookup[name]

  get: (name) ->
    @series(name)

  limit: (duration) ->
    super(duration)
    for name, ts of @lookup
      ts.limit(duration)

  append: (t, v) ->
    for key, value of v
      if @lookup.hasOwnProperty(key)
        @lookup[key].append(t, value)
      else
        @lookup[key] = factory.build([[t, value]])
        @attrs.push(key)
    super(t, v)

  attr: (name) ->
    @series(name)

  serieses: () ->
    @attrs

  # minimum of value
  min: () ->
    mins = []
    for key, series of @lookup when series.min
      mins.push(series.min())
    Math.min.apply(Math, mins)

  # maximum of values
  max: () ->
    maxes = []
    for key, series of @lookup when series.max
      maxes.push(series.max())
    Math.max.apply(Math, maxes)

  # determine if a series exists by name
  exists: (name) ->
    @series(name) != null


# expose the factory
root = if typeof module != "undefined" && module.exports
  module.exports
else
  window

root.$ts = factory
