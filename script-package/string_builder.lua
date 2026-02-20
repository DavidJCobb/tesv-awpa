
do
   local instance_members = {}
   string_builder = make_class({
      constructor = function()
         self.chunks = {}
         self.count  = 0
         self.size   = nil
      end,
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
   end
end