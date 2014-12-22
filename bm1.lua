math.randomseed(os.time())

function test ()
  local x
  if (math.random(100) > 50) then
    x = 3
  else
    x = 2
  end

  return x
end

for i=1, 10000000 do
  test()
end

print(test())
