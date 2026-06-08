
if not awpa.conditions then
   awpa.conditions = {}
end

do
   local instance_members = {}
   awpa.conditions.global = make_class({
      superclass  = awpa.condition,
      constructor = function(self)
         self.form       = nil
         self.comparison = {
            operator = nil,
            operand  = nil
         }
      end,
      instance_members = instance_members
   })
   
   do -- member functions
      function instance_members:copy(element)
         local out = awpa.conditions.global()
         self:_copy_base(out)
         out.form     = self.form
         out.comparison.operator = self.comparison.operator
         out.comparison.operand  = self.comparison.operand
         return out
      end
      function instance_members:from_xml(element)
         if element.node_name ~= "global" then
            utils.fail_load("mismatched node name", element)
         end
         self:_extract_run_on(element)
         
         local v = element.attributes["form"] or element.attributes["name"]
         if not v then
            utils.fail_load("attribute `form` or `name` required", element)
         end
         self.form = dovah.get_form_by_editor_id(v, form_types.global)
         if not self.form then
            utils.fail_load("GLOB not found: " .. v, element)
         end
         
         self:_extract_numeric_comparison(element)
      end
      function instance_members:assert_valid()
         if not self.form then
            error("no global")
         end
      end
      function instance_members:_to_native_compatible_table_impl()
         return {
            run_on        = "subject",
            function_name = "GetGlobalValue",
            parameters    = { self.form },
            comparison    = self.comparison
         }
      end
   end
end