ENT.ChanceCards = {
	{"Advanced to Boardwalk", space =},
	{"Advance to Go (Collect $200)", go = true, space =},
	{"Advance to Illinois Avenue. If you pass Go, collect $200", go = true, space =},
	{"Advance to St. Charles Place. If you pass Go, collect $200", go = true, space =},
	{"Advance to the nearest Railroad. If unowned, you may buy it. If owned, pay owner twice the rent", space =, railroad = true,},
	{"Advance to the nearest Utility. If unowned, you may buy it. If owned, throw dice and pay owner a total ten times amount thrown.", utility = true,}
	{"Bank pays you dividend of $50", money = 50},
	{"Get out of Jail Free Card", goj = true},
	{"Go directly to Jail.", jail = true},
	{"Speeding Fine. Pay $15", money = -15},
	{"D.U.I. Fine. Pay $50", money = -50}
	{"Holiday fund matures. Collect $100", money = 100},
	{"You have been elected Chairman of the Board. Pay each player $50", function() end},
	{"Your building loan matures. Collect $150", money = 150},
	{"Make general repairs on all your property. For each house pay $25. For each hotel pay $100.", repairs = {25, 100}},
	{"Take a trip to Reading Railroad. If you pass Go, collect $200", go = true, space =}
}

ENT.CommunityCards = {
	{"Advance to Go (Collect $200)", go = true, space =},
	{"Bank error in your favour. Collect $200", money = 200},
	{"Doctor's fee. Pay $50", money = -50},
	{"From sale of stock you get $50", money = 50},
	{"Get out of Jail Free Card", goj = true},
	{"Go directly to Jail.", jail = true},
	{"Holiday fund matures. Receive $100", money = 100},
	{"Income tax refund. Collect $20", money = 20},
	{"It is your birthday. Collect $10 from every player"},
	{"Life insurance matures. Collect $100", money = 100},
	{"Pay hospital fees of $100", money = -100},
	{"Pay school fees of $50", money = -50},
	{"Pay $25 consultancy fee", money = -25},
	{"You are assessed for street repairs. $40 per house. $115 per hotel", repairs = {40, 115}},
	{"You have won second prize in a beauty contest. Collect $10", money = 10},
	{"You inherit $100. Congratulations?", money = 100}
	{"Pay your insurance premium $50", money = -50}
}