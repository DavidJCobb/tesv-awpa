
do
   local instance_members = {}
   awpa.scope = make_class({
      constructor = function(self)
         self.condition_sets    = {}
         self.constants         = {}
         self.constants_by_name = {}
      end,
      instance_members = instance_members,
   })
   
   function instance_members:resolve_condition_set(name)
      for i = 1, #self.condition_sets do
         local cs = self.condition_sets[i]
         if cs.name == name then
            return cs
         end
      end
      if awpa.scope.is(self.parent) then
         return self.parent:resolve_condition_set(name)
      end
      return nil
   end
   
   function instance_members:resolve_constant(name)
      local v = self.constants_by_name[name]
      if v then
         return v
      end
      if awpa.scope.is(self.parent) then
         return self.parent:resolve_constant(name)
      end
      return nil
   end
end