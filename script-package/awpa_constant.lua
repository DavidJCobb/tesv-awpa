
if not awpa then
   awpa = {}
end

do
   local instance_members = {}
   awpa.constant = make_class({
      constructor = function(self)
         self.name  = nil
         self.value = nil
      end,
      instance_members = instance_members,
   })
   do -- member functions
      function instance_members:from_xml(element)
         local n = element.attributes["name"]
         if n then
            self.name = n
         else
            -- TODO: error
         end
      
         local v = tonumber(element.attributes["value"])
         if v then
            self.value = v
         end
      end
   end
end