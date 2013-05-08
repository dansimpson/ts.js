## ts.js

A tiny timeseries library (6k minified) for the browser and node.js

### Getting Started

There are three types of time series
* Timeseries
* NumericTimeseries (extends Timeseries) - all values are numeric
* MultiTimeseries (extends Timeseries) - values are objects, which have nested numeric values

Convert your timeseries data into a ts instance:

```js
var ts = $ts.numeric([
  [1351903913000 , 67.33],
  [1351913913000 , 62.33]
]);

// strings
var ts = $ts.wrap([
  [1351903913000 , "yes"],
  [1351913913000 , "no"]
]);

// sub objects (numeric)
var ts = $ts.multi([
  [1351903913000 , {
    hits: 15,
    users: 3
  }],
  [1351913913000 , {
    hits: 17,
    users: 1
  }]
]);

// guess the type
var ts = $ts.build([ts, something]);
```

Now you can call any of the following methods, depending on the type of timeseries you have created.

### Timeseries

* size(), length(), count() -> the number of samples
* first() -> the first sample
* last() -> the last sample
* sample(idx) -> the sample at a particular index
* value(idx) -> the value at a particular index
* append(time, value) - add another sample to the series
* filter(function(time, value) -> boolean) - get a new series with items filtered out
* map(function(time, value) -> [time, value]) - get a new series with mutation applied
* toString() -> get string with basic information, nice for console.log
* timestamps() - get the timestamps as a flat list
* time(idx) - get the time at a particular index
* domain() - get the time frame, earliest and latest timestamp as array [t1, t2]
* nearest(timestamp) - get the sample closest to the given time (fuzzy search)
* scan(time1, time2) - get a new timeseries between two dates (using nearest, fuzzy)

### NumericTimeseries

* min() -> min value
* max() -> max value
* mean() -> average
* variance() -> variance
* stddev() -> standard deviation
* values() -> value set
* range() -> range of values, [min, max]
* statistics() -> a collection of stats: min, max, mean, stddev
* norms() -> vnorms of the values
* simplify(threshold) -> yield a simplified data set
* match(ts) -> do a pattern match against the series

### MultiTimseries

* series(path) -> fetch a series by name or path.

For example:

```js
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
```

When building a timeseries with $ts.multi(data), 4 underlying timeseries will be created.  You can access the individual series by using the `series` method:

```js
ts.series("dan"); // -> MultiTimeseries instance
ts.series("dan/calories"); // -> NumericTimeseries
ts.series("dan/calories").max(); // -> max calories for any time series entry
```

##### More

If your data doesn't have timestamps, you can also index
the values with timestamps.

```js
var ts = $ts.numeric(
  $ts.timestamp(
    [1, 2, 2.2, 2.3, 2.2, 2, 1.9], // values
    new Date().getTime(), // start time
    60 * 1000 // step in milliseconds
  )
);
```

#### Contributing

fork -> modify -> rake test -> request pull

#### Contributors
* Dan Simpson
* Mike Countis
