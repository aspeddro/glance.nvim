local utils = require('glance.utils')

local M = {}

local function create_handler(method)
  return function(bufnr, params, handler)
    vim.lsp.buf_request(
      bufnr,
      method.lsp_method,
      params,
      function(err, m, results)
        results = method.lsp_method == m and results or m
        if err then
          utils.error(
            ('An error happened requesting %s: %s'):format(
              method.label,
              err.message
            )
          )
          return handler({})
        end
        if results == nil or #results == 0 then
          return handler({})
        end
        if method.normalize then
          for _, value in ipairs(results) do
            value.uri = value.targetUri or value.uri
            value.range = value.targetSelectionRange or value.range
          end
        end
        handler(results)
      end
    )
  end
end

M.methods = {
  type_definitions = {
    label = 'type definitions',
    lsp_method = 'textDocument/typeDefinition',
    normalize = true,
  },
  implementations = {
    label = 'implementations',
    lsp_method = 'textDocument/implementation',
  },
  definitions = {
    label = 'definitions',
    lsp_method = 'textDocument/definition',
    normalize = true,
  },
  references = {
    label = 'references',
    lsp_method = 'textDocument/references',
  },
}

for key, method in pairs(M.methods) do
  M.methods[key].handler = create_handler(method)
end

function M.request(name, params, bufnr, cb)
  if M.methods[name] then
    params.context = { includeDeclaration = true }
    M.methods[name].handler(bufnr, params, cb)
  else
    utils.error(("No such method '%s'"):format(name))
  end
end

return M
