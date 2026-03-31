
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
            if self.run_on == self.actor then
               return true
            end
         end
         return false
      end
      function instance_members:overwrite_condition(cnd)
         self:_set_condition_common(cnd)
         self:_set_condition_run_on(cnd)
         
         if self.actor then
            cnd.function_name = "GetInSameCell"
            if self.actor == "player" then
               cnd.parameters[1] = dovah.get_form_by_id(0x14)
            elseif self.actor == "speaker" then
               error("can't specify the speaker as a parameter")
            elseif self.actor == "subject" then
               cnd.override_types_with = "alias"
               cnd.parameters[1] = self.quest_info.form.aliases["ActorToFind"]
            end
         else
            cnd.function_name = "GetInCell"
            cnd.parameters[1] = self.cell
         end
         if self.equals then
            cnd.comparison.operator = "=="
         else
            cnd.comparison.operator = "!="
         end
         cnd.comparison.operand  = 1
      end
   end
end