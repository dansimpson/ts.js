###
Copyright 2012 Dan Simpson
MIT License
###
if(typeof exports != "undefined" && exports != null)
  root = global
else
  root = window

###
# Timeseries class
#
# A class for wrapping timed values
#
# data: a 2d array containing
# 
###
class Timeseries
  constructor: (@data) ->

  # the number of samples
  size: () -> 
    @data.length

  # the sum of all values
  sum: () ->
    return @_sum if @_sum
    r = 0.0
    for [t, v] in @data
      r += v
    @_sum = r

  # the sum of all squared values
  sumsq: () ->
    return @_sum2 if @_sum2
    r = 0.0
    for [t, v] in @data
      r += v * v
    @_sum2 = r

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

  # the first sample
  first: () ->
    @data[0]

  # the last sample
  last: () ->
    @data[@size() - 1]

  # get the sample at index idx
  sample: (idx) ->
    @data[idx]

  # get the value at index idx
  value: (idx) ->
    @sample(idx)[1]

  # get the time at index idx
  time: (idx) ->
    @sample(idx)[0]

  # time domain (earliest, latest)
  domain: () ->
    [@first()[0], @last()[0]]

  # value range (min, max)
  range: () ->
    return @_range if @_range
    min = 99999999999
    max = -min
    for [t, v] in @data
      if v > max
        max = v
      if v < min
        min = v
    @_range = [min, max]

  # minimum of value
  min: () ->
    @range()[0]

  # maximum of values
  max: () ->
    @range()[1]

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
    new Timeseries(r)


  # timestamps as 1d array
  timestamps: () ->
    r = []
    for [t, v] in @data
      r.push t
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
class MultiTimeseries
  constructor: (@lookup) ->
    @attrs = []
    for key, ts of @lookup
      @attrs.push(key)
    @data = @lookup[@attrs[0]]

  get: (attr) ->
    unless @lookup[attr]
      throw "Can't get attribute #{attr} of multi time series"
    @lookup[attr]

  dispatch: (method, attr=null, args) ->
    # console.log "dispatching:", method, attr, args
    if attr
      @get(attr)[method](args)
    else
      res = {}
      for attr in @attrs
        res[attr] = @get(attr)[method](args)
      res

  # the number of samples
  size: () -> 
    @data.size()

  # the sum of all values
  sum: (attr=null) ->
    @dispatch("sum", attr)

  # the sum of all squared values
  sumsq: (attr=null) ->
    @dispatch("sumsq", attr)

  # variance of the values
  variance: (attr=null) ->
    @dispatch("variance", attr)

  # standard deviation of the values
  stddev: (attr=null) ->
    @dispatch("stddev", attr)

  # mean of value
  mean: (attr=null) ->
    @dispatch("mean", attr)

  # the first sample
  first: (attr=null) ->
    @sample(0, attr)

  # the last sample
  last: (attr=null) ->
    @sample(@size() - 1, attr)

  # get the sample at index idx
  sample: (idx, attr=null) ->
    [@time(idx), @value(idx, attr)]

  # get the value at index idx
  value: (idx, attr=null) ->
    @dispatch("value", attr, idx)

  # get the time at index idx
  time: (idx) ->
    @data.time(idx)

  # value range (min, max)
  range: (attr=null) ->
    @dispatch("range", attr)

  # minimum of value
  min: (attr=null) ->
    @dispatch("min", attr)

  # maximum of values
  max: (attr=null) ->
    @dispatch("max", attr)

  # values as 1d array
  values: (attr=null) ->
    @dispatch("values", attr)

  # filter out items and return new
  # timeseries
  filter: (attr=null, fn) ->
    # not sure

  # normalized values as 1d array
  norms: (attr=null) ->
    @dispatch("norms", attr)

  # time domain (earliest, latest)
  domain: () ->
    @data.domain()

  # timestamps as 1d array
  timestamps: () ->
    @data.timestamps()

  # finds the nearest index in the domain using
  # a binary search
  nearest: (timestamp) ->
    @data.nearest(timestamp)

  # report
  toString: () ->
    for attr, ts of @lookup
      ts.toString()

# Factory function
root.$ts = (data, mapper=null, sort=false) ->
  if data
    if mapper
      tmp = []
      for item in data
        tmp.push mapper(item)
      data = tmp

    if data.length == 0
      throw "ts.coffee takes an array of data"

    if typeof(data[0][0]) != "number"
      throw "ts.coffee requires timestamps; eg: [[timestamp, value]...]"

    if typeof(data[0][1]) == "number"
      return new Timeseries(data)

    # At this point we should have a time series
    # with standard object values (key, value).
    # Take those values and split them into singular ts
    lookup = {}
    for key, value of data[0][1]
      lookup[key] = []

    # add items to each sub array
    for point in data
      for key, value of point[1]
        lookup[key].push([point[0], value])
    
    # Conver array to actual ts, nested if need be
    for key, value of lookup
      lookup[key] = $ts(lookup[key])


    return new MultiTimeseries(lookup)

  index: (data, start=(new Date().getTime()), step=60000) ->
    i = 0
    r = []
    for v in data
      r.push [start + (i++ * step), v]
    r



