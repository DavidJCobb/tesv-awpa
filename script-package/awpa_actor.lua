
do
   local instance_members = {}
   awpa.actor = make_class({
      constructor = function(self, quest_info)
         self.source_xml_node = nil
         
         self.quest_info = quest_info
         self.editor_id  = nil
         self.name       = nil
         self.form       = nil
         self.overrides  = {
            begin_asking_about = {
               --
               -- Override whether other actors can be asked about this actor.
               --
               conditions = {},
            },
            begin_asking_to = {
               --
               -- Override this actor's responses to "Can you help me find someone?"
               --
               bribe   = nil, -- optional<awpa.actor_override_bribe>
               results = {},  -- vector<variant<awpa.group, awpa.line>>
            },
            begin_responding = {
               --
               -- Override this actor's responses to inquiries about any other actor.
               --
               conditions = {},
               results    = {}, -- vector<variant<awpa.group, awpa.line>>
            },
         }
      end,
      instance_members = instance_members,
   })
   do -- member functions
      function instance_members:visit_topic_helpers(visitor)
         if self.overrides.begin_asking_to.bribe then
            self.overrides.begin_asking_to.bribe:visit_topic_helpers(visitor)
         end
         -- TODO
      end
   
      function instance_members:from_xml(element)
         self.source_xml_node = element
         
         self.editor_id = element.attributes["editor-id"]
         self.name      = element.attributes["name"]
         if not self.name then
            self.name = self.editor_id
         end
         if not self.editor_id then
            error("Actor is missing an editor ID")
         end
         self.form = dovah.get_form_by_editor_id(self.editor_id, form_types.actor_base)
         if not self.form then
            error("Actor failed to find its form: " .. self.editor_id)
         end
         
         element:for_each_child_element(function(node)
            if node.node_name == "begin-asking-about" then
               local over = self.overrides.begin_asking_about
               node:for_each_child_element(function(node)
                  if node.node_name == "conditions" then
                     awpa.condition.construct_list_from_xml(over, self.quest_info, node)
                     for i = 1, #over.conditions do
                        over.conditions[i].is_override = self
                     end
                  else
                     error("unexpected element: " .. node.node_name)
                  end
               end)
            elseif node.node_name == "begin-asking-to" then
               local over = self.overrides.begin_asking_to
               node:for_each_child_element(function(node)
                  if node.node_name == "bribe" then
                     local bribe = over.bribe
                     if not bribe then
                        over.bribe = awpa.actor_override_bribe(self.quest_info, self)
                        bribe = over.bribe
                     end
                     bribe:from_xml(node)
                  elseif node.node_name == "line" then
                     local list = over.results
                     local item = awpa.line()
                     list[#list + 1] = item
                     item:from_xml(node)
                  elseif node.node_name == "g" then
                     local list  = over.results
                     local child = awpa.group()
                     list[#list + 1] = child
                     child.parent = nil
                     child:from_xml(node)
                  else
                     error("unexpected element: " .. node.node_name)
                  end
               end)
            elseif node.node_name == "begin-responding" then
               -- TODO
            else
               error("unexpected element: " .. node.node_name)
            end
         end)
      end
      function instance_members:amend_xml_clone(nodemap)
         do
            local node <const> = nodemap[self.source_xml_element]
            node.attributes["editor-id"] = self.editor_id
            if self.name == self.editor_id then
               node.attributes["name"] = nil
            else
               node.attributes["name"] = self.name
            end
         end
         -- sub-objects:
         do
            local item = self.overrides.begin_asking_to.bribe
            if item then
               item:amend_xml_clone(nodemap)
            end
         end
      end
      
   end
end