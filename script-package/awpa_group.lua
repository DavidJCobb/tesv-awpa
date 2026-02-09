
do
   local instance_members = {}
   awpa.group = make_class({
      superclass  = awpa.scope,
      constructor = function(self)
         self.id           = nil
         self.name         = nil
         self.parent       = nil
         self.exclusive    = true
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
      function instance_members:get_unique_path(element)
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
         for i = 1, #self.groups do
            local child = self.groups[i]
            child:generate_lines(topic)
         end
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
         end
      end
   end
end