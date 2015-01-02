-- local mlc = require "metalua.compiler".new()

-- local s_ast = mlc:src_to_ast("local x = 3")

function print_table(t)
  for key, value in pairs(t) do print(key, value) end
end

local ast_sample = {tag="Local", 
		    {{tag="Id", "love"}, {tag="Id", "hate"}}, 
		    {{tag="Number", 1}, {tag="Number", 3}}}

local ast_sample2 = {tag="Number", 1}

local ast_sample3 = {tag="Id", "y"}

local ast_sample4 = {tag="Return", {tag="Number", 1}}

local ast_samples = {ast_sample, ast_sample4}

-- local src = mlc:ast_to_src(ast_samples)

local x = 3

function plus(a, b)
  return a + b
end

local function plus2(a, b)
  return a + b
end

if true then
  local test = 1
else
  local test = 2
end

print(test)
print("ha")

if true then
  return 3
else
  return 4
end

