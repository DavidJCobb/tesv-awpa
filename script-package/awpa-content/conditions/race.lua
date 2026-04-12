
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
            error("mismatched node name")
         end
         self:_extract_run_on(element)
         
         local v = element.attributes["is"]
         if v then
            self.equals = true
            if element.attributes["is-not"] then
               error("specify only one of `is` or `is-not`")
            end
         else
            self.equals = false
            v = element.attributes["is-not"]
            if not v then
               error("specify either `is` or `is-not`")
            end
         end
         self.form = dovah.get_form_by_editor_id(v, form_types.race)
         if not self.form then
            self.form = utils.resolve_form_reference(v)
            if not self.form then
               error("RACE not found: " .. v)
            end
            if self.form.form_type ~= form_types.race then
               error("form is not a RACE: " .. v)
            end
         end
      end
      function instance_members:assert_valid()
         if not self.form then
            error("no race")
         end
      end
      function instance_members:overwrite_condition(cnd)
         self:_set_condition_common(cnd)
         self:_set_condition_run_on(cnd)
         cnd.function_name = "GetIsRace"
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