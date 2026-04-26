
if not awpa.conditions then
   awpa.conditions = {}
end

do
   local instance_members = {}
   awpa.conditions.parent_cell = make_class({
      superclass  = awpa.condition,
      constructor = function(self)
         self.run_on = "subject"
         self.cell   = nil -- form
         self.actor  = nil
         self.equals = true
      end,
      instance_members = instance_members
   })
   
   do -- member functions
      function instance_members:copy(element)
         local out = awpa.conditions.parent_cell()
         self:_copy_base(out)
         for _, v in ipairs({
            "run_on",
            "cell",
            "actor",
            "equals"
         }) do
            out[v] = self[v]
         end
         return out
      end
      function instance_members:from_xml(element)
         if element.node_name ~= "parent-cell" then
            error("mismatched node name")
         end
         self:_extract_run_on(element)
         
         local v = element.attributes["is"]
         if v then
            if element.attributes["is-not"]
            or element.attributes["same-as"]
            then
               error("you must specify only one of `is`, `is-not`, or `same-as`")
            end
         else
            v = element.attributes["is-not"]
            if v then
               self.equals = false
               if element.attributes["same-as"] then
                  error("you must specify only one of `is`, `is-not`, or `same-as`")
               end
            end
         end
         if v then
            self.cell = dovah.get_form_by_editor_id(v, form_types.cell)
            if not self.cell then
               error("CELL not found: " .. v)
            end
         else
            v = element.attributes["same-as"]
            if not v then
               error("you must specify one of `is`, `is-not`, or `same-as`")
            end
            self.actor = v
            
            if self.actor ~= self.subject then
               if self.actor == "speaker" then
                  local a = self.run_on
                  local b = self.actor
                  self.run_on = b
                  self.actor  = a
               end
            end
         end
      end
      function instance_members:is_no_op()
         self:assert_valid()
         if self.actor then
            local MAPPING = {
               ["ActorToFind"] = "subject",
               ["player"]      = "player",
               ["subject"]     = "speaker",
            }
            local mapped = MAPPING[self.run_on]
            if mapped and mapped == self.actor then
               return true
            end
         end
         return false
      end
      function instance_members:_to_native_compatible_table_impl()
         local t = {
            comparison = {
               operator = self.equals and "==" or "!=",
               operand  = 1
            }
         }
         self:_set_condition_run_on(t)
         if self.actor then
            t.function_name = "GetInSameCell"
            
            local param
            if self.actor == "speaker" then
               error("can't specify the speaker as a parameter")
            elseif self.actor == "player" then
               param = dovah.get_form_by_id(0x14)
            elseif self.actor == "subject" then
               t.override_types_with = "alias"
               param = self.quest_info.alias_for_actor_to_find
            end
            t.parameters = { param }
         else
            t.function_name = "GetInCell"
            t.parameters    = { self.cell }
         end
         return t
      end
   end
end