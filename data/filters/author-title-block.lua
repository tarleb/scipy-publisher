--- Create an author title block

local type = pandoc.utils.type

local function ensure_list (obj)
  if type(obj) == 'List' then
    return obj
  elseif type(obj) == 'nil' then
    return pandoc.List{}
  end
  return pandoc.List{obj}
end

function Meta (meta)
  local authors = ensure_list(meta.author or meta.authors or pandoc.List{})
  local author_tex = pandoc.Inlines{}
  for i, author in ipairs(authors) do
    if i > 1 then
      if i == #authors then
        author_tex:extend{pandoc.Space(), pandoc.Str 'and', pandoc.Space()}
      else
        author_tex:extend{pandoc.Str ',', pandoc.Space()}
      end
    end
    author_tex:insert(pandoc.Str(author.name))
  end
  -- Iterate through authors again to handle affiliations.
  author_tex:insert(pandoc.RawInline('latex', '\\IEEEcompsocitemizethanks{'))
  for i, author in ipairs(authors) do
    print(type(author.institution))
    author_tex:insert(pandoc.RawInline('latex', '\\IEEEcompsocthanksitem '))
    author_tex:insert(pandoc.Str(author.name))
    author_tex:extend(pandoc.Inlines ' is with ')
    author_tex:extend(author.institution[1])
    author_tex:insert(pandoc.RawInline('latex', '.\n'))
  end
  author_tex:insert(pandoc.RawInline('latex', '}'))
  meta.author = author_tex
  return meta
end
