
do
   local instance_members = {}
   string_builder = make_class({
      constructor = function(self)
         self.chunks = {}
         self.count  = 0
         self.size   = 0
      end,
      instance_members = instance_members,
   })
   do -- member functions
      function instance_members:append(t)
         t = tostring(t)
         local i = self.count + 1
         self.chunks[i] = t
         self.count = i
         self.size  = self.size + #t
      end
      function instance_members:write_to(file)
         for i = 1, self.count do
            file:write(self.chunks[i])
         end
      end
      function instance_members:to_string()
         return table.concat(self.chunks)
      end
   end
end