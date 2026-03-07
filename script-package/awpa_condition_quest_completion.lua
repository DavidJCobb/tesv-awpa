
if not awpa.conditions then
   awpa.conditions = {}
end

do
   local instance_members = {}
   awpa.conditions.quest_completion = make_class({
      superclass  = awpa.condition,
      constructor = function(self)
         self.form = nil
         self.done = nil
      end,
      instance_members = instance_members
   })
   
   do -- member functions
      function instance_members:copy(element)
         local out = awpa.conditions.quest_completion()
         out.is_or_linked = self.is_or_linked
         out.form = self.form
         out.done = self.done
         return out
      end
      function instance_members:from_xml(element)
         if  element.node_name ~= "quest-completed"
         and element.node_name ~= "quest-not-completed"
         then
            error("mismatched node name")
         end
         self:_extract_run_on(element)
         
         local v = element.attributes["name"]
         if not v then
            error("needs `name` attribute")
         end
         self.form = utils.resolve_form_reference(v)
         if not self.form then
            self.form = dovah.get_form_by_editor_id(v, form_types.quest)
            if not self.form then
               error("QUST not found: " .. v)
            end
         end
         
         self.done = element.node_name == "quest-completed"
      end
      function instance_members:assert_valid()
         if not self.form then
            error("no quest")
         end
      end
      function instance_members:overwrite_condition(cnd)
         self:_set_condition_common(cnd)
         cnd.function_name = "GetQuestCompleted"
         cnd.parameters[1] = self.form
         if self.done then
            cnd.comparison.operator = "=="
         else
            cnd.comparison.operator = "!="
         end
         cnd.comparison.operand = 1
      end
   end
end