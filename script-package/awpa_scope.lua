
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
end