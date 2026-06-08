
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
         self:_copy_base(out)
         out.form   = self.form
         out.equals = self.equals
         return out
      end
      function instance_members:from_xml(element)
         if element.node_name ~= "location" then
            utils.fail_load("mismatched node name", element)
         end
         self:_extract_run_on(element)
         
         local v = element.attributes["is"]
         if not v then
            v = element.attributes["is-not"]
            if v then
               self.equals = false
            else
               utils.fail_load("attribute `is` or `is-not` required", element)
            end
         end
         self.form = dovah.get_form_by_editor_id(v, form_types.location)
         if not self.form then
            utils.fail_load("LCTN not found: " .. v, element)
         end
      end
      function instance_members:assert_valid()
         if not self.form then
            error("no location")
         end
      end
      function instance_members:_to_native_compatible_table_impl()
         local t = {
            function_name = "GetInCurrentLoc",
            parameters    = { self.form },
            comparison    = {
               operator = self.equals and "==" or "!=",
               operand  = 1
            }
         }
         self:_set_condition_run_on(t)
         return t
      end
   end
end