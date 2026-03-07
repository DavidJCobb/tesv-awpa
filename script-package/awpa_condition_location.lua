
if not awpa.conditions then
   awpa.conditions = {}
end

do
   local instance_members = {}
   awpa.conditions.location = make_class({
      superclass  = awpa.condition,
      constructor = function(self)
         self.run_on = "subject"
         self.form   = nil
         self.equals = true
      end,
      instance_members = instance_members
   })
   
   do -- member functions
      function instance_members:copy(element)
         local out = awpa.conditions.location()
         out.is_or_linked = self.is_or_linked
         out.form   = self.form
         out.equals = self.equals
         return out
      end
      function instance_members:from_xml(element)
         if element.node_name ~= "location" then
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
         self.form = dovah.get_form_by_editor_id(v, form_types.location)
         if not self.form then
            error("LCTN not found: " .. v)
         end
      end
      function instance_members:apply_to_info(info, scope)
         if not self.form then
            error("no location")
         end
         local cnd = info.conditions:insert()
         self:_set_condition_common(cnd)
         self:_set_condition_run_on(cnd)
         cnd.function_name = "GetInCurrentLoc"
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