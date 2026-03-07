
do
   local instance_members = {}
   awpa.scope = make_class({
      constructor = function(self, quest_info)
         self.quest_info = quest_info
         if not awpa.quest.is(quest_info) then
            error("no quest info")
         end
      
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
         awpa.condition.construct_list_from_xml(node, cset.conditions, {
            allow_condition_set = false,
            scope               = self,
            quest_info          = self.quest_info,
         })
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
   
   function instance_members:_do_scoped_lookup(functor)
      local result = functor(self)
      if result then
         return result
      end
      local scope = self.parent
      while scope do
         if awpa.scope.is(scope) then
            result = functor(scope)
            if result then
               break
            end
            scope = scope.parent
         elseif awpa.actor_redirect.is(scope) then -- HACK HACK HACK
            scope = scope.quest_info
         else
            return
         end
      end
      return result
   end
   
   function instance_members:resolve_condition_set(name)
      return self:_do_scoped_lookup(function(scope)
         for i = 1, #scope.condition_sets do
            local cs = scope.condition_sets[i]
            if cs.name == name then
               return cs
            end
         end
      end)
   end
   
   function instance_members:resolve_constant(name)
      return self:_do_scoped_lookup(function(scope)
         return scope.constants_by_name[name]
      end)
   end
end