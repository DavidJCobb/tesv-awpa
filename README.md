
# Ask Where People Are

Ask Where People Are is a Skyrim mod wherein you can walk up to a named citizen of any town, and ask them for the location of any other named citizen in that same town. (Thus the name.) I'm creating this mod primarily using DovahKit, my work-in-progress attempt at building my own Creation Kit.

## Design

Skyrim basically always simulates the AI of unique NPCs, though at a very low fidelity when they're in a distant, unloaded area. This means that dialogue conditions can run checks like `GetInCell` and even `GetPos` against them and get a *reasonably* accurate result.

AWPA requires a very large amount of dialogue, so the best workflow actually comes from generating that dialogue via DovahKit's (alpha) Lua script APIs, with dialogue defined in XML files.

* For outdoor areas, i.e. NPCs being near certain buildings or parts of a city, I rely on `GetPos` and `GetDistance` checks (the latter run against refs that are persistent in the vanilla game). To measure out the `GetPos` checks, I place bounding volumes in the Creation Kit, but that only shows the centerpoint and extents of these volumes, whereas `GetPos` requires min and max coordinates on a given axis. Therefore, the XML files define coordinates by the centerpoint and extents, and the script can just convert that to a min/max range.

* All lines are written using masculine pronouns to refer to the actor the player has asked about. We can automatically duplicate those lines and swap pronouns via script, but we can only do that for a male-to-female swap. The feminine object and dependent-possessive pronouns are ambiguous (we can't automatically discern whether "her" should map to "him" or "his").
