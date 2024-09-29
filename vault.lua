local fn = vim.fn
local api = vim.api

local function readchar()
	local ch = fn.getchar()
	ch = fn.nr2char(ch)
	return ch
end

local function setpos(position)
	local lnum = position[1]
	local col = position[2]
	fn.setcursorcharpos(lnum, col)
end

local function copybuf(buf)
	local new = {}
	for i = 1, #buf do
		new[i] = buf[i]
	end
	return new
end

-- TODO: is it a good way to label things?
-- Why not just highlight that position
-- TODO: better safe labels which are easy to type
-- TODO: more labels is needed when more texts in the screen
local safe_labels = {
	"s",
	"f",
	"n",
	"u",
	"t",
	"/",
	"S",
	"F",
	"N",
	"L",
	"H",
	"M",
	"U",
	"G",
	"T",
	"Z",
	"?",
	"1",
	"2",
	"3",
	"4",
	"5",
	"6",
	"7",
	"8",
	"9",
	"0",
	"-",
	"=",
}

-- TODO: jump to special characters like `()[]{},`
-- TODO: jump back instead only jump forward
local function vault()
	local mode = fn.mode(1)

	local sch = readchar()

	-- NOTE: simply exit when user enter a special key
	-- like ESCAPE
	if sch == "^[" then
		return
	end

	local positions = {}
	-- NOTE:
	-- W: don't wrap at the end of file
	local sflag = "W"
	local startline = fn.line("w0")
	local stopline = fn.line("w$")

	-- TODO: save current position
	-- let save_cursor = getcurpos()
	-- MoveTheCursorAround
	-- call setpos('.', save_cursor)
	local cpos = fn.getcursorcharpos(0)

	while true do
		-- TODO: it may not work with wide charaters
		local pos = fn.searchpos(sch, sflag, stopline)
		if pos[1] == 0 and pos[2] == 0 then
			break
		end
		table.insert(positions, pos)
	end

	-- NOTE: if no match, simply stop
	if #positions == 0 then
		return
	end

	-- NOTE: move cursor to first match
	local fm = positions[1]
	if not mode ~= "no" then
		setpos(fm)
	end

	-- NOTE: if there is only one match, move the cursor and exit
	if #positions == 1 then
		return
	end

	local jlist = {}

	local ns_id = api.nvim_create_namespace("vault.nvim")

	-- NOTE: label non-first matches
	for i = 2, #positions do
		local lb = safe_labels[i - 1]
		-- TODO: handle situation where
		-- number of labels is less than number of matches
		if lb == nil then
			break
		end
		local pos = positions[i]
		local hpos = {}
		jlist[lb] = pos

		-- NOTE: draw labels near positions, 2 char after
		local lnum = pos[1] -- NOTE: one-based
		table.insert(hpos, lnum)
		local line = lnum - 1
		local col = pos[2] - 1 -- NOTE: one-based

		-- NOTE: use extmarks instead of set buffer content
		-- note: highlight and label non-first matches
		api.nvim_buf_set_extmark(
			0,
			ns_id,
			line,
			col,
			{ virt_text = { { lb, "VaultNvim" } }, virt_text_pos = "overlay" }
		)
	end

	-- TODO: optional: shade other contents

	-- NOTE: redraw
	vim.cmd("redraw")

	-- NOTE: read user input
	local lch = readchar()

	-- NOTE: remove highlight and marks
	api.nvim_buf_clear_namespace(0, ns_id, 0, -1)

	-- NOTE: move cursor to matching label
	if jlist[lch] then
		local um = jlist[lch]
		setpos(um)
	end
end

local function setup()
	-- TODO: setup highlight group
	api.nvim_create_namespace("vault.nvim")

	vim.cmd("highlight VaultNvim ctermbg=red guibg=red gui=italic,bold")

	vim.keymap.set({ "n", "o", "x" }, "s", vault)
end

setup()
