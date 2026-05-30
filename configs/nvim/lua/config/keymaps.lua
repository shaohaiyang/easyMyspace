local map = vim.keymap.set
local opts = { silent = true, noremap = true }

-- Better escape
map("i", "jk", "<Esc>", opts)
map("i", "kj", "<Esc>", opts)

-- Clear search highlights
map("n", "<Esc>", "<cmd>nohlsearch<CR>", opts)

-- Save / Quit
map("n", "<C-s>", "<cmd>w<CR>", opts)
map("n", "<C-q>", "<cmd>q<CR>", opts)

-- Move lines in visual mode
map("v", "J", ":m '>+1<CR>gv=gv", opts)
map("v", "K", ":m '<-2<CR>gv=gv", opts)

-- Keep cursor centered when jumping
map("n", "n", "nzzzv", opts)
map("n", "N", "Nzzzv", opts)
map("n", "<C-d>", "<C-d>zz", opts)
map("n", "<C-u>", "<C-u>zz", opts)

-- Better paste
map("x", "<leader>p", "\"_dP", opts)

-- Yank to system clipboard
map({ "n", "v" }, "<leader>y", "\"+y", opts)
map("n", "<leader>Y", "\"+Y", opts)

-- Window management with <Space> prefix (mirrors Kitty ctrl-z spirit)
map("n", "<leader>u", "<C-w>v", opts)
map("n", "<leader>v", "<C-w>s", opts)
map("n", "<leader>h", "<C-w>h", opts)
map("n", "<leader>j", "<C-w>j", opts)
map("n", "<leader>k", "<C-w>k", opts)
map("n", "<leader>l", "<C-w>l", opts)
map("n", "<leader>w", "<C-w>c", opts)
map("n", "<leader>z", "<C-w>_ | <C-w>|", opts)

-- Window resize
map("n", "<leader><C-h>", "<C-w><", opts)
map("n", "<leader><C-l>", "<C-w>>", opts)
map("n", "<leader><C-j>", "<C-w>-", opts)
map("n", "<leader><C-k>", "<C-w>+", opts)

-- Equalize windows
map("n", "<leader>=", "<C-w>=", opts)

-- Buffer navigation
map("n", "<leader>b", "<cmd>bprevious<CR>", opts)
map("n", "<leader>a", "<cmd>bnext<CR>", opts)
