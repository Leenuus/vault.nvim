local fn = vim.fn
local api = vim.api

local function restore_opts(opts)
	opts = opts
		or {
			scrolloff = 0,
			modified = false,
			modifiable = true,
			readonly = false,
			spell = false,
			virtualedit = "",
		}
	local o_opts = {
		scrolloff = vim.o["scrolloff"],
		modified = vim.o["modified"],
		modifiable = vim.o["modifiable"],
		readonly = vim.o["readonly"],
		spell = vim.o["spell"],
		virtualedit = vim.o["virtualedit"],
	}
	for k, v in pairs(opts) do
		vim.opt_local[k] = v
	end
	return o_opts
end

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

	local old_opts = restore_opts()

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
	local buf = api.nvim_buf_get_lines(0, startline - 1, stopline, false)

	local newbuf = copybuf(buf)
	local hpositions = {}
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
		local lnum = pos[1]
		table.insert(hpos, lnum)
		local col = pos[2] -- NOTE: one-based
		local cline = newbuf[lnum]
		cline = vim.split(cline, "")

		if cline[col + 2] then
			cline[col + 2] = lb
			table.insert(hpos, col + 2)
		else
			table.insert(cline, lb)
			table.insert(hpos, #cline)
		end
		cline = fn.join(cline, "")
		newbuf[lnum] = cline -- NOTE: build marked buf
		table.insert(hpositions, hpos) -- NOTE: build highlight pos
	end

	-- TODO: use extmarks instead of set buffer content
	-- NOTE: set lines and force redraw
	api.nvim_buf_set_lines(0, startline - 1, stopline, false, newbuf)

	-- NOTE: highlight and label non-first matches

	local hid = fn.matchaddpos("VaultNvim", hpositions)

	vim.cmd("redraw")

	-- TODO: optional: shade other contents

	-- NOTE: read user input
	local lch = readchar()

	-- NOTE: restore line
	api.nvim_buf_set_lines(0, startline - 1, stopline, false, buf)

	-- NOTE: remove highlight
	fn.matchdelete(hid)

	-- NOTE: restore opts
	restore_opts(old_opts)

	-- NOTE: move cursor to matching label
	if jlist[lch] then
		local um = jlist[lch]
		setpos(um)
	end
end

local function setup()
	-- NOTE: setup highlight group
	vim.cmd("highlight VaultNvim ctermbg=red guibg=red gui=italic,bold")

	vim.keymap.set("n", "s", vault)
	vim.keymap.set("x", "s", vault)
	vim.keymap.set("o", "s", vault)
end

setup()
