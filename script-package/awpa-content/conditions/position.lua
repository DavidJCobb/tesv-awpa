
if not awpa.conditions then
   awpa.conditions = {}
end

do
   local instance_members = {}
   awpa.conditions.position = make_class({
      superclass  = awpa.condition,
      constructor = function(self)
         self.run_on = "subject"
         self.axis   = nil
         self.comparison = {
            operator = nil,
            operand  = nil
         }
      end,
      instance_members = instance_members
   })
   
   do -- member functions
      function instance_members:copy(element)
         local out = awpa.conditions.position()
         self:_copy_base(out)
         out.run_on = self.run_on
         out.axis   = self.axis
         out.comparison.operator = self.comparison.operator
         out.comparison.operand  = self.comparison.operand
         return out
      end
      function instance_members:from_xml(element)
         if element.node_name == "x"
         or element.node_name == "y"
         or element.node_name == "z"
         then
            self.axis = element.node_name:upper()
         else
            utils.fail_load("mismatched node name", element)
         end
         self:_extract_run_on(element)
         self:_extract_numeric_comparison(element)
      end
      function instance_members:_to_native_compatible_table_impl()
         local t = {
            function_name = "GetPos",
            parameters    = { self.axis },
            comparison    = self.comparison
         }
         self:_set_condition_run_on(t)
         return t
      end
   end
end