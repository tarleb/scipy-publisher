if FORMAT:match 'latex' or FORMAT:match 'native' then
  return {}
end

RawBlock = function (raw)
  if raw.format == 'latex' then
    return pandoc.read(raw.text, 'latex').blocks
  end
end
