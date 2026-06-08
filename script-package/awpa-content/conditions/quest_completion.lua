
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
         self:_copy_base(out)
         out.form = self.form
         out.done = self.done
         return out
      end
      function instance_members:from_xml(element)
         if  element.node_name ~= "quest-completed"
         and element.node_name ~= "quest-not-completed"
         then
            utils.fail_load("mismatched node name", element)
         end
         
         local v = element.attributes["name"]
         if not v then
            utils.fail_load("attribute `name` required", element)
         end
         self.form = utils.resolve_form_reference(v, true)
         if not self.form then
            self.form = dovah.get_form_by_editor_id(v, form_types.quest)
            if not self.form then
               utils.fail_load("QUST not found: " .. v, element)
            end
         end
         
         self.done = element.node_name == "quest-completed"
      end
      function instance_members:assert_valid()
         if not self.form then
            error("no quest")
         end
      end
      function instance_members:_to_native_compatible_table_impl()
         return {
            run_on        = "subject",
            function_name = "GetQuestCompleted",
            parameters    = { self.form },
            comparison    = {
               operator = self.done and "==" or "!=",
               operand  = 1
            }
         }
      end
   end
end