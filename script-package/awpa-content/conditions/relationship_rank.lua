
if not awpa.conditions then
   awpa.conditions = {}
end

do
   local instance_members = {}
   awpa.conditions.relationship_rank = make_class({
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
         local out = awpa.conditions.relationship_rank()
         self:_copy_base(out)
         out.form     = self.form
         out.comparison.operator = self.comparison.operator
         out.comparison.operand  = self.comparison.operand
         return out
      end
      function instance_members:from_xml(element)
         if element.node_name ~= "relationship-rank" then
            error("mismatched node name")
         end
         self:_extract_run_on(element)
         
         local v = element.attributes["with"]
         if not v then
            error("needs `with` attribute")
         end
         if v == "player" then
            self.form = dovah.get_form_by_id(0x7) -- Player
         else
            self.form = dovah.get_form_by_editor_id(v, form_types.actor_base)
         end
         if not self.form then
            error("NPC_ not found: " .. v)
         end
         
         self:_extract_numeric_comparison(element)
      end
      function instance_members:assert_valid()
         if not self.form then
            error("no actor base")
         end
      end
      function instance_members:_to_native_compatible_table_impl()
         return {
            run_on        = "subject",
            function_name = "GetRelationshipRank",
            parameters    = { self.form },
            comparison    = self.comparison
         }
      end
   end
end