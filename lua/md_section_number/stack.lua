local Stack = {}

Stack.__index = Stack

function Stack:push(element)
	table.insert(self, #self + 1, element)
end

function Stack:pop()
	local element = self[#self]
	table.remove(self, #self)
	return element
end

function Stack:new(attrs)
	attrs = attrs or {}
	return setmetatable(attrs, self)
end

return Stack
