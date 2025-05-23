--contains common functions used through Behemoth mod to calculate power & power factor for Behemoths

--(global variables) default values for gold levels to scale Behemoth power with gold spent
intGoldLevel1_default = 1000;
intGoldLevel2_default = 2000;
intGoldLevel3_default = 5000;
boolBehemothInvulnerableToNeutrals_default = true;
intStrengthAgainstNeutrals_default = 2.0;

--calculate the Behemoth power scaling factor; this multiplier will be used to calculate several of the Behemoth's stats during creation (or for presenting the would-be stats during purchase phase)
--some stats will take Behemoth power and multiply by the scaling factor, others may add/subtract to/from it, to generate appropriate stats
function getBehemothPowerFactor (behemothPower)
	--set default values if Mod.Settings are nil (ie: a template that was created before these values are implemented)
	local intGoldLevel1 = Mod.Settings.BehemothGoldLevel1 or intGoldLevel1_default; --while goldSpent < a, power < goldSpent but increases linearly
	local intGoldLevel2 = Mod.Settings.BehemothGoldLevel2 or intGoldLevel2_default; --while a < goldSpent < b, power >= b and grows slowly/linearly
	local intGoldLevel3 = Mod.Settings.BehemothGoldLevel3 or intGoldLevel3_default; --while b < goldSpent < c, power grows faster/quadratically
	return (math.min ((behemothPower/intGoldLevel1)/10, 0.1) + math.min ((behemothPower/intGoldLevel2)/10, 0.1) + math.min ((behemothPower/intGoldLevel3)/10, 0.1)); --max factor of 0.1 per component for total max of 0.3
	--this factor will be multiplied by some Behemoth stats, added for others, increased then multiplied for others, etc
end

--calculate the Behemoth Power, which forms the basis for all Behemoth stats; the scaling factor will then be used to create differences among the various stats as appropriate
function getBehemothPower (goldSpent)
	local power = 0;
	if (goldSpent <= 0) then return 0; end

	--set default values if Mod.Settings are nil (ie: a template that was created before these values are implemented)
	local a = Mod.Settings.BehemothGoldLevel1 or intGoldLevel1_default; --while goldSpent < a, power < goldSpent but increases linearly
	local b = Mod.Settings.BehemothGoldLevel2 or intGoldLevel2_default; --while a < goldSpent < b, power >= b and grows slowly/linearly
	local c = Mod.Settings.BehemothGoldLevel3 or intGoldLevel3_default; --while b < goldSpent < c, power grows faster/quadratically
	                                                                    --while goldSpent > c, power grows even faster/exponentially

	-- --if (goldSpent >= 1 and goldSpent <=50) then return (goldSpent/50)*goldSpent;
	-- power = power + math.min ((goldSpent/50)*goldSpent, 25);
	-- if (goldSpent >=50) then power = power + math.min ((goldSpent/100)*goldSpent, 100); end
	-- if (goldSpent >= 100) then power = power + math.min ((goldSpent/500)*goldSpent, 500); end
	-- if (goldSpent >= 500) then power = power + math.min ((goldSpent/1000)*goldSpent, 1000); end
	-- if (goldSpent >= 1000) then power = power + math.min ((goldSpent/5000)*goldSpent, 5000); end
	-- if (goldSpent >=5000) then power = power + (goldSpent/10000)*goldSpent; end
	-- power = math.floor (math.max (1, power)+0.5);

	-- power = 0;
	--[[power = power + math.min ((goldSpent/75)*goldSpent, 50);
	power = power + math.min ((goldSpent/150)*goldSpent, 100);
	power = power + math.min ((goldSpent/600)*goldSpent, 500);
	power = power + math.min ((goldSpent/1200)*goldSpent, 1000);
	power = power + math.min ((goldSpent/6000)*goldSpent, 5000);
	power = power + (goldSpent/10000)*goldSpent;
	power = math.floor (math.max (1, power)+0.5);]]

	-- local a = 50;  --while goldSpent < a, power < goldSpent
	-- local b = 100; --while a < goldSpent < b, power >= b and grows slowly/linearly
	-- local c = 1000; --while b < goldSpent < c, power grows faster/quadratically
	               --while c < goldSpent, power grows even faster/exponentially
	--power = math.min ((goldSpent/a)*goldSpent, a) + math.max(0, (goldSpent - a) * 1.5) + math.max(0, math.max (0, (goldSpent - b))^1.5 - (b - a) * 0.5) + math.max(0, math.exp(goldSpent - c) - (c - b)^2);
	--print  (goldSpent ..", "..math.min ((goldSpent/a)*goldSpent, a) ..", ".. math.max(0, (goldSpent - a) * 1.5) ..", ".. math.max(0, math.max (0, (goldSpent - b))^1.5 - (b - a) * 0.5) ..", ".. math.max(0, math.exp(goldSpent - c) - (c - b)^2));

	power = math.min ((goldSpent/a)*goldSpent, a) + math.max(0, (goldSpent - a) * 1.5) + math.max(0, ((goldSpent - b)) * 1.0)^1 + math.max(0, math.max (0, (goldSpent - c))^1.2 - (c - b) * 0.5);
	print  (goldSpent ..", ".. math.min ((goldSpent/a)*goldSpent, a) ..", ".. math.max(0, (goldSpent - a) * 1.5) ..", ".. math.max(0, ((goldSpent - b)) * 1.0)^1 ..", ".. math.max(0, math.max (0, (goldSpent - c))^1.2 - (c - b) * 0.5));

	return power;
end