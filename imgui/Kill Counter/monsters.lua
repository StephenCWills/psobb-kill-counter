-- Author: Soleil Rojas (https://github.com/Solybum)
-- From: PSOBBMod-Addons (https://github.com/Solybum/PSOBBMod-Addons)
-- License: GPL-3.0 (https://github.com/Solybum/PSOBBMod-Addons/blob/master/LICENSE)

local m = {}

-- Standard enemy colors are white, rare enemies are yellow, bosses are red.
-- Minibosses are a less threatening red. 8)
-- Changing the second value to "false" makes the enemy not appear on the monster
-- reader.

-- Forest
m[1] = { 0xFFFFFFFF, false } -- Hildebear / Hildelt
m[2] = { 0xFFFFFF00, false } -- Hildeblue / Hildetorr
m[3] = { 0xFFFFFFFF, false } -- Mothmant / Mothvert
m[4] = { 0xFFFFFFFF, false } -- Monest / Mothvist
m[5] = { 0xFFFFFFFF, false } -- Rag Rappy / El Rappy
m[6] = { 0xFFFFFF00, false } -- Al Rappy / Pal Rappy
m[7] = { 0xFFFFFFFF, false } -- Savage Wolf / Gulgus
m[8] = { 0xFFFFFFFF, false } -- Barbarous Wolf / Gulgus-gue
m[9] = { 0xFFFFFFFF, false } -- Booma / Bartle
m[10] = { 0xFFFFFFFF, false } -- Gobooma / Barble
m[11] = { 0xFFFFFFFF, false } -- Gigobooma / Tollaw

-- Cave
m[12] = { 0xFFFFFFFF, false } -- Grass Assassin / Crimson Assassin
m[13] = { 0xFFFFFFFF, false } -- Poison Lily / Ob Lily
m[14] = { 0xFFFFFF00, false } -- Nar Lily / Mil Lily
m[15] = { 0xFFFFFFFF, false } -- Nano Dragon
m[16] = { 0xFFFFFFFF, false } -- Evil Shark / Vulmer
m[17] = { 0xFFFFFFFF, false } -- Pal Shark / Govulmer
m[18] = { 0xFFFFFFFF, false } -- Guil Shark / Melqueek
m[19] = { 0xFFFFFFFF, false } -- Pofuilly Slime
m[20] = { 0xFFFFFF00, false } -- Pouilly Slime
m[21] = { 0xFFFFFFFF, false } -- Pan Arms
m[22] = { 0xFFFFFFFF, false } -- Migium
m[23] = { 0xFFFFFFFF, false } -- Hidoom

-- Mine
m[24] = { 0xFFFFFFFF, false } -- Dubchic / Dubchich
m[25] = { 0xFFFFFFFF, false } -- Garanz / Baranz
m[26] = { 0xFFFFFFFF, false } -- Sinow Beat / Sinow Blue
m[27] = { 0xFFFFFFFF, false } -- Sinow Gold / Sinow Red
m[28] = { 0xFFFFFFFF, false } -- Canadine / Canabin
m[29] = { 0xFFFFFFFF, false } -- Canane / Canune
m[49] = { 0xFFFFFFFF, false } -- Dubwitch
m[50] = { 0xFFFFFFFF, false } -- Gillchic / Gillchich

-- Ruins
m[30] = { 0xFFFFFFFF, false } -- Delsaber
m[31] = { 0xFFFFFFFF, false } -- Chaos Sorcerer / Gran Sorcerer
m[32] = { 0xFFFFFFFF, false } -- Bee R / Gee R
m[33] = { 0xFFFFFFFF, false } -- Bee L / Gee L
m[34] = { 0xFFFFFFFF, false } -- Dark Gunner
m[35] = { 0xFFFFFFFF, false } -- Death Gunner
m[36] = { 0xFFFFFFFF, false } -- Dark Bringer
m[37] = { 0xFFFFFFFF, false } -- Indi Belra
m[38] = { 0xFFFFFFFF, false } -- Claw
m[39] = { 0xFFFFFFFF, false } -- Bulk
m[40] = { 0xFFFFFFFF, false } -- Bulclaw
m[41] = { 0xFFFFFFFF, false } -- Dimenian / Arlan
m[42] = { 0xFFFFFFFF, false } -- La Dimenian / Merlan
m[43] = { 0xFFFFFFFF, false } -- So Dimenian / Del-D

-- Episode 1 Bosses
m[44] = { 0xFFFF0000, false } -- Dragon / Sil Dragon
m[45] = { 0xFFFF0000, false } -- De Rol Le / Dal Ral Lie
m[46] = { 0xFFFF0000, false } -- Vol Opt / Vol Opt ver.2
m[47] = { 0xFFFF0000, false } -- Dark Falz

-- VR Temple	
m[51] = { 0xFFFFFF00, false } -- Love Rappy
m[73] = { 0xFFFF0000, false } -- Barba Ray
m[74] = { 0xFFFFFFFF, false } -- Pig Ray
m[75] = { 0xFFFFFFFF, false } -- Ul Ray
m[79] = { 0xFFFFFFFF, false } -- St. Rappy
m[80] = { 0xFFFFFF00, false } -- Hallo Rappy
m[81] = { 0xFFFFFF00, false } -- Egg Rappy

-- VR Spaceship
m[76] = { 0xFFFF0000, false } -- Gol Dragon

-- Central Control Area
m[52] = { 0xFFFFFFFF, false } -- Merillia
m[53] = { 0xFFFFFFFF, false } -- Meriltas
m[54] = { 0xFFFFFFFF, false } -- Gee
m[55] = { 0xFFFF8080, false } -- Gi Gue
m[56] = { 0xFFFF8080, false } -- Mericarol
m[57] = { 0xFFFF8080, false } -- Merikle
m[58] = { 0xFFFF8080, false } -- Mericus
m[59] = { 0xFFFFFFFF, false } -- Ul Gibbon
m[60] = { 0xFFFFFFFF, false } -- Zol Gibbon
m[61] = { 0xFFFF8080, false } -- Gibbles
m[62] = { 0xFFFFFFFF, false } -- Sinow Berill
m[63] = { 0xFFFFFFFF, false } -- Sinow Spigell
m[77] = { 0xFFFF0000, false } -- Gal Gryphon
m[82] = { 0xFFFFFFFF, false } -- Ill Gill
m[83] = { 0xFFFFFFFF, false } -- Del Lily
m[84] = { 0xFFFF8080, false } -- Epsilon
m[87] = { 0xFFFFFFFF, false } -- Epsigard

-- Seabed
m[64] = { 0xFFFFFFFF, false } -- Dolmolm
m[65] = { 0xFFFFFFFF, false } -- Dolmdarl
m[66] = { 0xFFFFFFFF, false } -- Morfos
m[67] = { 0xFFFFFFFF, false } -- Recobox
m[68] = { 0xFFFFFFFF, false } -- Recon
m[69] = { 0xFFFFFFFF, false } -- Sinow Zoa
m[70] = { 0xFFFFFFFF, false } -- Sinow Zele
m[71] = { 0xFFFFFFFF, false } -- Deldepth
m[72] = { 0xFFFFFFFF, false } -- Delbiter
m[78] = { 0xFFFF0000, false } -- Olga Flow
m[85] = { 0xFFFFFFFF, false } -- Gael	
m[86] = { 0xFFFFFFFF, false } -- Giel

-- Crater
m[88] = { 0xFFFFFFFF, true } -- Astark
m[89] = { 0xFFFFFFFF, false } -- Yowie
m[90] = { 0xFFFFFFFF, false } -- Satellite Lizard
m[94] = { 0xFFFFFFFF, false } -- Zu
m[95] = { 0xFFFFFF00, false } -- Pazuzu
m[96] = { 0xFFFFFFFF, false } -- Boota
m[97] = { 0xFFFFFFFF, false } -- Za Boota
m[98] = { 0xFFFFFFFF, false } -- Ba Boota
m[99] = { 0xFFFFFFFF, false } -- Dorphon
m[100] = { 0xFFFFFFFF, false } -- Dorphon Eclair
m[104] = { 0xFFFFFFFF, false } -- Sand Rappy
m[105] = { 0xFFFFFF00, false } -- Del Rappy

-- Desert
m[91] = { 0xFFFFFFFF, false } -- Merissa A
m[92] = { 0xFFFFFF00, false } -- Merissa AA
m[93] = { 0xFFFFFFFF, false } -- Girtablulu
m[101] = { 0xFFFFFFFF, false } -- Goran
m[102] = { 0xFFFFFFFF, false } -- Goran Detonator
m[103] = { 0xFFFFFFFF, false } -- Pyro Goran
m[106] = { 0xFFFF0000, false } -- Saint-Milion
m[107] = { 0xFFFF0000, false } -- Shambertin
m[108] = { 0xFFFF8000, false } -- Kondrieu

-- Other
m[48] = { 0xFFFFFFFF, false } -- Container

return 
{
    m = m,
}
