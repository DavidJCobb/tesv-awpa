
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
         self:_copy_base(out)
         out.form     = self.form
         out.variable = self.variable
         out.comparison.operator = self.comparison.operator
         out.comparison.operand  = self.comparison.operand
         return out
      end
      function instance_members:from_xml(element)
         if element.node_name ~= "papyrus-quest-variable" then
            utils.fail_load("mismatched node name", element)
         end
         self:_extract_run_on(element)
         
         local v = element.attributes["for"]
         if not v then
            utils.fail_load("attribute `for` required", element)
         end
         self.form = dovah.get_form_by_editor_id(v, form_types.quest)
         if not self.form then
            utils.fail_load("QUST not found: " .. v, element)
         end
         
         self.variable = element.attributes["var"]
         if not self.variable then
            utils.fail_load("attribute `var` required", element)
         end
         
         self:_extract_numeric_comparison(element)
      end
      function instance_members:assert_valid()
         if not self.form then
            error("no quest")
         end
      end
      function instance_members:_to_native_compatible_table_impl()
         return {
            run_on        = "subject",
            function_name = "GetVMQuestVariable",
            parameters    = { self.form, self.variable },
            comparison    = self.comparison
         }
      end
   end
end