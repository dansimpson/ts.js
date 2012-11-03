class Runner
  constructor: (trace=false) ->
    @errors = 0
    @tests = 0
    @trace = trace
    @suite = ""

  describe: (text) ->
    @suite = text
    console.log("Running tests for #{text}")

  red: (msg) ->
    "\x1b[31m#{msg}\x1b[0m"
     
  green: (msg) ->
    "\x1b[32m#{msg}\x1b[0m"
  
  assertEqual: (a, b, padding) ->
    if a instanceof Array
      if a.length != b.length
        throw new Error("#{a} is not equal to #{b}, length mismatch")
      for i in [0..a.length]
        if a[i] != b[i]
          throw new Error("#{a} is not equal to #{b} at index #{i}")
      return this

    if padding
      unless a - padding < b && a + padding > b
        throw new Error("#{a} is not loosely equal to #{b}")
      return this

    if a != b
      throw new Error("#{a} is not equal to #{b}")
    
    this

  assertMatch: (a,b) ->
    unless b.match(a)
      throw new Error("#{b} does not match #{a}")
    this

  assertTrue: (a) ->
    if !!!a
      throw new Error("#{a} is not true")
    this
  
  assertFalse: (a) ->
    if a != false
      throw new Error("#{a} is not true")
    this

  assertExists: (a) ->
    if typeof a == "undefined"
      throw new Error("#{a} does not exist")
    this

  assertUndefined: (a) ->
    if a != undefined
      throw new Error("#{a} is defined")
    this

  assertNotNull: (a) ->
    if a == null
      throw new Error("#{a} is defined")
    this
  
  test: (name, fn) ->
    @tests++
    try
      fn()
      console.log(@green("☑ #{@suite} did #{name}"))
    catch err
      @errors++
      console.error(@red("☒ #{@suite} didn't #{name}"))
      if @trace
        console.log(err.stack)

  report: () ->
    console.log("-------------------")
    if @errors > 0

      console.error("#{@red('☒')} #{@errors}/#{@tests} failures")
    else
      console.log("#{@green('☑')} #{@tests} passes, 0 failures")

global.runner = new Runner(true)

require "./ts_test"

global.runner.report()
