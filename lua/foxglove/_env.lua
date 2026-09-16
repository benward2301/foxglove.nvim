return function(name)
  local value = os.getenv(name)
  if value == nil or value == '' then
    return nil
  end
  return value
end
