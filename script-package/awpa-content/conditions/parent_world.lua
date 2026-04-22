
if not awpa.conditions then
   awpa.conditions = {}
end

do
   local instance_members = {}
   awpa.conditions.parent_world = make_class({
      superclass  = awpa.condition,
      constructor = function(self)
         self.run_on = "subject"
         self.world  = nil -- form
         self.equals = true
      end,
      instance_members = instance_members
   })
   
   do -- member functions
      function instance_members:copy(element)
         local out = awpa.conditions.parent_world()
         self:_copy_base(out)
         for _, v in ipairs({
            "run_on",
            "world",
            "equals"
         }) do
            out[v] = self[v]
         end
         return out
      end
      function instance_members:from_xml(element)
         if element.node_name ~= "parent-world" then
            error("mismatched node name")
         end
         self:_extract_run_on(element)
         
         local v = element.attributes["is"]
         if v then
            if element.attributes["is-not"]
            or element.attributes["same-as"]
            then
               error("you must specify only one of `is` or `is-not`")
            end
         else
            v = element.attributes["is-not"]
            if v then
               self.equals = false
               if element.attributes["same-as"] then
                  error("you must specify only one of `is` or `is-not`")
               end
            else
               error("you must specify one of `is` or `is-not`")
            end
         end
         self.world = dovah.get_form_by_editor_id(v, form_types.worldspace)
         if not self.world then
            error("WRLD not found: " .. v)
         end
      end
      function instance_members:overwrite_condition(cnd)
         self:_set_condition_common(cnd)
         self:_set_condition_run_on(cnd)
         
         cnd.function_name = "GetInWorldspace"
         cnd.parameters[1] = self.world
         if self.equals then
            cnd.comparison.operator = "=="
         else
            cnd.comparison.operator = "!="
         end
         cnd.comparison.operand  = 1
      end
      function instance_members:_to_native_compatible_table_impl()
         local t = {
            function_name = "GetInWorldspace",
            parameters    = { self.world },
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