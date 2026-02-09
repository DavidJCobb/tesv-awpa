
## Elements

### Actor

**Selector:** `quest>actors>actor`

Defines an actor.

The `editor-id` attribute is the editor ID of the actor base. The `name` attribute defines a name with which the actor can be referenced within the current document; if unspecified, it defaults to the editor ID. The intended use case is to allow the use of "friendly" names within the document; for example, Talen-Jei has the editor ID `TalenJei` but could be defined to use the name `Talen-Jei`, allowing the latter name to then be used to refer to him consistently.

The content of an `actor` element is split into a few kinds of child elements: `begin-asking-to`, `begin-responding`, and `begin-asking-about`. If multiple of any of these elements are present, their contents are concatenated in the order in which they are seen.

* **`begin-asking-to`:** Influence whether the player can ask this actor for help, and what happens when they do.
  * A child `conditions` element will control when the player is allowed to say "Can you help me find someone?" to the actor.
  * Child [groups](./#group) and [lines](./#line) will override how the actor responds to "Can you help me find someone?" If no lines in here have their conditions met, then the actor falls through to the standard behavior.
* **`begin-responding`:** Child [groups](./#group) will override how the actor responds once the player specifies who they're looking for.
* **`begin-asking-about`:** Influence whether the player can ask anyone else about this actor, and what happens when they do.
  * A child `conditions` element will control when the player is allowed to give this actor's name as the person they're looking for.
  * Child [groups](./#group) will override how other actors respond when asked about this actor. If no lines in here have their conditions met, then the speaker falls through to the standard behavior.

### Condition

These elements can only appear in [condition lists](./#condition%20list).

All conditions can specify an `of` attribute specifying what actor to run on (the `subject` being asked about, the `speaker` being asked, or the `player`).

<dfn>Numeric conditions</dfn> can specify relational operators for comparison to either constants or global-variable [form references](./#form%20reference): `gt`, `gte`, `lt`, `lte`, `eq`, `neq`.

<dfn>Range conditions</dfn> can use the same relational operators as numeric conditions, but can also specify allowed values in two alternate forms: center-and-extents (`at` and `around`), and center-and-half-extents (`at` and `within`).

* **`actor-base`:** Either `is` or `is-not` a given editor ID or [`actor`](./#actor) name.
* **`death-count`:** A numeric condition checking the deaths of the unique actor-base specified in the `for` attribute.
* **`enable-state`:** Check whether a given ref is enabled.
  * `for=` the ref
  * `is` or `is-not` either `enabled` or `disabled`
* **`global`:** Numeric condition. The global variable's editor ID can be specified in `name`.
* **`location`:** A `GetInCurrentLoc` condition checking `is` or `is-not`.
* **`papyrus-quest-variable`:** Numeric condition. Look up a numeric Papyrus variable on a quest.
  * `for=` the quest's editor ID
  * `var=` the Papyrus variable name as encoded in game data (i.e. `::Name_var`)
* **`parent-cell`:** Specify a specific parent cell via `is` or `is-not` for `GetInCell`, or for `GetInSameCell`, specify `same-as` as either `subject`, `speaker`, or `player`.
* **`parent-world`:** `is` or `is-not`. Translates to `GetInWorldspace`.
* **`race`:** Check if an actor's race `is` or `is-not` a given race's editor ID.
* **`quest-stage`:** Check quest stage information.
  * `for=` a form reference to the quest
  * Specify a quest stage in `done` or `not-done` for a `GetStageDone` condition, or specify one of the relational operator attributes for a `GetStage` condition.
* **`quest-status`:** Check a quest's status.
  * `for=` the quest
  * `is=` either `running` (`GetQuestRunning`) or `complete` (`GetQuestComplete`)
* **`x`, `y`, and `z`:** Range conditions that translate to `GetPos`.

### Group

**Tag:** `g`

A container element for <i>scoped content</i> and for dialogue.

Groups can have a `name` or an `id`. IDs are globally unique strings; names are not globally unique, so a group which only has a name can only be uniquely identified via its hierarchy (i.e. a path delimited with forward slashes, tracing up either to the root or to the nearest ID; IDs in this path are prefixed with `#`).

If a group is marked as `non-exclusive="true"`, then neither its previous-sibling line nor its last line will be marked "random end."

### Scoped content

These elements and their data are referenceable only within the nearest enclosing [group](./#group). They are typically identified via the `name` attribute, and elements in an inner group can shadow identically-named elements in an outer group.

#### Condition list

Defines a reusable list of conditions. The tagname varies by context.

These are defined similarly to conditions in game content. OR-linked conditions are wrapped in an `or` element; the list is otherwise flat and AND-linked; no nesting is allowed.

#### Condition set definition

**Selector:** `:is(:root, quest, g)>condition-set`

Defines a reusable [condition list](./#condition%20list) with a `name` attribute.

#### Condition set reference

**Selector:** `:is(conditions, condition-set)>condition-set`

Specifies the `name` of a [condition set](./#condition%20set%20definition), and transcludes the content of that condition set into the reference's enclosing condition list.

#### Constant

**Tag:** `constant`

Give a name to a numeric `value`.

#### Macro definition

**Tag:** `macro`

Defines a macro.

`parameter` child elements define a `name`d parameter, optionally with a `default-value`. The `data` child element wraps the content to be included when the macro is invoked. Within attribute values, `%NAME%` substitutes in the value of the `NAME` parameter; within text-content, the syntax is `<substitution parameter="NAME" />`.

#### Macro invocation

**Tag:** `invoke`

Invokes a macro. Invoking a macro transcludes its content at the point of invocation; `parameter` child elements of the `invoke` tag are used to fill macro parameter values; any other child elements of the `invoke` tag are spliced in afterward.

### Bribe

**Tag:** `actor>:is(begin-asking-to, begin-responding)>bribe`

Some NPCs will offer information but only if you pay them. This tag indicates such a situation, and has the following child elements:

* **`conditions`:** Conditions under which the bribe functionality comes into effect.
* **`begin-lines`:** The NPC's immediate response: them demanding money.
* **`accept-lines`:** The NPC's response to the player giving them money, before the NPC then gives information.
* **`refuse-lines`:** The NPC's response to the player refusing to give them money.
* **`poor-lines`:** The NPC's response to the player having insufficient funds.

The structure of a bribe is roughly as follows:

* **Can you help me find someone?**
* *Begin lines.*
  * **I can pay. (Bribe)** (Only if the player has sufficient gold.)
    * *Accept lines.*
      * **(Player selects a name.)**
        * *TODO: Can we defer the actual payment until the player picks a name?*
  * **I don't have enough gold.** (Only if the player lacks sufficient gold.)
    * *Poor lines.*
  * **Never mind.**
    * *Refuse lines.*

### Line

**Tag:** `line`

Defines a single line of dialogue. The text-content is the dialogue text. Ultimately, each `line` corresponds to a Topic Info.

The following optional attributes are available:

* **`hours-until-reset`:** A number indicating the hours until reset to use for this info.
* **`script-notes`:** A string to be preserved within the Script Notes section.
* **`vanilla`:** A form ID or [form reference](./#form%20reference). Indicates that we can copy the audio for a specific vanilla line.
* **`vanilla-fragment:`** A form ID or [form reference](./#form%20reference). Indicates that we may be able to slice out part of the audio for a vanilla line.

### Shared-info list

**Selector:** `:root>shared-info`

A collection of groups whose IDs can be referenced in shared-info references.

### Shared-info reference

**Selector:** `:is(lines, g)>shared-info[id]`

Specifies the ID of a group in the shared-info list, and transcludes the content of that group.

### Quest

**Selector:** `:root>quest[id]`

Defines a quest. You should generally make one for each town or city.

## Data

### Form reference

A string of the form `[TYPE:00123456]EditorID` indicating a form type, form ID, and editor ID.

For infos, you can additionally reference a response by its unique ID in xEdit: `[INFO:00123456]EditorIDIfAny/#ResponseID`.