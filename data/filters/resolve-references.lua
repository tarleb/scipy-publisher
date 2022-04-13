local ntables = 0
local nfigures = 0
local nequations = 0

local table_labels = {}
local figure_labels = {}
local equation_labels = {}
local labels = {}

local stringify = pandoc.utils.stringify

local function collect_table_labels (tbl)
  ntables = ntables + 1
  return tbl:walk {
    Span = function (span)
      local label = span.attributes.label
      if label then
        local label = stringify(span)
        table_labels[label] = tostring(ntables)
        labels[label] = {pandoc.Str(tostring(ntables))}
      end
    end
  }
end

local function collect_figure_labels (para)
  -- ensure that we are looking at an implicit figure
  if #para.content ~= 1 or para.content[1].t ~= 'Image' then
    return nil
  end
  local image = para.content[1]
  nfigures = nfigures + 1
  return pandoc.Para{
    image:walk {
      Span = function (span)
        local label = span.attributes.label
        if label then
          figure_labels[label] = tostring(nfigures)
          labels[label] = {pandoc.Str(tostring(nfigures))}
        end
      end
    }
  }
end

local function collect_equation_tags (span)
  local label = span.attributes.label
  if span.classes[1] == 'equation' and label then
    nequations = nequations + 1
    equation_labels[label] = tostring(nequations)
    labels[label] = {pandoc.Str(tostring(nequations))}
  end
end

local function normalize_label_span (span)
  if span.classes == pandoc.List{'label'} and span.identifier == '' then
    span.identifier = span.attributes.label or stringify(span)
    span.attributes.label = span.identifier
    span.classes = {}
    span.content = {}
  end
  if span.attributes.label and span.identifier == '' then
    span.identifier = span.attributes.label
  end
  if #span.content == 1 then
    local formula = span.content[1]
    if formula.t == 'Math' and formula.mathtype == 'DisplayMath' then
      span.classes:insert('equation')
    end
  end
  return span
end

local function resolve_ref_number (span)
  if span.classes == pandoc.List{'ref'} then
    local target = pandoc.utils.stringify(span)
    if FORMAT:match 'latex' then
      return pandoc.RawInline('latex', '\\ref{' .. target .. '}')
    else
      return pandoc.Link(labels[target], '#' .. target)
    end
  end
end

local function latex_equation (span)
  if span.classes == pandoc.List{'equation'} then
    local formula = #span.content == 1 and span.content[1] or nil
    if formula and formula.t == 'Math' then
      local env = span.type or 'equation'
      local label = span.attributes.label
        and string.format('\\label{%s}', span.attributes.label)
        or ''
      return pandoc.RawInline(
        'latex',
        string.format(
          [[\begin{%s}%s%s\end{%s}]], env, formula.text, label, env
        )
      )
    end
  end
end

if not FORMAT:match 'latex' then
  latex_equation = nil
end

return {
  { Span = normalize_label_span },
  {
    Table = collect_table_labels,
    Para = collect_figure_labels,
    Span = collect_equation_tags,
  },
  { Span = resolve_ref_number },
  { Span = latex_equation },
}
