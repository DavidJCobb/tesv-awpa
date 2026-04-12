
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
            error("mismatched node name")
         end
         self:_extract_run_on(element)
         
         local v = element.attributes["includes"]
         if v then
            self.equals = true
            if element.attributes["excludes"] then
               error("specify only one of `includes` or `excludes`")
            end
         else
            self.equals = false
            v = element.attributes["excludes"]
            if not v then
               error("specify either `includes` or `excludes`")
            end
         end
         self.form = dovah.get_form_by_editor_id(v, form_types.faction)
         if not self.form then
            self.form = utils.resolve_form_reference(v)
            if not self.form then
               error("FACT not found: " .. v)
            end
            if self.form.form_type ~= form_types.faction then
               error("form is not a FACT: " .. v)
            end
         end
      end
      function instance_members:assert_valid()
         if not self.form then
            error("no faction")
         end
      end
      function instance_members:overwrite_condition(cnd)
         self:_set_condition_common(cnd)
         self:_set_condition_run_on(cnd)
         cnd.function_name = "GetInFaction"
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