
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
         self.range  = {
            origin      = nil,
            half_extent = nil
         }
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
         out.run_on = self.run_on
         out.axis   = self.axis
         out.range  = {
            origin      = self.range.origin,
            half_extent = self.range.half_extent
         }
         out.comparison.operator = self.comparison.operator
         out.comparison.operand  = self.comparison.operand
         return out
      end
      function instance_members:from_xml(element)
         if element.node_name == "x"
         or element.node_name == "y"
         or element.node_name == "z"
         then
            self.axis = element.node_name
         else
            error("mismatched node name")
         end
         self:_extract_run_on(element)
         
         local v = element.attributes["at"]
         if v then
            if tonumber(v) then
               v = tonumber(v)
            else
               v = self:_resolve_constant(v)
            end
            self.range.origin = v
            
            v = element.attributes["within"]
            if not v then
               v = element.attributes["around"]
               if not v then
                  error("`at` must be used in conjunction with `within` (full-extent) or `around` (half-extent)")
               end
               v = tonumber(v) / 2
            end
            if tonumber(v) then
               v = tonumber(v)
            else
               v = self:_resolve_constant(v)
            end
            self.range.half_extent = v
         else
            self:_extract_numeric_comparison(element)
         end
      end
      function instance_members:apply_to_info(info, scope)
         local cnd = info.conditions:insert()
         self:_set_condition_common(cnd)
         self:_set_condition_run_on(cnd)
         cnd.function_name = "GetPos"
         cnd.parameters[1] = self.axis
         if self.range.origin then
            if self.is_or_linked then
               error("position range conditions cannot be OR-linked")
            end
            cnd.comparison.operator = ">="
            cnd.comparison.operand  = self.range.origin - self.range.half_extent
            
            cnd = info.conditions:insert()
            self:_set_condition_common(cnd)
            self:_set_condition_run_on(cnd)
            cnd.function_name = "GetPos"
            cnd.parameters[1] = self.axis
            cnd.comparison.operator = "<="
            cnd.comparison.operand  = self.range.origin + self.range.half_extent
         else
            cnd.comparison.operator = self.comparison.operator
            cnd.comparison.operand  = self.comparison.operand
         end
      end
   end
end