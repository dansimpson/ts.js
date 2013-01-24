require "../ts.coffee"

runner.describe "$ts"

runner.test "instantiate", () ->
  runner.assertNotNull $ts([[0, 1], [1, 1]])

runner.test "index data", () ->
  ts = $ts().index([1, 2, 2.2, 2.3, 2.2, 2, 1.9], 1000, 60)
  runner.assertEqual 1000, ts[0][0]
  runner.assertEqual 1060, ts[1][0]
  runner.assertEqual 2, ts[1][1]

############################

runner.describe "timeseries"

time = 0
data = $ts().index([1, 2, 3, 6, 4, 4, 4], time)
ts   = $ts(data)

runner.test "calc min", () ->
  runner.assertEqual 1, ts.min()

runner.test "calc max", () ->
  runner.assertEqual 6, ts.max()

runner.test "calc mean", () ->
  runner.assertEqual 3.42, ts.mean(), 0.1

runner.test "calc size", () ->
  runner.assertEqual 7, ts.size()

runner.test "give first", () ->
  runner.assertEqual time, ts.first()[0]
  runner.assertEqual 1, ts.first()[1]

runner.test "give last", () ->
  runner.assertEqual data[data.length - 1][0], ts.last()[0]
  runner.assertEqual data[data.length - 1][1], ts.last()[1]

runner.test "give range", () ->
  runner.assertEqual [1, 6], ts.range()

runner.test "give domain", () ->
  runner.assertEqual [time, data[data.length - 1][0]], ts.domain()

runner.test "compute sum", () ->
  runner.assertEqual 24, ts.sum()

runner.test "compute sumsq", () ->
  runner.assertEqual 98, ts.sumsq()

runner.test "compute variance", () ->
  runner.assertEqual 2.619, ts.variance(), 0.1

runner.test "compute stddev", () ->
  runner.assertEqual 1.09, ts.stddev(), 0.1

runner.test "compute nearest", () ->
  runner.assertEqual 0, ts.nearest(0)
  runner.assertEqual 6, ts.nearest(ts.last()[0] + 50)
  runner.assertEqual 5, ts.nearest(ts.last()[0] - 60000)
  runner.assertEqual 4, ts.nearest(ts.last()[0] - 90001)
  runner.assertEqual 5, ts.nearest(ts.last()[0] - 89999)
  runner.assertEqual 5, ts.nearest(ts.last()[0] - 90000)

runner.test "give sample", () ->
  runner.assertEqual [time, 1], ts.sample(0)

runner.test "give value", () ->
  runner.assertEqual 1, ts.value(0)

runner.test "give time", () ->
  runner.assertEqual time, ts.time(0)

runner.test "simplify", () ->
  ts1 = $ts($ts().index([1,1,1,1,2,1,1,1,1]))
  ts2 = ts1.simplify()

  runner.assertEqual [1,1,2,1,1], ts2.values()
  runner.assertEqual ts1.first(), ts2.first()
  runner.assertEqual ts1.last(), ts2.last()

runner.test "filter", () ->
  filtered = ts.filter (t, v) ->
    v % 2 == 0
  
  runner.assertEqual 5, filtered.size()
  runner.assertEqual 2, filtered.min()

