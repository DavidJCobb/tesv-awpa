
if not awpa then
   awpa = {}
end

do
   local instance_members = {}
   awpa.scope = make_class({
      constructor = function(self)
         self.condition_sets = {}
         self.constants      = {}
      end,
      instance_members = instance_members,
   })
   
   function instance_members:resolve_constant(name)
      local v = self.constants[name]
      if v then
         return v
      end
      if awpa.scope.is(self.parent) then
         return self.parent:resolve_constant(name)
      end
      return nil
   end
end