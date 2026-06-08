
if not awpa.conditions then
   awpa.conditions = {}
end

do
   local instance_members = {}
   awpa.conditions.relationship_rank = make_class({
      superclass  = awpa.condition,
      constructor = function(self)
         self.with_actor = nil
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
         out.with_actor = self.with_actor
         out.comparison.operator = self.comparison.operator
         out.comparison.operand  = self.comparison.operand
         return out
      end
      function instance_members:from_xml(element)
         if element.node_name ~= "relationship-rank" then
            utils.fail_load("mismatched node name", element)
         end
         self:_extract_run_on(element)
         
         local v = element.attributes["with"]
         if not v then
            utils.fail_load("attribute `with` required", element)
         end
         if v == "player" then
            self.with_actor = dovah.get_form_by_id(0x14) -- PlayerRef
            assert(self.with_actor)
         else
            local actor_base = dovah.get_form_by_editor_id(v, form_types.actor_base)
            if not actor_base then
               utils.fail_load("NPC_ not found: " .. v, element)
            end
            
            assert(self.quest_info)
            local aliases = self.quest_info.form.aliases
            local alias   = aliases[actor_base.editor_id]
            if not alias then
               utils.fail_load("actor `" .. v .. "` is not an alias on the containing quest (you can only specify actors listed in the quest's actor list", element)
            end
            self.with_actor = alias
         end
         
         self:_extract_numeric_comparison(element)
      end
      function instance_members:assert_valid()
         if not self.with_actor then
            error("no actor ref or alias")
         end
      end
      function instance_members:_to_native_compatible_table_impl()
         local override_type = nil
         if not object_is_form(self.with_actor) then
            override_type = "alias"
         end
         return {
            run_on        = "subject",
            function_name = "GetRelationshipRank",
            parameters    = { self.with_actor },
            comparison    = self.comparison,
            override_types_with = override_type,
         }
      end
   end
end