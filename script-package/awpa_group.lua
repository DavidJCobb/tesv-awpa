
do
   local instance_members = {}
   awpa.group = make_class({
      superclass  = awpa.scope,
      constructor = function(self, quest_info)
         self.source_xml_node = nil
         
         self.id         = nil
         self.name       = nil
         self.parent     = nil -- variant<awpa.group, awpa.top_level_group, awpa.quest, awpa.actor_redirect>
         self.exclusive  = true
         self.conditions = {}
         self.children   = {} -- vector<variant<awpa.group, awpa.line, awpa.shared_info_reference>>
      end,
      instance_members = instance_members,
   })
   do -- member functions
      function instance_members:from_xml(element)
         self.source_xml_node = element
         
         self.name = element.attributes["name"]
         awpa.env:set_object_id(self, element.attributes["id"])
         
         local v = element.attributes["non-exclusive"]
         if v == "true" then
            self.exclusive = false
         end
         
         element:for_each_child_element(function(node)
            if self:_consume_xml_child_as_scope(node) then
               return
            end
            if node.node_name == "conditions" then
               awpa.condition.construct_list_from_xml(node, self.conditions, {
                  scope      = self,
                  quest_info = self.quest_info,
               })
               return
            end
            if node.node_name == "g" then
               local item = awpa.group(self.quest_info)
               local list = self.children
               list[#list + 1] = item
               item.parent = self
               item:from_xml(node)
               return
            end
            if node.node_name == "line" then
               local item = awpa.line()
               local list = self.children
               list[#list + 1] = item
               item:from_xml(node)
               return
            end
            if node.node_name == "shared-info" then
               local item = awpa.shared_info_reference()
               local list = self.children
               list[#list + 1] = item
               item:from_xml(node)
               return
            end
            error("invalid child of a `g`: " .. node.node_name)
         end)
      end
      function instance_members:amend_xml_clone(nodemap)
         for i =  1, #self.children do
            self.children[i]:amend_xml_clone(nodemap)
         end
      end
      
      function instance_members:get_relevant_conditions()
         local out
         if not awpa.group.is(self.parent) then
            if awpa.env.generate_flat_results and awpa.top_level_group.is(self.parent) then
               out = { table.unpack(self.parent.conditions) }   
            else
               return { table.unpack(self.conditions) }
            end
         else
            out = self.parent:get_relevant_conditions()
         end
         local j = #out + 1
         for i = 1, #self.conditions do
            out[j] = self.conditions[i]
            j = j + 1
         end
         return out
      end
      function instance_members:generate_infos(topic, topic_helper)
         local conditions = self:get_relevant_conditions()
         local last_line =  nil
         
         for i = 1, #self.children do
            local item = self.children[i]
            if awpa.line.is(item) then
               local a, b = item:generate_infos(topic)
               for j = 1, #conditions do
                  local c = conditions[j]
                  c:apply_to_info(a)
                  if b then
                     c:apply_to_info(b)
                  end
               end
               topic_helper:append_desired_info(a)
               if b then
                  topic_helper:append_desired_info(b)
               end
               --
               last_line = b or a
            elseif awpa.group.is(item) then
               local th_infos   = topic_helper.infos.desired_order
               local last_prior = th_infos[#th_infos]
               item:generate_infos(topic, topic_helper)
               local last_after = th_infos[#th_infos]
               if last_prior ~= last_after then
                  last_line = last_after
               end
            elseif awpa.shared_info_reference.is(item) then
               item:generate_infos(topic)
               local size = #item.forms
               for i = 1, size do
                  local info = item.forms[i]
                  for j = 1, #conditions do
                     conditions[j]:apply_to_info(info)
                  end
                  topic_helper:append_desired_info(info)
               end
               if size > 0 then
                  last_line = item.forms[size]
               end
            end
         end
         if self.exclusive and last_line then
            last_line.is_random_end = true
         end
      end
   end
end