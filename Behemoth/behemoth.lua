--contains common functions used through Behemoth mod to calculate power & power factor for Behemoths

function getBehemothPowerFactor (behemothPower)
	return (math.min (behemothPower/100, 0.1) + math.min (behemothPower/1000, 0.1) + math.min (behemothPower/10000, 0.1)); --max factor of 0.3
end

function getBehemothPower (goldSpent)
	local power = 0;
	if (goldSpent <= 0) then return 0; end
	--if (goldSpent >= 1 and goldSpent <=50) then return (goldSpent/50)*goldSpent;
	power = power + math.min ((goldSpent/50)*goldSpent, 25);
	if (goldSpent >=50) then power = power + math.min ((goldSpent/100)*goldSpent, 100); end
	if (goldSpent >= 100) then power = power + math.min ((goldSpent/500)*goldSpent, 500); end
	if (goldSpent >= 500) then power = power + math.min ((goldSpent/1000)*goldSpent, 1000); end
	if (goldSpent >= 1000) then power = power + math.min ((goldSpent/5000)*goldSpent, 5000); end
	if (goldSpent >=5000) then power = power + (goldSpent/10000)*goldSpent; end
	power = math.floor (math.max (1, power)+0.5);

	power = 0;
	--[[power = power + math.min ((goldSpent/75)*goldSpent, 50);
	power = power + math.min ((goldSpent/150)*goldSpent, 100);
	power = power + math.min ((goldSpent/600)*goldSpent, 500);
	power = power + math.min ((goldSpent/1200)*goldSpent, 1000);
	power = power + math.min ((goldSpent/6000)*goldSpent, 5000);
	power = power + (goldSpent/10000)*goldSpent;
	power = math.floor (math.max (1, power)+0.5);]]

	local a = 50;  --while goldSpent < a, power < goldSpent
	local b = 100; --while a < goldSpent < b, power >= b and grows slowly/linearly
	local c = 1000; --while b < goldSpent < c, power grows faster/quadratically
	               --while c < goldSpent, power grows even faster/exponentially
	--power = math.min ((goldSpent/a)*goldSpent, a) + math.max(0, (goldSpent - a) * 1.5) + math.max(0, math.max (0, (goldSpent - b))^1.5 - (b - a) * 0.5) + math.max(0, math.exp(goldSpent - c) - (c - b)^2);
	--print  (goldSpent ..", "..math.min ((goldSpent/a)*goldSpent, a) ..", ".. math.max(0, (goldSpent - a) * 1.5) ..", ".. math.max(0, math.max (0, (goldSpent - b))^1.5 - (b - a) * 0.5) ..", ".. math.max(0, math.exp(goldSpent - c) - (c - b)^2));

	power = math.min ((goldSpent/a)*goldSpent, a) + math.max(0, (goldSpent - a) * 1.5) + math.max(0, ((goldSpent - b)) * 1.0)^1 + math.max(0, math.max (0, (goldSpent - c))^1.2 - (c - b) * 0.5);
	print  (goldSpent ..", ".. math.min ((goldSpent/a)*goldSpent, a) ..", ".. math.max(0, (goldSpent - a) * 1.5) ..", ".. math.max(0, ((goldSpent - b)) * 1.0)^1 ..", ".. math.max(0, math.max (0, (goldSpent - c))^1.2 - (c - b) * 0.5));

	return power;
end