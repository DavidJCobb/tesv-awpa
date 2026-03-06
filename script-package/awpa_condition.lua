
do
   local instance_members = {}
   local static_members   = {}
   awpa.condition = make_class({
      constructor = function(self)
         self.owning_scope = nil
         self.is_or_linked = false
         self.is_override  = nil -- optional<awpa.actor>
      end,
      instance_members = instance_members,
      static_members   = static_members,
   })
   do -- member functions
      function instance_members:copy()
         error("pure virtual function call")
      end
   
      local function _parse_run_on(s)
         if s == "subject" then
            return "ActorToFind"
         elseif s == "speaker" then
            return "subject"
         elseif s == "player" then
            return "player"
         end
         return "subject"
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
                  local form = utils.resolve_form_reference(self.comparison.operand)
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
         self.run_on = _parse_run_on(element.attributes["of"])
      end
   
      function instance_members:from_xml(element)
         error("pure virtual function call")
      end
      
      function instance_members:_set_condition_run_on(info, cnd)
         if self.run_on == "subject"
         or self.run_on == "player"
         or not self.run_on
         then
            cnd.run_on = self.run_on
         elseif self.run_on == "ActorToFind" then
            if self.is_override then
               cnd.run_on = info.parent_quest.aliases[self.is_override.form.editor_id]
            else
               cnd.run_on = info.parent_quest.aliases["ActorToFind"]
            end
         else
            error("invalid run-on")
         end
      end
      
      function instance_members:_set_condition_common(info, cnd)
         cnd.is_or_linked = self.is_or_linked or false
      end
      
      function instance_members:apply_to_info(info, scope)
         error("pure virtual function call")
      end
   end
   do -- static members
      local TAGNAMES_TO_CONSTRUCTOR_NAMES = {
         ["actor-base"]             = "actor_base",
         ["death-count"]            = "death_count",
         ["enable-state"]           = "enable_state",
         ["global"]                 = "global",
         ["location"]               = "location",
         ["offers-services"]        = "offers_services",
         ["papyrus-quest-variable"] = "papyrus_quest_variable",
         ["parent-cell"]            = "parent_cell",
         ["quest-completed"]        = "quest_completion",
         ["quest-not-completed"]    = "quest_completion",
         ["quest-stage"]            = "quest_stage",
         ["x"]                      = "position",
         ["y"]                      = "position",
         ["z"]                      = "position",
      }
      
      function static_members.construct_from_xml(scope, node)
         local clsname = TAGNAMES_TO_CONSTRUCTOR_NAMES[node.node_name]
         if not clsname then
            error("unrecognized tag in condition list: " .. node.node_name)
         end
         local cls  = awpa.conditions[clsname]
         if not cls then
            error("internal error when loading condition with tag name: " .. node.node_name)
         end
         local item = awpa.conditions[clsname]()
         item.owning_scope = scope
         item:from_xml(node)
         return item
      end
      function static_members.construct_list_from_xml(owner, scope, node)
         local is_condition_set = awpa.condition_set.is(owner)
         local list             = owner.conditions
         
         local last_or_linked = nil
         node:for_each_child_element(function(node)
            if node.node_name == "or" then
               node:for_each_child_element(function(node)
                  if node.node_name == "condition-set"
                  or node.node_name == "or"
                  then
                     error("can't nest these in an OR")
                  end
                  last_or_linked = awpa.condition.construct_from_xml(scope, node)
                  list[#list + 1] = last_or_linked
                  last_or_linked.is_or_linked = true
               end)
            else
               if last_or_linked then
                  last_or_linked.is_or_linked = false
                  last_or_linked = nil
               end
               if node.node_name == "condition-set" then
                  if is_condition_set then
                     error("condition sets cannot reference each other")
                  end
                  local name = node.attributes["name"]
                  if not name then
                     error("condition set reference with no name (is this a misplaced definition?)")
                  end
                  name = tostring(name)
                  local cs = scope:resolve_condition_set(name)
                  if not cs then
                     error("condition set `" .. name .. "` not found")
                  end
                  cs:apply_to(owner.conditions, node)
               else
                  local cnd = awpa.condition.construct_from_xml(scope, node)
                  list[#list + 1] = cnd
               end
            end
         end)
         if last_or_linked then
            last_or_linked.is_or_linked = false
         end
      end
   end
end