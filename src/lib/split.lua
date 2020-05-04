-- split: Return a table with every part of string at the char supplied
function split(string, delim)
	local stringTable = {}
	local lastIndex = 1
	for i=1,string.len(string) do
		local currentlyContains = true
		for j=1,string.len(delim) do
			if (string.sub(string, i+j-1, i+j-1) ~= string.sub(delim, j, j)) then
				currentlyContains = false
			end
		end
		if (currentlyContains and string.len(string.sub(string, lastIndex, i-1)) > 0) then
			stringTable[#stringTable+1] = string.sub(string, lastIndex, i-1)
			lastIndex = i+string.len(delim)
		end
	end
	stringTable[#stringTable+1] = string.sub(string, lastIndex, #string)
	return stringTable
end

