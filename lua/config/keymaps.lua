if vim.g.vscode then
  local vscode = require("vscode")

  -- Suppress command-line output that causes VS Code Output panel popups
  vim.opt.cmdheight = 1
  vim.opt.more = false
  vim.opt.report = 9999
  vim.opt.shortmess:append("sScW")

  -- Silent undo/redo
  vim.keymap.set("n", "u", "<cmd>silent! undo<CR>", { noremap = true, silent = true })
  vim.keymap.set("n", "<C-r>", "<cmd>silent! redo<CR>", { noremap = true, silent = true })

  -- Bypass neovim's cmdline entirely for search to prevent VS Code Output
  -- panel from popping up. Uses vim.ui.input which vscode-neovim routes to
  -- VS Code's native input box. Search register is set so n/N/hlsearch work.
  -- Prompt uses descriptive text (not "/" or "?") to avoid vscode-neovim
  -- misinterpreting it. hlsearch is only enabled when the pattern is found.
  local function silent_search(direction)
    local prompt = direction == "/" and "Search forward: " or "Search backward: "
    vim.ui.input({ prompt = prompt }, function(pattern)
      if pattern and pattern ~= "" then
        -- Disable hlsearch BEFORE setting register to prevent stale E486
        vim.cmd("silent! nohlsearch")
        vim.fn.setreg("/", pattern)
        vim.fn.histadd("/", pattern)
        vim.v.searchforward = direction == "/" and 1 or 0
        local flags = (direction == "/" and "" or "b") .. "sW"
        local found = vim.fn.search(pattern, flags)
        if found > 0 then
          vim.o.hlsearch = true
          pcall(vim.cmd, "silent! normal! zv")
        end
      end
    end)
  end

  vim.keymap.set("n", "/", function() silent_search("/") end,
    { noremap = true, silent = true, desc = "Search forward" })
  vim.keymap.set("n", "?", function() silent_search("?") end,
    { noremap = true, silent = true, desc = "Search backward" })

  -- Silent n/N with consistent direction (LazyVim-style saner behavior).
  -- Uses vim.fn.search() with the last pattern from the "/" register instead
  -- of normal! n/N, to completely avoid E486 messages reaching vscode-neovim.
  vim.keymap.set("n", "n", function()
    local pattern = vim.fn.getreg("/")
    if pattern == "" then return end
    local forward = vim.v.searchforward == 1
    local flags = (forward and "" or "b") .. "sW"
    local found = vim.fn.search(pattern, flags)
    if found > 0 then
      vim.o.hlsearch = true
      pcall(vim.cmd, "silent! normal! zv")
    end
  end, { noremap = true, silent = true, desc = "Next Search Result" })

  vim.keymap.set("n", "N", function()
    local pattern = vim.fn.getreg("/")
    if pattern == "" then return end
    local forward = vim.v.searchforward == 1
    local flags = (forward and "b" or "") .. "sW"
    local found = vim.fn.search(pattern, flags)
    if found > 0 then
      vim.o.hlsearch = true
      pcall(vim.cmd, "silent! normal! zv")
    end
  end, { noremap = true, silent = true, desc = "Prev Search Result" })

  -- Yank file path (absolute) - calls VS Code's copy path command
  vim.keymap.set("n", "yp", function()
    vscode.action("workbench.action.files.copyPathOfActiveFile")
  end, { noremap = true, silent = true, desc = "Yank file path" })

  -- Yank relative file path
  vim.keymap.set("n", "yP", function()
    vscode.action("workbench.action.files.copyRelativePathOfActiveFile")
  end, { noremap = true, silent = true, desc = "Yank relative file path" })

  -- Navigate between functions/classes using VS Code's LSP symbol provider.
  -- Replaces treesitter-textobjects ]f, ]c etc. which don't work in vscode-neovim.
  -- SymbolKind values: Class=4, Method=5, Function=11
  local function goto_symbol(direction, symbol_kinds)
    vscode.eval([[
      const editor = vscode.window.activeTextEditor;
      if (!editor) return;
      const symbols = await vscode.commands.executeCommand(
        'vscode.executeDocumentSymbolProvider',
        editor.document.uri
      );
      if (!symbols || symbols.length === 0) return;
      const kinds = args.kinds;
      const currentLine = editor.selection.active.line;
      function flatten(syms, result) {
        result = result || [];
        for (const s of syms) {
          if (kinds.includes(s.kind)) result.push(s);
          if (s.children) flatten(s.children, result);
        }
        return result;
      }
      const matches = flatten(symbols).sort((a, b) =>
        (a.range || a.location.range).start.line - (b.range || b.location.range).start.line
      );
      let target;
      if (args.direction === "next") {
        target = matches.find(s => (s.range || s.location.range).start.line > currentLine);
      } else {
        const before = matches.filter(s => (s.range || s.location.range).start.line < currentLine);
        target = before.length > 0 ? before[before.length - 1] : null;
      }
      if (target) {
        const range = target.range || target.location.range;
        const pos = new vscode.Position(range.start.line, range.start.character);
        editor.selection = new vscode.Selection(pos, pos);
        editor.revealRange(new vscode.Range(pos, pos));
      }
    ]], { args = { direction = direction, kinds = symbol_kinds } })
  end

  vim.keymap.set("n", "]f", function() goto_symbol("next", {11, 5}) end,
    { silent = true, desc = "Next Function" })
  vim.keymap.set("n", "[f", function() goto_symbol("prev", {11, 5}) end,
    { silent = true, desc = "Prev Function" })
  vim.keymap.set("n", "]c", function() goto_symbol("next", {4}) end,
    { silent = true, desc = "Next Class" })
  vim.keymap.set("n", "[c", function() goto_symbol("prev", {4}) end,
    { silent = true, desc = "Prev Class" })

  -- Navigate git hunks using VS Code's built-in change navigation
  -- (workbench.action.editor.nextChange moves cursor without opening peek widget)
  vim.keymap.set("n", "]h", function()
    vscode.action("workbench.action.editor.nextChange")
  end, { silent = true, desc = "Next Hunk" })
  vim.keymap.set("n", "[h", function()
    vscode.action("workbench.action.editor.previousChange")
  end, { silent = true, desc = "Prev Hunk" })

  vim.api.nvim_create_autocmd({"BufEnter", "VimEnter"}, {
    callback = function()
      vim.opt.cmdheight = 1
    end,
  })
end