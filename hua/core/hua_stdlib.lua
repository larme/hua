local clone = nil
local isArray = nil
local isTable = nil
local isEqual = nil
local isCallable = nil
local isIterable = nil
local isString = nil
local isFunction = nil
local isNil = nil
local isNumber = nil
local isNaN = nil
local isFinite = nil
local isBoolean = nil
local isInteger = nil
local _hua_anon_var_1
do
  local __hua_import_m__ = require("moses")
  clone = __hua_import_m__["clone"]
  isArray = __hua_import_m__["isArray"]
  isTable = __hua_import_m__["isTable"]
  isEqual = __hua_import_m__["isEqual"]
  isCallable = __hua_import_m__["isCallable"]
  isIterable = __hua_import_m__["isIterable"]
  isString = __hua_import_m__["isString"]
  isFunction = __hua_import_m__["isFunction"]
  isNil = __hua_import_m__["isNil"]
  isNumber = __hua_import_m__["isNumber"]
  isNaN = __hua_import_m__["isNaN"]
  isFinite = __hua_import_m__["isFinite"]
  isBoolean = __hua_import_m__["isBoolean"]
  isInteger = __hua_import_m__["isInteger"]
  _hua_anon_var_1 = isInteger
end
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
local is_array = isArray
local is_table = isTable
local is_equal = isEqual
local is_callable = isCallable
local is_iterable = isIterable
local is_string = isString
local is_function = isFunction
local is_nil = isNil
local is_number = isNumber
local is_nan = isNaN
local is_finite = isFinite
local is_boolean = isBoolean
local is_int = isInteger
local _hua_anon_var_2
do
  local _hua_module_1235 = {}
  _hua_module_1235["apply"] = apply
  _hua_module_1235["dec"] = dec
  _hua_module_1235["first"] = first
  _hua_module_1235["inc"] = inc
  _hua_module_1235["clone"] = clone
  _hua_module_1235["is_array"] = is_array
  _hua_module_1235["is_table"] = is_table
  _hua_module_1235["is_equal"] = is_equal
  _hua_module_1235["is_callable"] = is_callable
  _hua_module_1235["is_iterable"] = is_iterable
  _hua_module_1235["is_string"] = is_string
  _hua_module_1235["is_function"] = is_function
  _hua_module_1235["is_nil"] = is_nil
  _hua_module_1235["is_number"] = is_number
  _hua_module_1235["is_nan"] = is_nan
  _hua_module_1235["is_finite"] = is_finite
  _hua_module_1235["is_boolean"] = is_boolean
  _hua_module_1235["is_int"] = is_int
  return _hua_module_1235
end
