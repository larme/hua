local apply = nil
apply = function (f, args)
  return f(unpack(args))
end
local dec = nil
dec = function (n)
  return (n - 1)
end
local first = nil
first = function (tbl)
  return tbl[1]
end
local inc = nil
inc = function (n)
  return (n + 1)
end
local EXPORT = {dec = dec, inc = inc, apply = apply, first = first}
return(EXPORT)
