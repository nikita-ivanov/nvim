-- ~/.config/nvim/lua/plugins/dap.lua
return {
  "mfussenegger/nvim-dap",
  dependencies = {
    {
      "rcarriga/nvim-dap-ui",
      opts = {
        layouts = {
          {
            elements = {
              { id = "scopes", size = 0.5 },
              { id = "breakpoints", size = 0.25 },
              { id = "stacks", size = 0.25 },
            },
            position = "left",
            size = 40,
          },
          {
            elements = {
              { id = "console", size = 1.0 }, -- removed repl
            },
            position = "bottom",
            size = 15,
          },
        },
      },
    },
  },
  keys = {
    {
      "<F5>",
      function()
        require("dap").continue()
      end,
      desc = "Continue",
    },
    {
      "<F10>",
      function()
        require("dap").step_over()
      end,
      desc = "Step Over",
    },
    {
      "<F11>",
      function()
        require("dap").step_into()
      end,
      desc = "Step Into",
    },
    {
      "<F12>",
      function()
        require("dap").step_out()
      end,
      desc = "Step Out",
    },
    {
      "<F9>",
      function()
        require("dap").toggle_breakpoint()
      end,
      desc = "Toggle Breakpoint",
    },
    {
      "<leader>dd",
      function()
        require("dapui").open({ layout = 2 })
      end,
      desc = "DAP Console Only",
    },
    {
      "<leader>dx",
      function()
        require("dapui").close({ layout = 2 })
      end,
      desc = "DAP Close Console",
    },
  },
}
