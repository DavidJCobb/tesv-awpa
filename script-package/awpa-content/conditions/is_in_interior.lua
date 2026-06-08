
if not awpa.conditions then
   awpa.conditions = {}
end

do
   local instance_members = {}
   awpa.conditions.is_in_interior = make_class({
      superclass  = awpa.condition,
      constructor = function(self)
         self.run_on = "subject"
         self.equals = true
      end,
      instance_members = instance_members
   })
   
   do -- member functions
      function instance_members:copy(element)
         local out = awpa.conditions.is_in_interior()
         self:_copy_base(out)
         out.equals = self.equals
         return out
      end
      function instance_members:from_xml(element)
         if  element.node_name ~= "is-in-interior"
         and element.node_name ~= "is-in-exterior"
         then
            utils.fail_load("mismatched node name", element)
         end
         self:_extract_run_on(element)
         
         self.equals = element.node_name == "is-in-interior"
      end
      function instance_members:_to_native_compatible_table_impl()
         local t = {
            function_name = "IsInInterior",
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