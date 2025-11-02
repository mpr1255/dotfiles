-- Disable smooth scrolling plugin
return {
  -- Disable neoscroll.nvim if it's included
  { "karb94/neoscroll.nvim", enabled = false },

  -- Disable mini.animate smooth scrolling
  {
    "echasnovski/mini.animate",
    enabled = false,
  },

  -- Disable any other smooth scroll plugins
  { "psliwka/vim-smoothie", enabled = false },
  { "declancm/cinnamon.nvim", enabled = false },
}
