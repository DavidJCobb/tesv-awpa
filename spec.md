
# Tags

* **`actor`:** Defines an actor you can ask about.

  * **`conditions`:** Conditions that must be met for you to be able to inquire about someone.

  * **`entry-point-conditions`:** Conditions that must be met for you to be able to select the line, "Can you help me find someone?"

  * **`override-entry-point`:** Overrides the responses the actor can give when you initially ask, "Can you help me find someone?" If `exclusive="true"` is not present, and the overrides are conditional and none match, then your inquiry proceeds as normal. In essence, this spawns extra infos in response to "Can you help me find someone?"
  
  * **`override-responses`:** If the conditions herein are true, then you can ask about anyone, but the speaker will only give these responses no matter who you pick.

* **`constant`:** Define a constant with a `name` and `value`. Scoped to the element in which it is defined.

* **`group`:** Defines a group of lines of dialogue. Can have an optional `name`. Groups can be nested.

  * `unordered="true"` indicates that we don't care about the ordering of groups nested within this one. If set, the group cannot directly contain child lines. Note that `priority` values can be set on nested groups to bias some to having their conditions checked before (higher priority) or after (lower priority) others (that is: this influences the ordering of topic-infos within the topic we generate).
  
  * `non-exclusive="true"` means that this group's lines are part of the parent group, i.e. there should be no "Random End" separating them.

  * **`lines`:** Container element for dialogue.
  
    * **`line`:** A single line of dialogue. The subject-actor being discussed should always be referred to using male pronouns; we can automatically generate female-pronoun lines (with appropriate `GetSex` conditions) from male-pronoun lines, but we can't automatically do the reverse. You can optionally specify an `hours-until-reset` attribute. Use male pronouns even for specific NPCs, partly in case the user has any gender-swapping mods and partly just because it keeps everything consistent.

* **`condition-set`:** When used outside of a `conditions` element, this defines a reusable set of conditions with a given `name`. When used inside of a `conditions` element, this transcludes a previously-defined set of conditions.

* **`conditions`:** Define a list of conditions that apply to all lines in the current `group`. When groups are nested, the conditions of all ancestor groups apply cumulatively.

* **`or`:** Wraps a set of OR-linked conditions in a `condition-set` or `conditions` element. Not nestable, and condition sets cannot be reused within these.

* **`shared-infos`:** At the top level, a container for groups of shared infos; when it appears elsewhere, it includes the lines belonging to a `group` in the shared infos.

## Conditions

In general, `of` indicates who we're querying information about. You can run conditions on the `speaker`, the `player`, or the `subject` that the player is asking about. If `of` is omitted, search upward for the nearest ancestor element which specifies that, and use that. When conditions are defined in a `condition-set` and that condition set is then reused, `of` may be specified at or above the point of reuse.

* **`actor-base`:** Either `is` or `is-not` a given actor-base.
* **`death-count`:** Test how many times the actor-base specified by `for` has died.
* **`distance`:** Compare the distance `of` some actor `to` some other actor.
* **`global`:** Compare the value of a global.
* **`parent-cell`:** Check the parent cell of a given actor. You can check whether the actor `is` in a given cell, or use `same-as` to check whether they're in the same cell as another entity you can query about.
* **`x`, `y`, and `z`:** A `GetPos` condition.
  * Compare the result via `lt`, `gt`, `lte`, `gte`, or `eq` and `neq` attributes whose values are numeric constants.
  * Alternatively, you can specify `within`/`at` to require that the position be in the range [*within - at*, *within + at*], or `within`/`around` to require that the position be in the range [*within - (around / 2)*, *within + (around / 2)*].
* **`offers-services`:** Check whether an actor is currently acting as a merchant.
* **`parent-world`:** A `GetInWorldspace` against the world specified by `is`.
* **`papyrus-quest-variable:** Check a `variable` on a `quest`, and see whether it's `eq`ual (or `neq`) to a given constant or global-variable value.
* **`quest-completed` and `quest-not-completed`**
* **`quest-running`**
* **`race`:** Check an actor's race.

## Macros

TODO: document me

The content of the `data` attribute is transcluded at the macro use site. Within attributes, `%NAME%` is replaced with the value of the given parameter; within text-content, the syntax is `<substitution parameter="NAME" />`.
