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
local _hua_anon_var_1
do
  local _hua_module_1235 = {}
  assoc(_hua_module_1235,"apply",apply)
  assoc(_hua_module_1235,"dec",dec)
  assoc(_hua_module_1235,"first",first)
  assoc(_hua_module_1235,"inc",inc)
  return _hua_module_1235
end
