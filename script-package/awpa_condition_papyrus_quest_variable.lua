
if not awpa.conditions then
   awpa.conditions = {}
end

do
   local instance_members = {}
   awpa.conditions.papyrus_quest_variable = make_class({
      superclass  = awpa.condition,
      constructor = function(self)
         self.form       = nil
         self.variable   = nil
         self.comparison = {
            operator = nil,
            operand  = nil
         }
      end,
      instance_members = instance_members
   })
   
   do -- member functions
      function instance_members:copy(element)
         local out = awpa.conditions.papyrus_quest_variable()
         out.form     = self.form
         out.variable = self.variable
         out.comparison.operator = self.comparison.operator
         out.comparison.operand  = self.comparison.operand
         return out
      end
      function instance_members:from_xml(element)
         if element.node_name ~= "papyrus-quest-variable" then
            error("mismatched node name")
         end
         self:_extract_run_on(element)
         
         local v = element.attributes["for"]
         if not v then
            error("needs `for` attribute")
         end
         self.form = dovah.get_form_by_editor_id(v, form_types.quest)
         if not self.form then
            error("QUST not found: " .. v)
         end
         
         self.variable = element.attributes["var"]
         if not self.variable then
            error("variable name `var` missing")
         end
         
         self:_extract_numeric_comparison(element)
      end
      function instance_members:apply_to_info(info, scope)
         if not self.form then
            error("no quest")
         end
         local cnd = info.conditions:insert()
         self:_set_condition_common(cnd)
         cnd.function_name = "GetVMQuestVariable"
         cnd.parameters[1] = self.form
         cnd.parameters[2] = self.variable
         cnd.comparison.operator = self.comparison.operator
         cnd.comparison.operand  = self.comparison.operand
      end
   end
end