
do
   local instance_members = {}
   local static_members   = {}
   awpa.condition = make_class({
      constructor = function(self)
         self.owning_scope = nil
         self.quest_info   = nil
         self.is_or_linked = false
         self.is_override  = nil -- optional<awpa.actor>
         
         -- only for some condition functions:
         self.run_on = nil
         
         -- table, suitable for passing to native `condition:overwrite_with`
         self.generated = nil
      end,
      instance_members = instance_members,
      static_members   = static_members,
   })
   do -- member functions
      function instance_members:copy()
         error("pure virtual function call")
      end
      function instance_members:_copy_base(dst)
         dst.owning_scope = self.owning_scope
         dst.quest_info   = self.quest_info
         dst.is_or_linked = self.is_or_linked
         dst.is_override  = self.is_override
         
         -- only for some condition functions:
         dst.run_on = self.run_on
      end
   
      local function _parse_run_on(s)
         if s == "subject" then
            return "ActorToFind"
         elseif s == "speaker" then
            return "subject"
         elseif s == "player" then
            return "player"
         end
      end
      
      function instance_members:_resolve_constant(name)
         if not self.owning_scope then
            error("orphaned condition cannot resolve constants")
         end
         local c = self.owning_scope:resolve_constant(name)
         if not c then
            error("could not resolve value: " .. tostring(name))
         end
         if not c.value then
            error("constant has no value: " .. tostring(name))
         end
         return c.value
      end
   
      function instance_members:_extract_numeric_comparison(element)
         local MAPPING = {
            eq  = "==",
            neq = "!=",
            lt  = "<",
            lte = "<=",
            gt  = ">",
            gte = ">=",
         }
         for k, v in pairs(MAPPING) do
            local operand = element.attributes[k]
            if operand then
               self.comparison.operator = v
               self.comparison.operand  = tonumber(operand) or operand
               if not tonumber(operand) then
                  local form = utils.resolve_form_reference(self.comparison.operand, true)
                  if form then
                     self.comparison.operand = form
                  else
                     self.comparison.operand = self:_resolve_constant(operand)
                  end
               end
               return
            end
         end
      end
      function instance_members:_extract_run_on(element)
         local v = element.attributes["of"]
         self.run_on = _parse_run_on(v)
         if not self.run_on then
            if v then
               utils.fail_load(string.format("attribute `of` had an unexpected value: %q", v), element)
            else
               utils.fail_load("attribute `of` required", element)
            end
         end
      end
   
      function instance_members:from_xml(element)
         error("pure virtual function call")
      end
      
      function instance_members:_set_condition_run_on(cnd)
         if self.run_on == "subject"
         or self.run_on == "player"
         or not self.run_on
         then
            cnd.run_on = self.run_on
         elseif self.run_on == "ActorToFind" then
            if self.is_override then
               local aliases = self.quest_info.form.aliases
               cnd.run_on = aliases[self.is_override.form.editor_id]
            else
               cnd.run_on = self.quest_info.alias_for_actor_to_find
            end
         else
            error("invalid run-on")
         end
      end
      
      function instance_members:_set_condition_common(cnd)
         cnd.is_or_linked = self.is_or_linked or false
      end
      
      function instance_members:assert_valid()
      end
      function instance_members:is_no_op()
         return false
      end
      
      function instance_members:to_native_compatible_table()
         local t = self.generated
         if not t then
            t = self:_to_native_compatible_table_impl()
            t.is_or_linked = self.is_or_linked or false
            self.generated = t
         end
         return t
      end
      function instance_members:_to_native_compatible_table_impl()
         -- Should return a table `t` suitable for passing to `condition:overwrite_with`.
         -- Does not need to worry about setting up `t.is_or_linked`.
         error("pure virtual function call")
      end
   end
   do -- static members
      local TAGNAMES_TO_CONSTRUCTOR_NAMES = {
         ["actor-base"]             = "actor_base",
         ["death-count"]            = "death_count",
         ["distance"]               = "distance",
         ["enable-state"]           = "enable_state",
         ["faction-membership"]     = "faction_membership",
         ["global"]                 = "global",
         ["is-in-exterior"]         = "is_in_interior",
         ["is-in-interior"]         = "is_in_interior",
         ["location"]               = "location",
         ["offers-services"]        = "offers_services",
         ["papyrus-quest-variable"] = "papyrus_quest_variable",
         ["parent-cell"]            = "parent_cell",
         ["parent-world"]           = "parent_world",
         ["quest-completed"]        = "quest_completion",
         ["quest-not-completed"]    = "quest_completion",
         ["quest-running"]          = "quest_running_state",
         ["quest-not-running"]      = "quest_running_state",
         ["quest-stage"]            = "quest_stage",
         ["race"]                   = "race",
         ["relationship-rank"]      = "relationship_rank",
         ["scene-running"]          = "scene_running_state",
         ["scene-not-running"]      = "scene_running_state",
         ["x"]                      = "position",
         ["y"]                      = "position",
         ["z"]                      = "position",
      }
      
      function static_members.construct_from_xml(node, options)
         if not options
         or not options.quest_info
         or not options.scope
         then
            error("missing required parameter(s)")
         end
         if not options.scope then
            options.scope = options.quest_info
         end
         
         local clsname <const> = TAGNAMES_TO_CONSTRUCTOR_NAMES[node.node_name]
         if not clsname then
            utils.fail_load_on_unexpected_element(node)
         end
         local cls <const> = awpa.conditions[clsname]
         if not cls then
            utils.fail_load("internal error when loading condition with tag name: " .. node.node_name, node)
         end
         local item <const> = awpa.conditions[clsname]()
         item.owning_scope = options.scope
         item.quest_info   = options.quest_info
         item:from_xml(node)
         return item
      end
      function static_members.construct_list_from_xml(node, dst_list, options)
         if not options
         or not options.quest_info
         then
            error("missing required parameter(s)")
         end
         if not options.scope then
            options.scope = options.quest_info
         end
         
         local allow_condition_set = true
         if options.allow_condition_set ~= nil then
            allow_condition_set = options.allow_condition_set
         end
         local scope <const> = options.scope or options.quest_info
      
         local last_or_linked = nil
         node:for_each_child_element(function(node)
            if node.node_name == "or" then
               node:for_each_child_element(function(node)
                  if node.node_name == "condition-set"
                  or node.node_name == "or"
                  then
                     utils.fail_load("cannot nest this tag in an OR", node)
                  end
                  last_or_linked = awpa.condition.construct_from_xml(node, options)
                  dst_list[#dst_list + 1] = last_or_linked
                  last_or_linked.is_or_linked = true
               end)
            else
               if last_or_linked then
                  last_or_linked.is_or_linked = false
                  last_or_linked = nil
               end
               if node.node_name == "condition-set" then
                  if not allow_condition_set then
                     utils.fail_load("condition sets cannot be referenced here", node)
                  end
                  local name = node.attributes["name"]
                  if not name then
                     utils.fail_load("condition set reference with no `name` (is this a misplaced definition?)", node)
                  end
                  name = tostring(name)
                  local cs = scope:resolve_condition_set(name)
                  if not cs then
                     utils.fail_load("condition set `" .. name .. "` not found", node)
                  end
                  cs:apply_to(dst_list, node)
               else
                  local cnd = awpa.condition.construct_from_xml(node, options)
                  dst_list[#dst_list + 1] = cnd
               end
            end
         end)
         if last_or_linked then
            last_or_linked.is_or_linked = false
         end
      end
   end
end