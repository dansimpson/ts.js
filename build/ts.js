// Generated by CoffeeScript 1.6.2
/*
ts.js - version 0.9.0

Copyright 2012 Dan Simpson, Mike Countis

MIT License: http://opensource.org/licenses/MIT
*/


(function() {
  var MultiTimeseries, NumericTimeseries, Timeseries, TimeseriesFactory, factory, root,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  TimeseriesFactory = (function() {
    function TimeseriesFactory() {}

    TimeseriesFactory.prototype.validate = function(data) {
      if (data.length === 0) {
        throw "Timeseries expects an array of data.";
      }
      if (data[0].length !== 2) {
        throw "Timeseries expects input like [[timestamp, value]...]";
      }
      if (typeof data[0][0] !== "number") {
        throw "Timeseries expects timestamps; eg: [[timestamp, value]...]";
      }
    };

    TimeseriesFactory.prototype.timestamp = function(data, start, step) {
      var i, r, v, _i, _len;

      if (start == null) {
        start = new Date().getTime();
      }
      if (step == null) {
        step = 60000;
      }
      i = 0;
      r = [];
      for (_i = 0, _len = data.length; _i < _len; _i++) {
        v = data[_i];
        r.push([start + (i++ * step), v]);
      }
      return r;
    };

    TimeseriesFactory.prototype.wrap = function(data) {
      this.validate(data);
      return new Timeseries(data);
    };

    TimeseriesFactory.prototype.numeric = function(data) {
      this.validate(data);
      if (typeof data[0][1] !== "number") {
        throw "NumericTimeseries expects timestamps and numbers; eg: [[timestamp, number]...]";
      }
      return new NumericTimeseries(data);
    };

    TimeseriesFactory.prototype.multi = function(data) {
      this.validate(data);
      return new MultiTimeseries(data);
    };

    TimeseriesFactory.prototype.build = function(data) {
      this.validate(data);
      if (typeof data[0][1] === "number") {
        return this.numeric(data);
      } else if (typeof data[0][1] === "string") {
        return this.wrap(data);
      } else {
        return this.multi(data);
      }
    };

    return TimeseriesFactory;

  })();

  factory = new TimeseriesFactory();

  /*
  #
  #
  */


  Timeseries = (function() {
    function Timeseries(data) {
      this.data = data;
      this.listeners = [];
    }

    Timeseries.prototype.size = function() {
      return this.data.length;
    };

    Timeseries.prototype.length = function() {
      return this.data.length;
    };

    Timeseries.prototype.count = function() {
      return this.data.length;
    };

    Timeseries.prototype.first = function() {
      return this.data[0];
    };

    Timeseries.prototype.last = function() {
      return this.data[this.size() - 1];
    };

    Timeseries.prototype.sample = function(idx) {
      return this.data[idx];
    };

    Timeseries.prototype.time = function(idx) {
      return this.data[idx][0];
    };

    Timeseries.prototype.value = function(idx) {
      return this.data[idx][1];
    };

    Timeseries.prototype.domain = function() {
      return [this.first()[0], this.last()[0]];
    };

    Timeseries.prototype.shift = function() {
      var shift;

      shift = this.data.shift();
      this.notify();
      return shift;
    };

    Timeseries.prototype.append = function(t, v) {
      if (t < this.end()) {
        throw "Can't append sample with past timestamp";
      }
      this.data.push([t, v]);
      return this.notify();
    };

    Timeseries.prototype.notify = function() {
      var listener, _i, _len, _ref, _results;

      _ref = this.listeners;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        listener = _ref[_i];
        _results.push(listener());
      }
      return _results;
    };

    Timeseries.prototype.listen = function(fn) {
      return this.listeners.push(fn);
    };

    Timeseries.prototype.values = function() {
      var r, t, v, _i, _len, _ref, _ref1;

      r = [];
      _ref = this.data;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        _ref1 = _ref[_i], t = _ref1[0], v = _ref1[1];
        r.push(v);
      }
      return r;
    };

    Timeseries.prototype.duration = function() {
      return this.end() - this.start();
    };

    Timeseries.prototype.start = function() {
      return this.first()[0];
    };

    Timeseries.prototype.end = function() {
      return this.last()[0];
    };

    Timeseries.prototype.scan = function(t1, t2) {
      var idx1, idx2;

      idx1 = this.nearest(t1);
      idx2 = this.nearest(t2);
      if (this.time(idx1) < t1) {
        ++idx1;
      }
      if (this.time(idx2) < t2) {
        ++idx2;
      }
      return new this.constructor(this.data.slice(idx1, idx2));
    };

    Timeseries.prototype.filter = function(fn) {
      var r, tv, _i, _len, _ref;

      r = [];
      _ref = this.data;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        tv = _ref[_i];
        if (fn(tv[0], tv[1])) {
          r.push(tv);
        }
      }
      return new this.constructor(r);
    };

    Timeseries.prototype.map = function(fn) {
      var r, tv, _i, _len, _ref;

      r = [];
      _ref = this.data;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        tv = _ref[_i];
        r.push(fn(tv[0], tv[1]));
      }
      return new this.constructor(r);
    };

    Timeseries.prototype.timestamps = function() {
      var r, t, v, _i, _len, _ref, _ref1;

      r = [];
      _ref = this.data;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        _ref1 = _ref[_i], t = _ref1[0], v = _ref1[1];
        r.push(t);
      }
      return r;
    };

    Timeseries.prototype.nearest = function(timestamp) {
      return this.bsearch(timestamp, 0, this.size() - 1);
    };

    Timeseries.prototype.bsearch = function(timestamp, idx1, idx2) {
      var diff1, diff2, mid;

      mid = Math.floor((idx2 - idx1) / 2.0) + idx1;
      if (idx1 === mid) {
        diff1 = Math.abs(this.time(idx1) - timestamp);
        diff2 = Math.abs(this.time(idx2) - timestamp);
        if (diff2 > diff1) {
          return idx1;
        } else {
          return idx2;
        }
      } else if (timestamp < this.time(mid)) {
        return this.bsearch(timestamp, idx1, mid);
      } else if (timestamp > this.time(mid)) {
        return this.bsearch(timestamp, mid, idx2);
      } else {
        return mid;
      }
    };

    Timeseries.prototype.toString = function() {
      return "Timeseries\nitems   : " + (this.size()) + "\ndomain  : " + (this.domain());
    };

    return Timeseries;

  })();

  /*
  # NumbericTimeseries class
  #
  # A class for wrapping timed values
  #
  # data: a 2d array containing
  #
  */


  NumericTimeseries = (function(_super) {
    __extends(NumericTimeseries, _super);

    function NumericTimeseries(data) {
      this.data = data;
      NumericTimeseries.__super__.constructor.call(this, this.data);
    }

    NumericTimeseries.prototype.statistics = function() {
      var max, min, sum, sum2, t, v, _i, _len, _ref, _ref1;

      if (this._stats) {
        return this._stats;
      }
      sum = 0.0;
      sum2 = 0.0;
      min = Infinity;
      max = -Infinity;
      _ref = this.data;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        _ref1 = _ref[_i], t = _ref1[0], v = _ref1[1];
        sum += v;
        sum2 += v * v;
        if (v > max) {
          max = v;
        }
        if (v < min) {
          min = v;
        }
      }
      return this._stats = {
        sum: sum,
        min: min,
        max: max,
        sum2: sum2
      };
    };

    NumericTimeseries.prototype.shift = function() {
      var first, max, min, t, v, _i, _j, _len, _len1, _ref, _ref1, _ref2, _ref3;

      first = this.data.shift();
      v = first[1];
      if (this._stats) {
        this._stats.sum -= v;
        this._stats.sum2 -= v * v;
        if (v === this._stats.min) {
          min = Infinity;
          _ref = this.data;
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            _ref1 = _ref[_i], t = _ref1[0], v = _ref1[1];
            min = Math.min(v, min);
          }
          this._stats.min = min;
        }
        if (v === this._stats.max) {
          max = -Infinity;
          _ref2 = this.data;
          for (_j = 0, _len1 = _ref2.length; _j < _len1; _j++) {
            _ref3 = _ref2[_j], t = _ref3[0], v = _ref3[1];
            max = Math.min(v, max);
          }
          this._stats.max = max;
        }
      }
      this.notify();
      return first;
    };

    NumericTimeseries.prototype.append = function(t, v) {
      if (t < this.end()) {
        throw "Can't append sample with past timestamp";
      }
      if (this._stats) {
        this._stats.sum += v;
        this._stats.sum2 += v * v;
        this._stats.min = Math.min(this._stats.min, v);
        this._stats.max = Math.max(this._stats.max, v);
      }
      return NumericTimeseries.__super__.append.call(this, t, v);
    };

    NumericTimeseries.prototype.sum = function() {
      return this.statistics().sum;
    };

    NumericTimeseries.prototype.sumsq = function() {
      return this.statistics().sum2;
    };

    NumericTimeseries.prototype.variance = function() {
      var n, r, t, v, _i, _len, _ref, _ref1;

      r = 0;
      _ref = this.data;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        _ref1 = _ref[_i], t = _ref1[0], v = _ref1[1];
        n = v - this.mean();
        r += n * n;
      }
      return r / (this.size() - 1);
    };

    NumericTimeseries.prototype.stddev = function() {
      return Math.sqrt((this.sumsq() / this.size()) / (this.mean() * this.mean()));
    };

    NumericTimeseries.prototype.mean = function() {
      return this.sum() / this.size();
    };

    NumericTimeseries.prototype.range = function() {
      return [this.min(), this.max()];
    };

    NumericTimeseries.prototype.span = function() {
      return this.max() - this.min();
    };

    NumericTimeseries.prototype.min = function() {
      return this.statistics().min;
    };

    NumericTimeseries.prototype.max = function() {
      return this.statistics().max;
    };

    NumericTimeseries.prototype.values = function() {
      var r, t, v, _i, _len, _ref, _ref1;

      r = [];
      _ref = this.data;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        _ref1 = _ref[_i], t = _ref1[0], v = _ref1[1];
        r.push(v);
      }
      return r;
    };

    NumericTimeseries.prototype.norms = function() {
      var r, t, v, _i, _len, _ref, _ref1;

      r = [];
      _ref = this.data;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        _ref1 = _ref[_i], t = _ref1[0], v = _ref1[1];
        r.push((v - this.mean()) / this.stddev());
      }
      return r;
    };

    NumericTimeseries.prototype.simplify = function(threshold) {
      var last, r, range, tv, _i, _len, _ref;

      if (threshold == null) {
        threshold = 0.1;
      }
      last = this.first();
      range = this.max() - this.min();
      r = [last];
      _ref = this.data;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        tv = _ref[_i];
        if (((Math.abs(tv[1] - last[1])) / range) > threshold) {
          if (last[0] !== r[r.length - 1][0]) {
            r.push(last);
          }
          r.push(tv);
        }
        last = tv;
      }
      if (last[0] !== r[r.length - 1][0]) {
        r.push(last);
      }
      return new Timeseries(r);
    };

    NumericTimeseries.prototype.match = function(pattern) {
      var best, distance, i, idx, query, source, _i, _ref;

      if (!(pattern instanceof Timeseries)) {
        throw "Must match against a Timeseries object";
      }
      best = 999999999;
      idx = -1;
      query = pattern.norms();
      source = this.norms();
      if (!(query.length <= source.length)) {
        throw "Query length exceeds source length";
      }
      for (i = _i = 0, _ref = source.length - query.length - 1; 0 <= _ref ? _i <= _ref : _i >= _ref; i = 0 <= _ref ? ++_i : --_i) {
        distance = this._distance(query, source.slice(i, +(i + query.length) + 1 || 9e9));
        if (distance < best) {
          best = distance;
          idx = i;
        }
      }
      return idx;
    };

    NumericTimeseries.prototype._distance = function(ts1, ts2) {
      var diff, i, sum, _i, _ref;

      if (ts1.length !== ts2.length) {
        throw "Array lengths must match for distance";
      }
      sum = 0.0;
      for (i = _i = 0, _ref = ts1.length - 1; 0 <= _ref ? _i <= _ref : _i >= _ref; i = 0 <= _ref ? ++_i : --_i) {
        diff = ts2[i] - ts1[i];
        sum += diff * diff;
      }
      return Math.sqrt(sum);
    };

    NumericTimeseries.prototype.toString = function() {
      return "Timeseries\nitems   : " + (this.size()) + "\nmean    : " + (this.mean()) + "\nstddev  : " + (this.stddev()) + "\ndomain  : " + (this.domain()) + "\nrange   : " + (this.range()) + "\nvariance: " + (this.variance());
    };

    return NumericTimeseries;

  })(Timeseries);

  /*
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
  */


  MultiTimeseries = (function(_super) {
    __extends(MultiTimeseries, _super);

    function MultiTimeseries(data) {
      var key, point, value, _i, _len, _ref, _ref1, _ref2;

      this.data = data;
      MultiTimeseries.__super__.constructor.call(this, this.data);
      this.lookup = {};
      this.attrs = [];
      _ref = data[0][1];
      for (key in _ref) {
        value = _ref[key];
        this.attrs.push(key);
        this.lookup[key] = [];
      }
      for (_i = 0, _len = data.length; _i < _len; _i++) {
        point = data[_i];
        _ref1 = point[1];
        for (key in _ref1) {
          value = _ref1[key];
          this.lookup[key].push([point[0], value]);
        }
      }
      _ref2 = this.lookup;
      for (key in _ref2) {
        value = _ref2[key];
        if (typeof this.lookup[key][0][1] === "number") {
          this.lookup[key] = factory.numeric(this.lookup[key]);
        } else {
          this.lookup[key] = factory.multi(this.lookup[key]);
        }
      }
    }

    MultiTimeseries.prototype.series = function(name) {
      var head, parts;

      if (name[0] === "/") {
        return this.series(name.substr(1));
      }
      if (name.indexOf("/") > 0) {
        parts = name.split("/");
        head = parts.shift();
        if (!this.lookup[head]) {
          throw "Can't get attribute " + head + " of multi time series";
        }
        return this.lookup[head].series(parts.join("/"));
      }
      if (!this.lookup[name]) {
        throw "Can't get attribute " + name + " of multi time series";
      }
      return this.lookup[name];
    };

    MultiTimeseries.prototype.append = function(t, v) {
      var key, value;

      for (key in v) {
        value = v[key];
        this.lookup[key].append(t, value);
      }
      return MultiTimeseries.__super__.append.call(this, t, v);
    };

    MultiTimeseries.prototype.shift = function() {
      var attr, _i, _len, _ref;

      _ref = this.attrs;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        attr = _ref[_i];
        this.lookup[attr].shift();
      }
      return MultiTimeseries.__super__.shift.call(this);
    };

    MultiTimeseries.prototype.attr = function(name) {
      return this.series(name);
    };

    return MultiTimeseries;

  })(Timeseries);

  root = typeof module !== "undefined" && module.exports ? module.exports : window;

  root.$ts = factory;

}).call(this);
