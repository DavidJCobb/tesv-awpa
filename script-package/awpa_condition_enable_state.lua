
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
         out.is_or_linked = self.is_or_linked
         out.form    = self.form
         out.enabled = self.enabled
         return out
      end
      function instance_members:from_xml(element)
         if element.node_name ~= "enable-state" then
            error("mismatched node name")
         end
         self:_extract_run_on(element)
         
         local v = element.attributes["for"]
         if not v then
            error("needs `for` attribute")
         end
         self.form = utils.resolve_form_reference(v)
         if not self.form then
            error("REFR not found: " .. v)
         end
         
         local invert = false
         v = element.attributes["is"]
         if not v then
            v = element.attributes["is-not"]
            if not v then
               error("`is` or `is-not` attribute required")
            end
            invert = true
         end
         if v == "enabled" then
            v = true
         elseif v == "disabled" then
            v = false
         else
            error("`is` or `is-not` must be \"enabled\" or \"disabled\"")
         end
         if invert then
            v = not v
         end
         self.enabled = v
      end
      function instance_members:apply_to_info(info, scope)
         if not self.form then
            error("no ref")
         end
         
         local cnd = info.conditions:insert()
         self:_set_condition_common(info, cnd)
         cnd.run_on = self.form
         cnd.function_name = "GetDisabled"
         if self.enabled then
            cnd.comparison.operator = "!="
         else
            cnd.comparison.operator = "=="
         end
         cnd.comparison.operand = 1
      end
   end
end