
[size=5][b]Ask Where People Are[/b][/size]

This mod allows you to walk up to any named townsperson in Skyrim's major cities and settlements, and ask for the location of any other named townsperson in the same settlement (provided said individual is still alive and is currently in the settlement). Several characters even have unique responses that match their personalities or their relationship with the player, and one or two NPCs will even refuse to help you at all! It's a nice, immersive alternative to objective markers and Clairvoyance spells.

Note that for now, this only works for base-game NPCs, not DLC or CC NPCs. It also very specifically doesn't work for Snilf, one of the beggars in Riften, since Bethesda forgot to flag him as a unique actor. Poor Snilf.

Note also that all lines are unvoiced. Perhaps someday I'll find time to splice thousands of lines for a dozen voicetypes each, but today is not that day, and honestly, to-year is probably not that year.


[size=4][b]How it works and how it's made[/b][/size]

There's no special magic to how the mod itself works. An actor's position can be checked for using conditions like [i]GetInCell[/i] and [i]GetPos[/i]; conceptually, all I did was doodle a bunch of boxes on a map, and then condition different lines based on whether an NPC is in a given box. There's no system to simulate whose location would be known to whom based on their schedules, paths of travel, or anything like that; NPCs just fudge their responses with qualifiers like "I saw her a little while ago." (That said, I did try to put some of the more obvious limitations in; for example, if Brynjolf is hanging out in the Ragged Flagon, Riften's surface-dwellers won't know where he's at.) There's also [i]basically[/i] no scripting; there's [i]one[/i] brief line of script code that runs when you pick an actor to ask about, to put that actor in an alias (the fill-in-the-blanks that make Radiant Quests possible) so we can run checks against them no matter who they are.

So the mod itself is pretty simple. The challenge was setting up all 5,199 lines of dialogue that the mod includes as of this writing. The workflow I used is impossible in the Creation Kit, and would be inordinately difficult using xEdit's scripting engine.

I made this mod using the alpha version of DovahKit, my attempt at creating a third-party Creation Kit. DovahKit includes an (incomplete) Lua script API for working with form data. For AWPA, I came up with a custom XML format that let me define NPC responses and conditions very efficiently, and I wrote a collection of Lua scripts to load this XML content and use it to create dialogue data en masse.

Here's the XML for the outside of Rustleif and Seren's house in Dawnstar, as an example. This collection of dialogue lines is defined as a bunch of nested groups, with conditions in an outer group inherited by the inner groups. This meant I could write the [i]GetPos[/i] checks for their house just once, and then handle all of the sub-cases (e.g. whether you're asking one of the homeowners, or someone else; whether either homeowner is dead).

[spoiler]
[code]
<g name="rustleif-house">
   <conditions>
      <x of="subject" gte="28672" />
      <x of="subject" lte="31072" />
      <y of="subject" gte="103024" />
      <y of="subject" lte="105328" />
      <z of="subject" lt="main-street-z-min" />
   </conditions>
   <g name="resident">
      <conditions>
         <or>
            <actor-base of="subject" is="Rustleif" />
            <actor-base of="subject" is="Seren" />
         </or>
      </conditions>
      <shared-info id="shared-exterior-near-own-home" />
   </g>
   <g non-exclusive="true" name="both-alive">
      <conditions>
         <death-count for="Rustleif" lte="0" />
         <death-count for="Seren" lte="0" />
      </conditions>
      <line>He might've been headed to Rustleif and Seren's home. They're the local blacksmiths.</line>
   </g>
   <g non-exclusive="true" name="rustleif-dead-seren-alive">
      <conditions>
         <death-count for="Rustleif" gt="0" />
         <death-count for="Seren" lte="0" />
      </conditions>
      <line>He might've been headed to Seren's home. <verbatim>She's</verbatim> the local blacksmith.</line>
   </g>
   <g non-exclusive="true" name="seren-dead-rustleif-alive">
      <conditions>
         <death-count for="Seren" gt="0" />
         <death-count for="Rustleif" lte="0" />
      </conditions>
      <line>He might've been headed to Rustleif's home. <verbatim>He's</verbatim> the local blacksmith.</line>
   </g>
   <line>I'm pretty sure I saw him around Rustleif's house.</line>
   <line>Hmm... Try looking near Rustleif's house, at the edge of the bay.</line>
</g>
[/code]
[/spoiler]

One thing you might also notice is that all of the lines use masculine pronouns to refer to whoever you're asking about. I wrote my Lua scripts to detect when a line contains masculine pronouns; these lines get duplicated, the pronouns get swapped from he/him/his to she/her/her, and both copies of the line get [i]GetIsSex[/i] checks targeting whoever you're asking about. This was one of the first ideas I had, many many years ago when I came up with this mod idea, and it cut the amount of content I needed to write almost in half. For cases where pronouns refer to someone other than the person you're asking about, they can be wrapped in "verbatim" XML tags to prevent them from being recognized and swapped.

There are all sorts of other tricks as well, including a full macro system for creating reusable arrangements of groups and conditions.

One of the largest benefits of using XML here was that I could also create a browser-based tool able to read that XML, to let me render out a map of all of the box-shaped areas I have [i]GetPos[/i] checks for. This made it very easy to ensure that I had full coverage of each town and city, with no gaps that would prevent an NPC's location from being identified.


[size=4][b]Notes[/b][/size]
As mentioned above, this mod was created using DovahKit; I used the Creation Kit to measure out coordinates for the [i]GetPos[/i] boxes, but all of this mod's actual content and data [i]using[/i] those coordinates was built using DovahKit.

Something that feels worth mentioning is that this mod idea is actually what motivated me to make DovahKit in the first place. I came up with the idea and built a brief proof of concept no later than May 2017: a simple mod that allowed me to approach any NPC in the game world, and ask whether Dinya Balu was in or around Riften's market. That worked well enough to prove that the idea as a whole could work, but I knew that no existing tools were capable of the kind of workflow I'd to set up the thousands of lines of dialogue this mod concept would require. The Creation Kit was flat-out incapable, and while xEdit [i]does[/i] have a scripting API, that API is... clunky. (Not their fault. They use an interpreter made by someone else, and it's sufficient for the use cases they intend. A project like [i]this[/i] just isn't one of those use cases.)

So I burned six years of my life on making my own Creation Kit, able to do what I needed, and now, you and I can find NPCs without needing an objective marker. Sometimes, it's the most understated mod concepts that take the most work.
