
if not awpa.conditions then
   awpa.conditions = {}
end

do
   local instance_members = {}
   awpa.conditions.distance = make_class({
      superclass  = awpa.condition,
      constructor = function(self)
         self.run_on = "subject"
         self.other  = nil -- ref OR "speaker" or "player" OR "subject"
         self.comparison = {
            operator = nil,
            operand  = nil
         }
      end,
      instance_members = instance_members
   })
   
   do -- member functions
      function instance_members:copy(element)
         local out = awpa.conditions.distance()
         self:_copy_base(out)
         out.run_on = self.run_on
         out.other  = self.other
         out.comparison.operator = self.comparison.operator
         out.comparison.operand  = self.comparison.operand
         return out
      end
      function instance_members:from_xml(element)
         if element.node_name ~= "distance" then
            error("mismatched node name")
         end
         self:_extract_run_on(element)
         
         local v = element.attributes["to"]
         if not v then
            error("attribute `to` required")
         end
         do
            local ref = utils.resolve_form_reference(v, true)
            if ref then
               if  ref.form_type ~= form_types.reference
               and ref.form_type ~= form_types.actor
               then
                  error("ref expected")
               end
               self.other = ref
            else
               if v == "player" then
                  self.other = dovah.get_form_by_id(0x14)
               elseif v == "subject" or v == "speaker" then
                  self.other = v
               end
            end
         end
         if self.run_on == "subject" and self.other == "speaker" then
            error("cannot check the distance between the speaker and themselves")
         end
         if self.run_on == "ActorToFind" and self.other == "subject" then
            error("cannot check the distance between the subject and themselves")
         end
         if self.run_on == "player" and self.other == "player" then
            error("cannot check the distance between the subject and themselves")
         end
         
         self:_extract_numeric_comparison(element)
      end
      function instance_members:overwrite_condition(cnd)
         self:_set_condition_common(cnd)
         self:_set_condition_run_on(cnd)
         cnd.function_name = "GetDistance"
         if type(self.other) == "string" then
            if self.other == "speaker" then
               --
               -- SOMETHING.distance(subject) -> subject.distance(SOMETHING)
               --
               if self.run_on == "player" then
                  --
                  -- player.distance(subject) -> subject.distance(player)
                  --
                  cnd.parameters[1] = dovah.get_form_by_id(0x14)
                  cnd.run_on = "subject"
               else
                  local a = cnd.run_on
                  local b = "subject"
                  if not object_is_form(a) then
                     cnd.override_types_with = "packdata"
                  end
                  cnd.parameters[1] = a
                  cnd.run_on        = b
               end
            elseif self.other == "subject" then
               cnd.override_types_with = "packdata"
               cnd.parameters[1] = self.quest_info.form.aliases["ActorToFind"]
            end
         else
            cnd.parameters[1] = self.other
         end
         cnd.comparison.operator = self.comparison.operator
         cnd.comparison.operand  = self.comparison.operand
      end
   end
end