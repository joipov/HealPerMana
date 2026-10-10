local _, ns = ...

-- Reserved for a later locale overlay. enUS is the only file shipped in v1;
-- ns.RegisterLocale exists so a [AllowLoadTextLocale] file can drop in later
-- without changing call sites.
function ns.RegisterLocale(strings)
	if type(strings) ~= "table" then
		return
	end
	local L = ns.L
	for key, value in pairs(strings) do
		L[key] = value
	end
end
