ts.js
=====

A small timeseries library for the browser and node.js

Getting Started
---------------

Convert your timeseries data into a ts instance:

```js
var ts = $ts.wrap([
//[unix timestamp, value],
  [1351903913000 , 67.33],
  [1351913913000 , 62.33]
]);
```

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

Now you can call any of the following methods on your ts instance.

### Basic methods

* size() - get the number of samples
* first() - get the first sample
* last() - get the last sample
* sample(idx) - get sample at a particular index
* append(time, value) - add another sample to the series
* filter(function -> boolean) - get a new series with items filtered out
* map(function -> [time, value]) - get a new series with mutation applied
* toString() -> get string with basic information

### Time oriented methods

* timestamps() - get the timestamps as a flat list
* time(idx) - get the time at a particular index
* domain() - get the time frame, earliest and latest timestamp as array [t1, t2]
* nearest(timestamp) - get the sample closest to the given time (fuzzy search)

### Value methods (numeric only)

* min()
* max()
* mean()
* variance()
* stddev()
* values()
* range()
* value(index)
* statistics()
* norms()
* simplify(threshold)
* match(ts)

Examples
--------

```js
```

Contributing
------------

fork -> change -> test -> request pull

