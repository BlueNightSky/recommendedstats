-- GENERATED 2026-10-15 - do not hand-edit
if not (C_Seasons and C_Seasons.GetActiveSeason and C_Seasons.GetActiveSeason() == ((Enum and Enum.SeasonID and Enum.SeasonID.SeasonOfDiscovery) or 2)) then return end
RecommendedStatsData_Talents = {
    ["DRUID_BALANCE_RAID"] = {
        ["n"] = 20,
        ["builds"] = {
            {
                ["split"] = {
                    38,
                    0,
                    13,
                },
                ["pct"] = 40,
            },
            {
                ["split"] = {
                    37,
                    0,
                    14,
                },
                ["pct"] = 30,
            },
            {
                ["split"] = {
                    40,
                    0,
                    11,
                },
                ["pct"] = 25,
            },
        },
        ["median"] = {
            38,
            0,
            13,
        },
    },
    ["DRUID_FERAL_RAID"] = {
        ["n"] = 20,
        ["builds"] = {
            {
                ["split"] = {
                    14,
                    32,
                    5,
                },
                ["pct"] = 100,
            },
        },
        ["median"] = {
            14,
            32,
            5,
        },
    },
    ["DRUID_GUARDIAN_RAID"] = {
        ["n"] = 20,
        ["builds"] = {
            {
                ["split"] = {
                    11,
                    33,
                    7,
                },
                ["pct"] = 65,
            },
            {
                ["split"] = {
                    11,
                    40,
                    0,
                },
                ["pct"] = 20,
            },
            {
                ["split"] = {
                    14,
                    32,
                    5,
                },
                ["pct"] = 10,
            },
        },
        ["median"] = {
            11,
            33,
            7,
        },
    },
    ["DRUID_RESTORATION_RAID"] = {
        ["n"] = 20,
        ["builds"] = {
            {
                ["split"] = {
                    12,
                    0,
                    39,
                },
                ["pct"] = 30,
            },
            {
                ["split"] = {
                    11,
                    0,
                    40,
                },
                ["pct"] = 30,
            },
            {
                ["split"] = {
                    14,
                    0,
                    37,
                },
                ["pct"] = 10,
            },
        },
        ["median"] = {
            12,
            0,
            39,
        },
    },
    ["HUNTER_BEASTMASTERY_RAID"] = {
        ["n"] = 14,
        ["builds"] = {
            {
                ["split"] = {
                    31,
                    20,
                    0,
                },
                ["pct"] = 50,
            },
            {
                ["split"] = {
                    28,
                    20,
                    3,
                },
                ["pct"] = 14,
            },
            {
                ["split"] = {
                    40,
                    11,
                    0,
                },
                ["pct"] = 7,
            },
        },
        ["median"] = {
            31,
            20,
            0,
        },
    },
    ["HUNTER_MARKSMANSHIP_RAID"] = {
        ["n"] = 20,
        ["builds"] = {
            {
                ["split"] = {
                    17,
                    31,
                    3,
                },
                ["pct"] = 75,
            },
            {
                ["split"] = {
                    14,
                    31,
                    6,
                },
                ["pct"] = 10,
            },
            {
                ["split"] = {
                    5,
                    38,
                    8,
                },
                ["pct"] = 5,
            },
        },
        ["median"] = {
            17,
            31,
            3,
        },
    },
    ["HUNTER_SURVIVAL_RAID"] = {
        ["n"] = 20,
        ["builds"] = {
            {
                ["split"] = {
                    0,
                    21,
                    30,
                },
                ["pct"] = 35,
            },
            {
                ["split"] = {
                    1,
                    20,
                    30,
                },
                ["pct"] = 30,
            },
            {
                ["split"] = {
                    0,
                    20,
                    31,
                },
                ["pct"] = 30,
            },
        },
        ["median"] = {
            0,
            20,
            30,
        },
    },
    ["MAGE_ARCANE_RAID"] = {
        ["n"] = 16,
        ["builds"] = {
            {
                ["split"] = {
                    31,
                    10,
                    10,
                },
                ["pct"] = 19,
            },
            {
                ["split"] = {
                    31,
                    0,
                    20,
                },
                ["pct"] = 13,
            },
            {
                ["split"] = {
                    36,
                    0,
                    15,
                },
                ["pct"] = 13,
            },
        },
        ["median"] = {
            36,
            0,
            10,
        },
    },
    ["MAGE_FIRE_RAID"] = {
        ["n"] = 20,
        ["builds"] = {
            {
                ["split"] = {
                    2,
                    32,
                    17,
                },
                ["pct"] = 30,
            },
            {
                ["split"] = {
                    3,
                    34,
                    14,
                },
                ["pct"] = 20,
            },
            {
                ["split"] = {
                    0,
                    34,
                    17,
                },
                ["pct"] = 10,
            },
        },
        ["median"] = {
            2,
            34,
            15,
        },
    },
    ["MAGE_FROST_RAID"] = {
        ["n"] = 20,
        ["builds"] = {
            {
                ["split"] = {
                    0,
                    23,
                    28,
                },
                ["pct"] = 40,
            },
            {
                ["split"] = {
                    21,
                    0,
                    30,
                },
                ["pct"] = 20,
            },
            {
                ["split"] = {
                    0,
                    22,
                    29,
                },
                ["pct"] = 15,
            },
        },
        ["median"] = {
            0,
            22,
            29,
        },
    },
    ["PALADIN_HOLY_RAID"] = {
        ["n"] = 20,
        ["builds"] = {
            {
                ["split"] = {
                    32,
                    7,
                    12,
                },
                ["pct"] = 70,
            },
            {
                ["split"] = {
                    32,
                    19,
                    0,
                },
                ["pct"] = 15,
            },
            {
                ["split"] = {
                    35,
                    0,
                    16,
                },
                ["pct"] = 10,
            },
        },
        ["median"] = {
            32,
            7,
            12,
        },
    },
    ["PALADIN_RETRIBUTION_RAID"] = {
        ["n"] = 30,
        ["builds"] = {
            {
                ["split"] = {
                    11,
                    10,
                    30,
                },
                ["pct"] = 20,
            },
            {
                ["split"] = {
                    11,
                    8,
                    32,
                },
                ["pct"] = 20,
            },
            {
                ["split"] = {
                    13,
                    8,
                    30,
                },
                ["pct"] = 17,
            },
        },
        ["median"] = {
            11,
            8,
            30,
        },
    },
    ["PALADIN_PROTECTION_RAID"] = {
        ["n"] = 10,
        ["builds"] = {
            {
                ["split"] = {
                    0,
                    33,
                    18,
                },
                ["pct"] = 50,
            },
            {
                ["split"] = {
                    1,
                    32,
                    18,
                },
                ["pct"] = 20,
            },
            {
                ["split"] = {
                    2,
                    31,
                    18,
                },
                ["pct"] = 20,
            },
        },
        ["median"] = {
            0,
            33,
            18,
        },
    },
    ["PRIEST_DISCIPLINE_RAID"] = {
        ["n"] = 20,
        ["builds"] = {
            {
                ["split"] = {
                    31,
                    20,
                    0,
                },
                ["pct"] = 85,
            },
            {
                ["split"] = {
                    30,
                    21,
                    0,
                },
                ["pct"] = 5,
            },
            {
                ["split"] = {
                    33,
                    18,
                    0,
                },
                ["pct"] = 5,
            },
        },
        ["median"] = {
            31,
            20,
            0,
        },
    },
    ["PRIEST_HOLY_RAID"] = {
        ["n"] = 20,
        ["builds"] = {
            {
                ["split"] = {
                    21,
                    30,
                    0,
                },
                ["pct"] = 90,
            },
            {
                ["split"] = {
                    18,
                    33,
                    0,
                },
                ["pct"] = 5,
            },
            {
                ["split"] = {
                    20,
                    31,
                    0,
                },
                ["pct"] = 5,
            },
        },
        ["median"] = {
            21,
            30,
            0,
        },
    },
    ["PRIEST_SHADOW_RAID"] = {
        ["n"] = 20,
        ["builds"] = {
            {
                ["split"] = {
                    13,
                    0,
                    38,
                },
                ["pct"] = 90,
            },
            {
                ["split"] = {
                    11,
                    0,
                    40,
                },
                ["pct"] = 5,
            },
            {
                ["split"] = {
                    14,
                    0,
                    37,
                },
                ["pct"] = 5,
            },
        },
        ["median"] = {
            13,
            0,
            38,
        },
    },
    ["ROGUE_ASSASSINATION_RAID"] = {
        ["n"] = 20,
        ["builds"] = {
            {
                ["split"] = {
                    30,
                    21,
                    0,
                },
                ["pct"] = 75,
            },
            {
                ["split"] = {
                    31,
                    8,
                    12,
                },
                ["pct"] = 15,
            },
            {
                ["split"] = {
                    25,
                    8,
                    18,
                },
                ["pct"] = 5,
            },
        },
        ["median"] = {
            30,
            21,
            0,
        },
    },
    ["ROGUE_COMBAT_RAID"] = {
        ["n"] = 20,
        ["builds"] = {
            {
                ["split"] = {
                    15,
                    31,
                    5,
                },
                ["pct"] = 20,
            },
            {
                ["split"] = {
                    25,
                    26,
                    0,
                },
                ["pct"] = 20,
            },
            {
                ["split"] = {
                    19,
                    27,
                    5,
                },
                ["pct"] = 10,
            },
        },
        ["median"] = {
            20,
            28,
            5,
        },
    },
    ["ROGUE_SUBTLETY_RAID"] = {
        ["n"] = 20,
        ["builds"] = {
            {
                ["split"] = {
                    16,
                    8,
                    27,
                },
                ["pct"] = 45,
            },
            {
                ["split"] = {
                    21,
                    8,
                    22,
                },
                ["pct"] = 25,
            },
            {
                ["split"] = {
                    18,
                    12,
                    21,
                },
                ["pct"] = 10,
            },
        },
        ["median"] = {
            18,
            8,
            22,
        },
    },
    ["SHAMAN_ELEMENTAL_RAID"] = {
        ["n"] = 20,
        ["builds"] = {
            {
                ["split"] = {
                    31,
                    0,
                    20,
                },
                ["pct"] = 95,
            },
            {
                ["split"] = {
                    30,
                    0,
                    21,
                },
                ["pct"] = 5,
            },
        },
        ["median"] = {
            31,
            0,
            20,
        },
    },
    ["SHAMAN_ENHANCEMENT_RAID"] = {
        ["n"] = 20,
        ["builds"] = {
            {
                ["split"] = {
                    20,
                    31,
                    0,
                },
                ["pct"] = 60,
            },
            {
                ["split"] = {
                    19,
                    32,
                    0,
                },
                ["pct"] = 35,
            },
            {
                ["split"] = {
                    18,
                    33,
                    0,
                },
                ["pct"] = 5,
            },
        },
        ["median"] = {
            20,
            31,
            0,
        },
    },
    ["SHAMAN_RESTORATION_RAID"] = {
        ["n"] = 20,
        ["builds"] = {
            {
                ["split"] = {
                    8,
                    12,
                    31,
                },
                ["pct"] = 20,
            },
            {
                ["split"] = {
                    0,
                    12,
                    39,
                },
                ["pct"] = 20,
            },
            {
                ["split"] = {
                    0,
                    5,
                    46,
                },
                ["pct"] = 20,
            },
        },
        ["median"] = {
            8,
            7,
            39,
        },
    },
    ["WARLOCK_AFFLICTION_RAID"] = {
        ["n"] = 20,
        ["builds"] = {
            {
                ["split"] = {
                    30,
                    0,
                    21,
                },
                ["pct"] = 100,
            },
        },
        ["median"] = {
            30,
            0,
            21,
        },
    },
    ["WARLOCK_DEMONOLOGY_RAID"] = {
        ["n"] = 20,
        ["builds"] = {
            {
                ["split"] = {
                    0,
                    30,
                    21,
                },
                ["pct"] = 95,
            },
            {
                ["split"] = {
                    9,
                    21,
                    21,
                },
                ["pct"] = 5,
            },
        },
        ["median"] = {
            0,
            30,
            21,
        },
    },
    ["WARLOCK_DESTRUCTION_RAID"] = {
        ["n"] = 20,
        ["builds"] = {
            {
                ["split"] = {
                    7,
                    10,
                    34,
                },
                ["pct"] = 20,
            },
            {
                ["split"] = {
                    6,
                    11,
                    34,
                },
                ["pct"] = 15,
            },
            {
                ["split"] = {
                    7,
                    3,
                    41,
                },
                ["pct"] = 10,
            },
        },
        ["median"] = {
            7,
            10,
            35,
        },
    },
    ["WARRIOR_ARMS_RAID"] = {
        ["n"] = 5,
        ["builds"] = {
            {
                ["split"] = {
                    31,
                    20,
                    0,
                },
                ["pct"] = 80,
            },
            {
                ["split"] = {
                    31,
                    2,
                    18,
                },
                ["pct"] = 20,
            },
        },
        ["median"] = {
            31,
            20,
            0,
        },
    },
    ["WARRIOR_PROTECTION_RAID"] = {
        ["n"] = 35,
        ["builds"] = {
            {
                ["split"] = {
                    17,
                    3,
                    31,
                },
                ["pct"] = 83,
            },
            {
                ["split"] = {
                    20,
                    31,
                    0,
                },
                ["pct"] = 9,
            },
            {
                ["split"] = {
                    19,
                    0,
                    32,
                },
                ["pct"] = 3,
            },
        },
        ["median"] = {
            17,
            3,
            31,
        },
    },
    ["WARRIOR_FURY_RAID"] = {
        ["n"] = 20,
        ["builds"] = {
            {
                ["split"] = {
                    20,
                    31,
                    0,
                },
                ["pct"] = 100,
            },
        },
        ["median"] = {
            20,
            31,
            0,
        },
    },
}
