
if not awpa.conditions then
   awpa.conditions = {}
end

do
   local instance_members = {}
   awpa.conditions.quest_running_state = make_class({
      superclass  = awpa.condition,
      constructor = function(self)
         self.form    = nil
         self.running = nil
      end,
      instance_members = instance_members
   })
   
   do -- member functions
      function instance_members:copy(element)
         local out = awpa.conditions.quest_running_state()
         self:_copy_base(out)
         out.form    = self.form
         out.running = self.running
         return out
      end
      function instance_members:from_xml(element)
         if  element.node_name ~= "quest-running"
         and element.node_name ~= "quest-not-running"
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
         
         self.running = element.node_name == "quest-running"
      end
      function instance_members:assert_valid()
         if not self.form then
            error("no quest")
         end
      end
      function instance_members:_to_native_compatible_table_impl()
         return {
            run_on        = "subject",
            function_name = "GetQuestRunning",
            parameters    = { self.form },
            comparison    = {
               operator = self.running and "==" or "!=",
               operand  = 1
            }
         }
      end
   end
end