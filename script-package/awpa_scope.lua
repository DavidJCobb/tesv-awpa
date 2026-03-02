
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
   
   function instance_members:_consume_xml_child_as_scope(node)
      if node.node_name == "condition-set" then
         local cset = awpa.condition_set()
         local list = self.condition_sets
         list[#list + 1] = cset
         cset:from_xml(node)
         cset.owning_scope = scope
         awpa.condition.construct_list_from_xml(cset, self, node)
         return true
      end
      if node.node_name == "constant" then
         local item = awpa.constant()
         local list = self.constants
         list[#list + 1] = item
         item:from_xml(node)
         self.constants_by_name[item.name] = item
         return true
      end
      return false
   end
   
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