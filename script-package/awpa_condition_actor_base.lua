
if not awpa.conditions then
   awpa.conditions = {}
end

do
   local instance_members = {}
   awpa.conditions.actor_base = make_class({
      superclass  = awpa.condition,
      constructor = function(self)
         self.run_on = "subject"
         self.form   = nil
         self.name   = nil
         self.equals = true
      end,
      instance_members = instance_members
   })
   
   do -- member functions
      function instance_members:copy(element)
         local out = awpa.conditions.actor_base()
         out.is_or_linked = self.is_or_linked
         out.form   = self.form
         out.name   = self.name
         out.equals = self.equals
         return out
      end
      function instance_members:from_xml(element)
         if element.node_name ~= "actor-base" then
            error("mismatched node name")
         end
         self:_extract_run_on(element)
         
         local v = element.attributes["is"]
         if not v then
            v = element.attributes["is-not"]
            if v then
               self.equals = false
            else
               error("needs `is` or `is-not` attribute")
            end
         end
         self.name = v
         self.form = dovah.get_form_by_editor_id(v, form_types.actor_base)
         -- self.form can be None, in which case we'll look it up at apply time
      end
      function instance_members:apply_to_info(info, scope)
         if not self.form then
            if not self.name then
               error("no actor base")
            end
            if not self.quest_info then
               error("unable to locate quest definition")
            end
            local actor_info = self.quest_info:actor_by_name(self.name)
            if actor_info then
               self.form = actor_info.form
            end
            if not self.form then
               error("unable to locate actor form: " .. self.name)
            end
         end
         
         local cnd = info.conditions:insert()
         self:_set_condition_common(cnd)
         self:_set_condition_run_on(cnd)
         cnd.function_name = "GetIsID"
         cnd.parameters[1] = self.form
         if self.equals then
            cnd.comparison.operator = "=="
         else
            cnd.comparison.operator = "!="
         end
         cnd.comparison.operand  = 1
      end
   end
end