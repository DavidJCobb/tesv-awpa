
if not awpa.conditions then
   awpa.conditions = {}
end

do
   local instance_members = {}
   awpa.conditions.faction_membership = make_class({
      superclass  = awpa.condition,
      constructor = function(self)
         self.form   = nil
         self.equals = true
      end,
      instance_members = instance_members
   })
   
   do -- member functions
      function instance_members:copy(element)
         local out = awpa.conditions.faction_membership()
         self:_copy_base(out)
         out.form   = self.form
         out.equals = self.equals
         return out
      end
      function instance_members:from_xml(element)
         if element.node_name ~= "faction-membership" then
            utils.fail_load("mismatched node name", element)
         end
         self:_extract_run_on(element)
         
         local v = element.attributes["includes"]
         if v then
            self.equals = true
            if element.attributes["excludes"] then
               utils.fail_load("specify only one of `includes` or `excludes`", element)
            end
         else
            self.equals = false
            v = element.attributes["excludes"]
            if not v then
               utils.fail_load("attribute `includes` or `excludes` required", element)
            end
         end
         self.form = dovah.get_form_by_editor_id(v, form_types.faction)
         if not self.form then
            self.form = utils.resolve_form_reference(v)
            if not self.form then
               utils.fail_load("FACT not found: " .. v, element)
               error("FACT not found: " .. v)
            end
            if self.form.form_type ~= form_types.faction then
               utils.fail_load("form is not a FACT: " .. v, element)
            end
         end
      end
      function instance_members:assert_valid()
         if not self.form then
            error("no faction")
         end
      end
      function instance_members:_to_native_compatible_table_impl()
         local t = {
            function_name = "GetInFaction",
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