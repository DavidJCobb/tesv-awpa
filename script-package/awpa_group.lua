
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
         
         self.path = self:get_unique_path()
      end
      function instance_members:get_relevant_conditions()
         if not awpa.group.is(self.parent) then
            return { table.unpack(self.conditions) }
         end
         local out = self.parent:get_relevant_conditions()
         local j   = #out + 1
         for i = 1, #self.conditions do
            out[j] = self.conditions[i]
            j = j + 1
         end
         return out
      end
      function instance_members:get_unique_path()
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
         local last_line =  nil
         
         local size = #self.lines
         for i = 1, size do
            local path           = self:get_unique_path()
            local line           = self.lines[i]
            local info_m, info_f = line:generate_info(topic)
            info_m.responses[1].edits = "[generated-from=" .. path .. "]"
            if info_f then
               info_f.responses[1].edits = "[fem-of=" .. info_m:form_id_to_string() .. "]"
            end
            for j = 1, #conditions do
               conditions[j]:apply_to_info(info_m, self)
               if info_f then
                  conditions[j]:apply_to_info(info_f, self)
               end
            end
            last_line = info_f or info_m
         end
         for i = 1, #self.shared_infos do
            local si = self.shared_infos[i]
            for j = 1, #si.forms do
               local si_form = si.forms[j]
               local gender  = nil
               do
                  local id = si_form.editor_id
                  local c  = id:sub(#id)
                  if c == "M" then
                     gender = "Male"
                  elseif c == "F" then
                     gender = "Female"
                  end
               end
               local info = dovah.create_form(form_types.topic_info, { parent = topic })
               info.use_shared_info = si_form
               info.is_random       = true
               if gender then
                  local cnd = info.conditions:insert()
                  cnd.run_on              = alias
                  cnd.function_name       = "GetIsSex"
                  cnd.parameters[1]       = gender
                  cnd.comparison.operator = "=="
                  cnd.comparison.operand  = 1
               end
               for j = 1, #conditions do
                  conditions[j]:apply_to_info(info, self)
               end
               last_line = info
            end
         end
         
         if self.exclusive and last_line then
            last_line.is_random_end = true
         end
      end
   end
end