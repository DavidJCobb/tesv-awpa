
if not awpa then
   awpa = {}
end

do
   local instance_members = {}
   awpa.condition = make_class({
      constructor = function(self)
         self.run_on        = nil
         self.function_name = nil
         self.parameters    = { nil, nil }
         self.comparison = {
            operator = "==",
            operand  = 1,
         }
         self.is_or_linked = false
      end,
      instance_members = instance_members,
   })
   do -- member functions
      local function _parse_run_on(s)
         if s == "subject" then
            return "ActorToFind"
         elseif s == "speaker" then
            return "subject"
         elseif s == "player" then
            return "player"
         end
      end
   
      function instance_members:_extract_numeric_comparison(element)
         local MAPPING = {
            eq  = "==",
            neq = "!=",
            lt  = "<",
            lte = "<=",
            gt  = ">",
            gte = ">=",
         }
         for k, v in pairs(MAPPING) do
            local operand = element.attributes[k]
            if operand then
               self.comparison.operator = v
               self.comparison.operand  = tonumber(operand) or operand
               return
            end
         end
      end
      function instance_members:_extract_run_on(element)
         self.run_on = _parse_run_on(element.attributes["of"])
      end
   
      function instance_members:from_xml(element)
         if element.node_name == "actor-base" then
            self:_extract_run_on(element)
            self.function_name = "GetIsID"
            self.comparison.operand = 1
            do
               local v = element.attributes["is"]
               if v then
                  local form = dovah.get_form_by_editor_id(v, form_types.actor_base)
                  if not form then
                     error("NPC_ not found: " .. v)
                  end
                  self.parameters[1] = form
                  self.comparison.operator = "=="
               end
            end
            do
               local v = element.attributes["is-not"]
               if v then
                  local form = dovah.get_form_by_editor_id(v, form_types.actor_base)
                  if not form then
                     error("NPC_ not found: " .. v)
                  end
                  self.parameters[1] = form
                  self.comparison.operator = "!="
               end
            end
            return
         end
         if element.node_name == "death-count" then
            self.run_on = "subject"
            self.function_name = "GetDeadCount"
            local v = element.attributes["for"]
            if not v then
               error("no ActorBase specified")
            end
            local form = dovah.get_form_by_editor_id(v, form_types.actor_base)
            if not form then
               error("NPC_ not found: " .. v)
            end
            self.parameters[1] = form
            self:_extract_numeric_comparison(element)
            return
         end
         if element.node_name == "enable-state" then
            self.run_on = element.attributes["for"]
            self.function_name = "GetDisabled"
            self.comparison.operand = 1
            do
               local v = element.attributes["is"]
               if v == "enabled" then
                  self.comparison.operator = "!="
               else
                  self.comparison.operator = "=="
               end
            end
            return
         end
         if element.node_name == "global" then
            self.run_on = "subject"
            self.function_name = "GetGlobalValue"
            do
               local glob = element.attributes["name"]
               if not glob then
                  error("GLOB not specified")
               end
               local form = dovah.get_form_by_editor_id(glob, form_types.global)
               if form then
                  self.parameters[1] = form
               else
                  error("GLOB not found: " .. glob)
               end
            end
            self:_extract_numeric_comparison(element)
            return
         end
         if element.node_name == "location" then
            self:_extract_run_on(element)
            self.function_name = "GetInCurrentLoc"
            self.comparison.operand = 1
            do
               local v = element.attributes["is"]
               if v then
                  local form = dovah.get_form_by_editor_id(v, form_types.location)
                  if not form then
                     error("LCTN not found: " .. v)
                  end
                  self.parameters[1] = form
                  self.comparison.operator = "=="
               end
            end
            do
               local v = element.attributes["is-not"]
               if v then
                  local form = dovah.get_form_by_editor_id(v, form_types.location)
                  if not form then
                     error("LCTN not found: " .. v)
                  end
                  self.parameters[1] = form
                  self.comparison.operator = "!="
               end
            end
            return
         end
         if element.node_name == "papyrus-quest-variable" then
            self.function_name = "GetVMQuestVariable"
            do
               local quest = element.attributes["for"]
               if not quest then
                  error("QUST not specified")
               end
               local form = dovah.get_form_by_editor_id(quest, form_types.quest)
               if form then
                  self.parameters[1] = form
               else
                  error("QUST not found: " .. glob)
               end
            end
            self.parameters[2] = element.attributes["var"]
            self:_extract_numeric_comparison(element)
            return
         end
         if element.node_name == "parent-cell" then
            self:_extract_run_on(element)
            if element.attributes["same-as"] then
               self.function_name = "GetInSameCell"
               do
                  local other = element.attributes["same-as"]
                  self.parameters[1] = _parse_run_on(other)
               end
               self.comparison.operator = "=="
               self.comparison.operand  = 1
            elseif element.attributes["is"] or element.attributes["is-not"] then
               self.function_name = "GetInCell"
               self.parameters[1] = element.attributes["is"] or element.attributes["is-not"]
               if not self.parameters[1] then
                  error("no cell specified")
               end
               self.parameters[1] = dovah.get_form_by_editor_id(self.parameters[1], form_types.cell)
               if not self.parameters[1] then
                  error("CELL not found")
               end
               if element.attributes["is"] then
                  self.comparison.operator = "=="
               else
                  self.comparison.operator = "!="
               end
               self.comparison.operand = 1
            end
            return
         end
         if element.node_name == "quest-stage" then
            local quest
            do
               local v = element.attributes["for"]
               if not v then
                  error("no quest specified (missing/empty `for` attribute)")
               end
               quest = dovah.get_form_by_editor_id(v, form_types.quest)
               if not quest then
                  error("QUST not found: " .. v)
               end
            end
         
            self.run_on = "subject"
            do
               local v = element.attributes["done"]
               if v then
                  self.function_name = "GetStageDone"
                  self.parameters[1] = quest
                  self.parameters[2] = v
                  self.comparison    = {
                     operator = "==",
                     operand  = 1
                  }
                  return
               end
            end
            do
               local v = element.attributes["not-done"]
               if v then
                  self.function_name = "GetStageDone"
                  self.parameters[1] = quest
                  self.parameters[2] = v
                  self.comparison    = {
                     operator = "==",
                     operand  = 0
                  }
                  return
               end
            end
            self.function_name = "GetStage"
            self.parameters[1] = quest
            self:_extract_numeric_comparison(element)
            return
         end
         if element.node_name == "x"
         or element.node_name == "y"
         or element.node_name == "z"
         then
            self:_extract_run_on(element)
            self.function_name = "GetPos"
            self.parameters[1] = element.node_name
            self:_extract_numeric_comparison(element)
            if element.attributes["at"] then
               self.pos_at = tonumber(element.attributes["at"])
               local span  = element.attributes["around"]
               if span then
                  self.half_extent = tonumber(span) / 2
               else
                  self.half_extent = tonumber(element.attributes["within"])
               end
            end
            return
         end
      end
      function instance_members:apply_to_info(info, scope)
         local quest = info.parent_quest
      
         local cnd = info.conditions:insert()
         cnd.function_name = self.function_name
         do -- run on
            if self.run_on == "subject"
            or self.run_on == "player"
            or not self.run_on
            then
               cnd.run_on = self.run_on
            elseif self.run_on == "ActorToFind" then
               cnd.run_on = quest.aliases["ActorToFind"]
            end
         end
         
         if self.function_name == "GetPos" then
            cnd.parameters[1] = self.parameters[1]
            
            if self.pos_at and self.half_extent then
               if self.is_or_linked then
                  error("can't make a pos range condition OR-linked")
               end
            
               cnd.comparison.operator = ">="
               cnd.comparison.operator = self.pos_at - self.half_extent
               
               cnd = info.conditions:insert()
               cnd.function_name = self.function_name
               cnd.run_on        = self.run_on or "subject"
               cnd.parameters[1] = self.parameters[1]
               cnd.comparison.operator = "<="
               cnd.comparison.operator = self.pos_at + self.half_extent
               return
            end
         end
         
         local v = self.comparison.operand
         if type(v) == "string" then
            v = scope:resolve_constant(v)
            if not v then
               error("unrecognized constant name: " .. self.comparison.operand)
            end
         end
         cnd.comparison.operator = self.comparison.operator
         cnd.comparison.operand  = v
         
         for i = 1, #self.parameters do
            local src = self.parameters[i]
            if src then
               if object_is_form(src) then
                  cnd.parameters[i] = src
               elseif tonumber(src) then
                  cnd.parameters[i] = tonumber(src)
               elseif tostring(src) then
                  if self.function_name == "GetInSameCell" then
                     if src == "player" then
                        cnd.parameters[i] = dovah.get_form_by_id(0x14)
                     elseif src == "subject" then
                        cnd.override_types_with = "alias"
                        cnd.parameters[i] = quest.aliases["ActorToFind"]
                     end
                  elseif self.function_name == "GetPos"
                  or     self.function_name == "GetVMQuestVariable"
                  then
                     cnd.parameters[i] = src
                  else
                     dovah.dump(self)
                     error("unhandled case")
                  end
               end
            end
         end
         
         cnd.is_or_linked = self.is_or_linked
      end
   end
end