
do
   local instance_members = {}
   awpa.group = make_class({
      superclass  = awpa.scope,
      constructor = function(self)
         self.id           = nil
         self.name         = nil
         self.parent       = nil
         self.exclusive    = true
         self.conditions   = {}
         self.groups       = {}
         self.lines        = {}
         self.shared_infos = {} -- references to shared_info_set instances used by this group
      end,
      instance_members = instance_members,
   })
   do -- member functions
      function instance_members:from_xml(element)
         self.name = element.attributes["name"]
         awpa.env:set_object_id(self, element.attributes["id"])
         
         local v = element.attributes["non-exclusive"]
         if v == "true" then
            self.exclusive = false
         end
      end
      function instance_members:get_relevant_conditions()
         if not awpa.group.is(self.parent) then
            return { table.unpack(self.conditions) }
         end
         return table.concat(
            self.parent:get_relevant_conditions(),
            self.conditions
         )
      end
      function instance_members:get_unique_path(element)
         --
         -- PATH SYNTAX FOR A LINE:
         --
         --    #something-with-an-id
         --    #something-with-an-id/something/with/a/name
         --    #something-with-an-id/something/with/no/name/@line-index
         --
         if self.id then
            return "#" .. self.id
         end
         if self.parent then
            local ancestor
            if awpa.group:is(self.parent) then
               ancestor = self.parent:get_unique_path()
            elseif awpa.quest:is(self.parent) then
               ancestor = "#" .. self.parent.id
            else
               error("unknown ancestor type")
            end
            if self.name then
               return ancestor .. "/" .. self.name
            end
            
            for i = 1, #self.parent.groups do
               local g = self.parent.groups[i]
               if g == self then
                  return ancestor .. "/@" .. tostring(i)
               end
            end
            error("unable to build path; inconsistent parent/child relationship")
         end
         error("unable to build path with no ID to base it on")
      end
      function instance_members:generate_lines(topic)
         local quest = topic.parent_quest
         local alias = quest.aliases["ActorToFind"]
      
         for i = 1, #self.groups do
            local child = self.groups[i]
            child:generate_lines(topic)
         end
         
         local conditions = self:get_relevant_conditions()
         
         local size = #self.lines
         for i = 1, size do
            local path           = self:get_unique_path()
            local line           = self.lines[i]
            local info_m, info_f = line:generate_info(topic)
            info_m.responses[1].edits = "[generated-from=" .. path .. "]"
            if info_f then
               info_f.responses[1].edits = "[fem-of=" .. info_m:form_id_to_string() .. "]"
            end
            if self.exclusive and i == size then
               (info_f or info_m).is_random_end = true
            end
            for j = 1, #conditions do
               conditions[j]:apply_to_info(info_m, self)
               if info_f then
                  conditions[j]:apply_to_info(info_f, self)
               end
            end
         end
         for i = 1, #self.shared_infos do
            local si = self.shared_infos[i]
            for j = 1, #si.forms do
               local si_form = si.forms[j]
               local gender  = nil
               do
                  local id = si_form.editor_id
                  local c  = id:sub(#id - 1)
                  if c == "M" then
                     gender = 0
                  elseif c == "F" then
                     gender = 1
                  end
               end
               local info = dovah.create_form(form_types.topic_info, { parent = topic })
               info.use_shared_info = si_form
               if gender then
                  local cnd = info.conditions:insert()
                  cnd.run_on              = alias
                  cnd.function_name       = "GetSex"
                  cnd.comparison.operator = "=="
                  cnd.comparison.operand  = gender
               end
               for j = 1, #conditions do
                  conditions[j]:apply_to_info(info, self)
               end
            end
         end
      end
   end
end