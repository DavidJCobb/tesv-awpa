
if not awpa.conditions then
   awpa.conditions = {}
end

do
   local instance_members = {}
   awpa.conditions.race = make_class({
      superclass  = awpa.condition,
      constructor = function(self)
         self.form   = nil
         self.equals = true
      end,
      instance_members = instance_members
   })
   
   do -- member functions
      function instance_members:copy(element)
         local out = awpa.conditions.race()
         self:_copy_base(out)
         out.form   = self.form
         out.equals = self.equals
         return out
      end
      function instance_members:from_xml(element)
         if element.node_name ~= "race" then
            utils.fail_load("mismatched node name", element)
         end
         self:_extract_run_on(element)
         
         local v = element.attributes["is"]
         if v then
            self.equals = true
            if element.attributes["is-not"] then
               utils.fail_load("specify only one of `is` or `is-not`", element)
            end
         else
            self.equals = false
            v = element.attributes["is-not"]
            if not v then
               utils.fail_load("attribute `is` or `is-not` required", element)
            end
         end
         self.form = dovah.get_form_by_editor_id(v, form_types.race)
         if not self.form then
            self.form = utils.resolve_form_reference(v)
            if not self.form then
               utils.fail_load("RACE not found: " .. v, element)
            end
            if self.form.form_type ~= form_types.race then
               utils.fail_load("form is not a RACE: " .. v, element)
            end
         end
      end
      function instance_members:assert_valid()
         if not self.form then
            error("no race")
         end
      end
      function instance_members:_to_native_compatible_table_impl()
         local t = {
            function_name = "GetIsRace",
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