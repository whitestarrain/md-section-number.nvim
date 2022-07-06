local Stack = {}

Stack.__index = Stack
Stack.elements = {}

function Stack:push(element)
  table.insert(self.elements, self:length() + 1, element)
end

function Stack:length()
  return #self.elements
end

function Stack:pop()
  if self:is_empty() then
    return nil
  end
  local element = self.elements[self:length()]
  table.remove(self.elements, self:length())
  return element
end

function Stack:new(elements, attrs)
  attrs = attrs or {}
  attrs.elements = elements or {}
  return setmetatable(attrs, self)
end

function Stack:is_empty()
  return self:length() == 0
end

function Stack:peek()
  return self.elements[self:length()]
end

return Stack
