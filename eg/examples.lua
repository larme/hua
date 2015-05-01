package.path = string.format("%s;%s/?.lua",package.path,"/Users/larme/codes/hua/hua/core")
local unpack = (unpack or table.unpack)
local apply = nil
local dec = nil
local first = nil
local inc = nil
local _hua_anon_var_1
do
  local __hua_import_m__ = require("hua_stdlib")
  apply = __hua_import_m__.apply
  dec = __hua_import_m__.dec
  first = __hua_import_m__.first
  inc = __hua_import_m__.inc
  _hua_anon_var_1 = nil
end
print("Simple Assignments and Arithmetic")
print("----------------------------")
local x = 10
x = 20
y = 40
z = 20
print("Some arithmetic operations",(x + y + z),(x < y and y < z), - (x))
print("------- section ends -------\n")
print("Table as Dict and List")
print("----------------------------")
local a_table = {name = "John"}
a_table.greeting = "Hello, "
print((a_table.greeting .. a_table.name .. "!"))
local a_list = {1, 2, 3, 4}
print("a-list length:",#(a_list))
a_table.l = a_list
print("a-table.l[3]:",a_table.l[3])
a_table.l[3] = 13
print("a-table.l[3] after assoc change the value:",a_table.l[3])
print("------- section ends -------\n")
print("Statements")
print("----------------------------")
local m, n = unpack({1, 2})
print("m, n:",m,n)
local _hua_anon_var_2
if x == y then
  _hua_anon_var_2 = print("x is equal to y")
else
  _hua_anon_var_2 = print("x is not equal to y")
end
local _hua_anon_var_6
if z < 20 then
  _hua_anon_var_6 = print("z is smaller than 20")
else
  local _hua_anon_var_5
  if z == 20 then
    _hua_anon_var_5 = print("z is equal to 20")
  else
    local _hua_anon_var_4
    if not (z <= 20) then
      _hua_anon_var_4 = print("z is larger than 20")
    else
      local _hua_anon_var_3
      if true then
        _hua_anon_var_3 = print("z is 42")
      else
        _hua_anon_var_3 = nil
      end
      _hua_anon_var_4 = _hua_anon_var_3
    end
    _hua_anon_var_5 = _hua_anon_var_4
  end
  _hua_anon_var_6 = _hua_anon_var_5
end
for i, v in ipairs({1, 3, 5}) do
  print("index and value in list:",i,v)
end
for i = 1, 11, 2 do
  print("numeric for:",i)
end
for i = 1, 3 do
  for key in pairs({pos = 3, cons = 2}) do
    print("mixed:",i,key)
  end
end
local l
do
  local _hua_result_1235 = {}
  for i = 1, 10 do
    for _, value in pairs({T = 1, F = 0}) do
      _hua_result_1235[(1 + #(_hua_result_1235))] = (i * value)
    end
  end
  l = _hua_result_1235
end
for _, v in ipairs(l) do
  print("list comprehensive result:",v)
end
print("------- section ends -------\n")
print("Functions")
print("----------------------------")
local double = nil
double = function (n)
  return (n * 2)
end
print("double of 21:",double(21))
local print_alot = nil
print_alot = function (a, ...)
  local rest = {...}
  print("first parameter:",a)
  for i, para in ipairs(rest) do
    print("rest parameter:",para)
  end
end
print_alot("That's","really","a","lot")
print_alot("That's",nil,"really","a","lot")
local test_tco = nil
test_tco = function (n)
  local _hua_anon_var_8
  if not (n <= 1) then
    _hua_anon_var_8 = test_tco((n - 1))
  else
    _hua_anon_var_8 = print("May overflow here, read the lua code to find out why")
  end
  return _hua_anon_var_8
end
local test_tco2 = nil
test_tco2 = function (n)
  local _hua_anon_var_9
  if not (n <= 1) then
    return test_tco2((n - 1))
  else
    _hua_anon_var_9 = print("No overflow!")
  end
  return _hua_anon_var_9
end
test_tco2(10000000)
local test_tco3 = nil
test_tco3 = function (n)
  local _hua_anon_var_12
  if not (n <= 10) then
    return test_tco3((n - 2))
  else
    local _hua_anon_var_11
    if (not (10 < n) and not (n < 2)) then
      return test_tco3((n - 1))
    else
      local _hua_anon_var_10
      if true then
        _hua_anon_var_10 = print("No overflow too!")
      else
        _hua_anon_var_10 = nil
      end
      _hua_anon_var_11 = _hua_anon_var_10
    end
    _hua_anon_var_12 = _hua_anon_var_11
  end
  return _hua_anon_var_12
end
test_tco3(10000000)
print("------- section ends -------\n")
print("Object Oriented")
print("----------------------------")
local Animal = nil
local _hua_anon_var_15
do
  local __hua_parent__ = nil
  local __hua_base__ = {__init = function (self, steps_per_turn)
    self.steps_per_turn = steps_per_turn
  end, move = function (self)
    return print(("I moved " .. tostring(self.steps_per_turn) .. " steps!"))
  end}
  local __hua_class_string__ = "Animal"
  __hua_base__.__index = __hua_base__
  local _hua_anon_var_13
  if __hua_parent__ then
    _hua_anon_var_13 = setmetatable(__hua_base__,__hua_parent__.__base)
  else
    _hua_anon_var_13 = nil
  end
  local __hua_cls_call__ = nil
  __hua_cls_call__ = function (cls, ...)
    local __hua_self__ = setmetatable({},__hua_base__)
    __hua_self__:__init(...)
    return __hua_self__
  end
  local __hua_class__ = setmetatable({__base = __hua_base__, __name = __hua_class_string__, __parent = __hua_parent__},{__call = __hua_cls_call__, __index = __hua_base__})
  __hua_base__.__class = __hua_class__
  local _hua_anon_var_14
  if (__hua_parent__ and __hua_parent__.__inherited) then
    _hua_anon_var_14 = __hua_parent__.__inherited(__hua_parent__,__hua_class__)
  else
    _hua_anon_var_14 = nil
  end
  Animal = __hua_class__
  _hua_anon_var_15 = nil
end
local Cat = nil
local _hua_anon_var_19
do
  local __hua_parent__ = Animal
  local __hua_base__ = {move = function (self)
    print(self.sound)
    return __hua_parent__.move(self)
  end, __init = function (self, steps_per_turn, sound)
    __hua_parent__.__init(self,steps_per_turn)
    self.sound = sound
  end}
  local __hua_class_string__ = "Cat"
  __hua_base__.__index = __hua_base__
  local _hua_anon_var_16
  if __hua_parent__ then
    _hua_anon_var_16 = setmetatable(__hua_base__,__hua_parent__.__base)
  else
    _hua_anon_var_16 = nil
  end
  local __hua_cls_call__ = nil
  __hua_cls_call__ = function (cls, ...)
    local __hua_self__ = setmetatable({},__hua_base__)
    __hua_self__:__init(...)
    return __hua_self__
  end
  local __hua_class__ = setmetatable({__base = __hua_base__, __name = __hua_class_string__, __parent = __hua_parent__},{__call = __hua_cls_call__, __index = function (cls, name)
    local val = rawget(__hua_base__,name)
    local _hua_anon_var_17
    if val == nil then
      _hua_anon_var_17 = __hua_parent__[name]
    else
      _hua_anon_var_17 = val
    end
    return _hua_anon_var_17
  end})
  __hua_base__.__class = __hua_class__
  local _hua_anon_var_18
  if (__hua_parent__ and __hua_parent__.__inherited) then
    _hua_anon_var_18 = __hua_parent__.__inherited(__hua_parent__,__hua_class__)
  else
    _hua_anon_var_18 = nil
  end
  Cat = __hua_class__
  _hua_anon_var_19 = nil
end
local a_cat = Cat(3,"meow meow meow!")
a_cat:move()
print("------- section ends -------\n")
print("Modules")
print("----------------------------")
local dummy1 = nil
local dummy2 = nil
local _hua_anon_var_20
do
  local __hua_import_m__ = require("dummy")
  dummy1 = __hua_import_m__.dummy1
  dummy2 = __hua_import_m__.dummy2
  _hua_anon_var_20 = nil
end
print("Variables in module \"dummy\"",dummy1,dummy2)
local _hua_anon_var_21
do
  local _hua_module_1236 = {}
  _hua_module_1236.test_tco3 = test_tco3
  return _hua_module_1236
end
print("------- section ends -------\n")
