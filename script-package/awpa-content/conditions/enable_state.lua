
if not awpa.conditions then
   awpa.conditions = {}
end

do
   local instance_members = {}
   awpa.conditions.enable_state = make_class({
      superclass  = awpa.condition,
      constructor = function(self)
         self.form    = nil
         self.enabled = true
      end,
      instance_members = instance_members
   })
   
   do -- member functions
      function instance_members:copy(element)
         local out = awpa.conditions.enable_state()
         self:_copy_base(out)
         out.form    = self.form
         out.enabled = self.enabled
         return out
      end
      function instance_members:from_xml(element)
         if element.node_name ~= "enable-state" then
            utils.fail_load("mismatched node name", element)
         end
         self:_extract_run_on(element)
         
         local v = element.attributes["for"]
         if not v then
            utils.fail_load("attribute `for` required", element)
         end
         self.form = utils.resolve_form_reference(v)
         if not self.form then
            utils.fail_load("REFR not found: " .. v, element)
         end
         
         local invert = false
         v = element.attributes["is"]
         if not v then
            v = element.attributes["is-not"]
            if not v then
               utils.fail_load("attribute `is` or `is-not` required", element)
            end
            invert = true
         end
         if v == "enabled" then
            v = true
         elseif v == "disabled" then
            v = false
         else
            utils.fail_load("`is` or `is-not` must be \"enabled\" or \"disabled\"", element)
         end
         if invert then
            v = not v
         end
         self.enabled = v
      end
      function instance_members:assert_valid()
         if not self.form then
            error("no ref")
         end
      end
      function instance_members:_to_native_compatible_table_impl()
         return {
            run_on        = self.form,
            function_name = "GetDisabled",
            comparison    = {
               operator = self.enabled and "!=" or "==",
               operand  = 1
            }
         }
      end
   end
end