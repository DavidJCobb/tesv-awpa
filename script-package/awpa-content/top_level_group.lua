
if not awpa then
   error("incorrect file order")
end

do
   local instance_members = {}
   awpa.top_level_group = make_class({
      superclass  = awpa.scope,
      constructor = function(self, quest_info)
         self.source_xml_node = nil
         
         self.parent         = nil -- awpa.quest
         self.topic          = nil -- topic
         self.topic_helper   = nil -- awpa.topic_helper
         self.conditions     = {} -- vector<awpa.condition>
         self.children       = {} -- vector<variant<awpa.group, awpa.line, awpa.shared_info_reference>>
         self.editor_id_slug = nil -- string
      end,
      instance_members = instance_members,
   })
   do -- member functions
      function instance_members:from_xml(element)
         self.source_xml_node = element
         
         self.name = element.attributes["name"]
         awpa.env:set_object_id(self, element.attributes["id"])
         
         self.editor_id_slug = element.attributes["slug"]
         if not self.editor_id_slug then
            error("attribute `slug` is required")
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
            error("unexpected element: " .. node.node_name)
         end)
      end
      function instance_members:amend_xml_clone(nodemap)
         for i =  1, #self.children do
            self.children[i]:amend_xml_clone(nodemap)
         end
      end
   end
end