
do
   local instance_members = {}
   awpa.condition = make_class({
      constructor = function(self)
         self.owning_scope = nil
         self.is_or_linked = false
         self.is_override  = nil -- optional<awpa.actor>
      end,
      instance_members = instance_members,
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
end