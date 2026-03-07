
if not awpa.conditions then
   awpa.conditions = {}
end

do
   local instance_members = {}
   awpa.conditions.death_count = make_class({
      superclass  = awpa.condition,
      constructor = function(self)
         self.form       = nil
         self.comparison = {
            operator = nil,
            operand  = nil
         }
      end,
      instance_members = instance_members
   })
   
   do -- member functions
      function instance_members:copy(element)
         local out = awpa.conditions.death_count()
         out.is_or_linked = self.is_or_linked
         out.form     = self.form
         out.comparison.operator = self.comparison.operator
         out.comparison.operand  = self.comparison.operand
         return out
      end
      function instance_members:from_xml(element)
         if element.node_name ~= "death-count" then
            error("mismatched node name")
         end
         self:_extract_run_on(element)
         
         local v = element.attributes["for"]
         if not v then
            error("needs `for` attribute")
         end
         self.form = dovah.get_form_by_editor_id(v, form_types.actor_base)
         if not self.form then
            error("NPC_ not found: " .. v)
         end
         
         self:_extract_numeric_comparison(element)
      end
      function instance_members:assert_valid()
         if not self.form then
            error("no actor base")
         end
      end
      function instance_members:overwrite_condition(cnd)
         self:_set_condition_common(cnd)
         cnd.function_name = "GetDeadCount"
         cnd.parameters[1] = self.form
         cnd.comparison.operator = self.comparison.operator
         cnd.comparison.operand  = self.comparison.operand
      end
   end
end