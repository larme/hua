math.randomseed(os.time())

function test ()
  local x = (function () if (math.random(100) > 50) then
	return 3
			 else
			   return		   2
			 end
	    end)()
  return x
end

for i=1, 10000000 do
  test()
end

print(test())
