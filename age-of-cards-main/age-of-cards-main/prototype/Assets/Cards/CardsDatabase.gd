
# Unitinfo = [Type, Attack, Retaliation, Health, Cost, Name, Melee or Ranged, Special Text]
# Eventinfo = [Type, Cost, Effect]
enum {Footman, Archer, SquadLeader, Warrior, Guardian, Knight, Mercenary, Spearman, Mentor, Trebuchet}

const DATA = {
	Footman : 
		["Units", 1, 1, 2, 1, "Footman", "Melee"],
	Archer :
		["Units", 2, 1, 3, 2, "Archer", "Ranged,\nImmune to\nRetaliation"],
	SquadLeader :
		["Units", 2, 2, 3, 3, "Squad Leader", "Melee,\nGive all friendly\n+1 Attack and \nRetaliation"],
	Warrior :
		["Units", 4, 0, 2, 3, "Rogue", "Melee,\nImmune to\nRetaliation"],
	Guardian :
		["Units", 1, 3, 6, 3, "Guardian", "Melee,\nProtector - stops the unit\nbehind it\nbeing attacked"],
	Knight : 
		["Units", 2, 3, 6, 4, "Knight", "Melee"],
	Mercenary :
		["Units", 2, 2, 0, 2, "Mercenary", "Melee,\nAlways Retaliates\nReturn to Supply when damaged\nor at start of next turn\nAfter played, increase\ncost by 1"],
	Spearman :
		["Units", 2, 2, 5, 3, "Spearman", "Melee or Ranged"],
	Mentor :
		["Units", 3, 0, 1, 2, "Mentor", "Melee,\nWhen played give\nfriendly unit +2 Attack\nand Retaliation"],
	Trebuchet :
		["Events", 4, "Deal 6 damage\nto a unit"],
	}
