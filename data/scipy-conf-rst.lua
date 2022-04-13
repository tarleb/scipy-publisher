-- Convert definition list to metadata.
local function deflist_to_meta (items)
  local meta = pandoc.Meta{
    authors = pandoc.List{}
  }
  local author
  for i, item in ipairs(items) do
    local key = pandoc.utils.stringify(item[1])
    local value = pandoc.utils.blocks_to_inlines(item[2][1] or {})
    if key == 'author' then
      author = {name = value, institution = pandoc.List()}
      meta.authors:insert(author)
    elseif key == 'email' and author then
      author.email = value
    elseif key == 'orcid' and author then
      author.orcid = pandoc.utils.stringify(value)
    elseif key == 'institution' and author then
      author.institution:insert(value)
    elseif key == 'equal-contributor' and author then
      author[key] = true
    elseif key == 'corresponding' and author then
      author[key] = true
    else
      author = nil
      meta[key] = value
    end
  end
  return meta
end

local header = [=[
.. role:: ref

.. role:: label

.. role:: cite(raw)
    :format: latex

.. |---| unicode:: U+2014  .. em dash, trimming surrounding whitespace
    :trim:

.. |--| unicode:: U+2013   .. en dash
    :trim:
]=]

function Reader (input, opts)
  opts.standalone = false
  local doc = pandoc.read(header .. tostring(input), 'rst', opts)
  -- treat initial definition list as metadata
  if doc.blocks[1].t == 'DefinitionList' then
    doc.meta = deflist_to_meta(doc.blocks[1].content)
    doc.blocks:remove(1)
  end

  -- Promote top level heading to document title
  local title
  doc = doc:walk {
    Header = function (h)
      h.level = h.level - 1
      if h.level == 0 then
        title = h.content
        return {}
      end
      return h
    end
  }
  doc.meta.title = title

  -- parse raw LaTeX
  return doc:walk {
    RawBlock = function (raw)
      if raw.format == 'latex' then
        return pandoc.read(raw.text, 'latex').blocks
      end
    end
  }
end
