ts.coffee
=========

A small timeseries library for the browser and node.js

Getting Started
---------------

Convert your timeseries data into a ts instance:

```js
var ts = $ts([
//[unix timestamp, value],
  [1351903913000 , 67.33],
  [1351913913000 , 62.33]
]);
```

If your data doesn't have timestamps, you can also index
the values with timestamps.

```js
var ts = $ts(
  $ts().index(
    [1, 2, 2.2, 2.3, 2.2, 2, 1.9], // values
    new Date().getTime(), // start time
    60 * 1000 // step in milliseconds
  )
);
```

Now you can call any of the following methods on your ts instance.

* size()
* min()
* max()
* mean()
* variance()
* stddev()
* values()
* timestamps()
* domain()
* range()
* sample(index)
* value(index)
* time(index)

A few other methods

* norms()
* simplify(threshold)
* match(ts)
* nearest(timestamp)
* filter(function(timestamp, value) {})

Examples
--------

```js
```

Contributing
------------

fork -> change -> test -> request pull

