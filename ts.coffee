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
    if @data.length == 0
      throw "Timeseries requires at least 1 data point"

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
  # a naive search against timestamps
  # todo: binary search
  nearest: (timestamp) ->
    idx = 0
    while idx < @size() && @data[idx][0] < timestamp
      idx++
    if idx >= @size()
      idx = @size() - 1
    if idx > 0
      d1 = @data[idx][0] - timestamp
      d2 = @data[idx - 1][0] - timestamp
      if Math.abs(d1) > Math.abs(d2)
        idx -= 1
    idx


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

root.$ts = (data, mapFn=null) ->
  if data
    data = mapFn(data) if mapFn
    return new Timeseries(data)

  index: (data, start=(new Date().getTime()), step=60000) ->
    i = 0
    r = []
    for v in data
      r.push [start + (i++ * step), v]
    r



