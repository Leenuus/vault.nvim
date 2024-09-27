local fn = vim.fn

local ch = fn.getchar()
ch = fn.nr2char(ch)
print(vim.inspect(ch))

-- local pos = fn.searchpos(ch)
-- if pos[1] == 0 and pos[2] == 0 then
-- 	print("good")
-- end

local positions = {}
-- NOTE:
-- W: don't wrap at the end of file
local sflag = "W"
local stopline = fn.line("w$")

-- TODO: save current position
local cpos = {}

while true do
	local pos = fn.searchpos(ch, sflag, stopline)
	if pos[1] == 0 and pos[2] == 0 then
		break
	end
	table.insert(positions, pos)
end

print(vim.inspect(positions))


-- TODO: if no match, simply stop


-- TODO: move cursor to first match
local cpos = {}


-- TODO: label non-first matches

-- TODO: optional: highlight non-first matches

-- TODO: read user input, move cursor to matching label
