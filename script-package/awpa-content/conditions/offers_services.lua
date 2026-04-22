
if not awpa.conditions then
   awpa.conditions = {}
end

do
   local instance_members = {}
   awpa.conditions.offers_services = make_class({
      superclass  = awpa.condition,
      constructor = function(self)
         self.run_on = "subject"
         self.equals = true
      end,
      instance_members = instance_members
   })
   
   do -- member functions
      function instance_members:copy(element)
         local out = awpa.conditions.offers_services()
         self:_copy_base(out)
         out.equals = self.equals
         return out
      end
      function instance_members:from_xml(element)
         if element.node_name ~= "offers-services" then
            error("mismatched node name")
         end
         self:_extract_run_on(element)
         
         local v = element.attributes["state"]
         if v then
            self.equals = (v ~= "false")
         end
      end
      function instance_members:overwrite_condition(cnd)
         self:_set_condition_common(cnd)
         self:_set_condition_run_on(cnd)
         cnd.function_name = "GetOffersServicesNow"
         if self.equals then
            cnd.comparison.operator = "=="
         else
            cnd.comparison.operator = "!="
         end
         cnd.comparison.operand  = 1
      end
      function instance_members:_to_native_compatible_table_impl()
         local t = {
            function_name = "GetOffersServicesNow",
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