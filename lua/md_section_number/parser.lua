local PairParser = {}
PairParser.__index = PairParser
PairParser.pairs = {}

function PairParser:add_pairs(startPair, endPair)
	table.insert(self, { startPair, endPair })
end

function PairParser:parse_pairs(line)
	-- todo
end

PairParser:add_pairs("```", "```")
PairParser:add_pairs("<!--", "-->")

return PairParser
