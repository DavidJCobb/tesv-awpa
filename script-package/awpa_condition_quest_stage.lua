
if not awpa.conditions then
   awpa.conditions = {}
end

do
   local instance_members = {}
   awpa.conditions.quest_stage = make_class({
      superclass  = awpa.condition,
      constructor = function(self)
         self.form  = nil
         self.done  = nil
         self.stage = nil
         self.comparison = {
            operator = nil,
            operand  = nil
         }
      end,
      instance_members = instance_members
   })
   
   do -- member functions
      function instance_members:copy(element)
         local out = awpa.conditions.quest_stage()
         out.is_or_linked = self.is_or_linked
         out.form  = self.form
         out.done  = self.done
         out.stage = self.stage
         out.comparison.operator = self.comparison.operator
         out.comparison.operand  = self.comparison.operand
         return out
      end
      function instance_members:from_xml(element)
         if element.node_name ~= "quest-stage" then
            error("mismatched node name")
         end
         self:_extract_run_on(element)
         
         local v = element.attributes["for"]
         if not v then
            error("needs `for` attribute")
         end
         self.form = utils.resolve_form_reference(v)
         if not self.form then
            self.form = dovah.get_form_by_editor_id(v, form_types.quest)
            if not self.form then
               error("QUST not found: " .. v)
            end
         end
         
         v = element.attributes["done"]
         if v then
            self.done  = true
            self.stage = v
         else
            v = element.attributes["not-done"]
            if v then
               self.done  = false
               self.stage = v
            end
         end
         if self.stage then
            self.stage = tonumber(self.stage)
            v = self.stage
            if not v or v < 0 or v > 65535 then
               error("`done` or `not-done` must be an unsigned 16-bit integer")
            end
         else
            self:_extract_numeric_comparison(element)
         end
      end
      function instance_members:apply_to_info(info, scope)
         if not self.form then
            error("no quest")
         end
         local cnd = info.conditions:insert()
         self:_set_condition_common(cnd)
         if type(self.done) == "nil" then
            cnd.function_name = "GetStage"
            cnd.comparison.operator = self.comparison.operator
            cnd.comparison.operand  = self.comparison.operand
         else
            cnd.function_name = "GetStageDone"
            cnd.parameters[2] = self.stage
            if self.done then
               cnd.comparison.operator = "=="
            else
               cnd.comparison.operator = "!="
            end
            cnd.comparison.operand = 1
         end
         cnd.parameters[1] = self.form
      end
   end
end