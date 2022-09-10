local t = {}

t[1] = 1
t[2] = 2
t[3] = 3
t[4] = 3
t[5] = 3
t[2] = nil
t[#t + 1] = 4
for k, v in pairs(t) do
    print(k, v)
end