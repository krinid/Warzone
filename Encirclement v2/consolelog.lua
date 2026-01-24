-- TO PRINT A TABLE 

local function p(obj, p2)
	function tprint(tbl, indent)
		if type(tbl) ~= 'table' then
			return tostring(tbl);
		end

		if not indent then
			indent = 0;
		end

		-- arrays dont have a proxy type
		if numKeys(tbl) ~= #tbl and tbl.proxyType then
			return DumpProxy(tbl, indent + 2);
		end

		local toprint = '{\r\n';
		indent = indent + 2;

		for k, v in pairs(tbl) do
			toprint = toprint .. string.rep(' ', indent)

			if type(k) == 'number' then
				toprint = toprint .. '[' .. k .. '] = ';
			elseif type(k) == 'string' then
				toprint = toprint  .. k ..  ' = ';
			end

			if type(v) == 'table' then
				if v.__proxyID then
					toprint = toprint .. DumpProxy(v, indent + 2) .. ',\r\n';
				else
					toprint = toprint .. tprint(v, indent + 2) .. ',\r\n';
				end
			elseif type(v) == 'string' then
				toprint = toprint .. '"' .. v .. '",\r\n';
			else
				toprint = toprint .. tostring(v) .. ',\r\n';
			end
		end

		toprint = toprint .. string.rep(' ', indent - 2) .. '}';

		return toprint;
	end

	function DumpProxy(obj, indent)
		if type(obj) ~= 'table' then
			return tostring(obj);
		end

		local str = '{';

		for _, key in pairs(obj.readableKeys) do
			if key ~= 'readableKeys' then
				str = str .. '\r\n' .. string.rep(' ', indent);
				if type(key) == 'string' then
					str = str .. key;
				else
					str = str .. '[' .. key .. ']';
				end

				str = str .. ' = ';

				local value = obj[key];

				if type(value) == 'table' then
					str = str .. tprint(value, indent);
				elseif type(value) == 'string' then
					str = str .. '"' .. value .. '"';
				else
					str = str .. tostring(value);
				end

				str = str .. ',';
			end
		end

		return str .. '\r\n' .. string.rep(' ', indent - 2) .. '}';
	end

	if type(obj) == 'table' then
		return tprint(obj, p2);
	else
		return tostring(obj);
	end
end

function tblprint(tbl)
	print(p(tbl));
end

function numKeys(tbl)
	local n = 0;

	for k, v in pairs(tbl) do
		n = n + 1;
	end

	return n;
end


--      tblprint(...)