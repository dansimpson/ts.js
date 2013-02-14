if(typeof exports != "undefined" && exports != null)
  root = global
else
  root = window

log = (args...) ->
  console.log args

merge = (object, opts...) ->
  for opt in opts
    for k, v of opt
      object[k] = v
  object
