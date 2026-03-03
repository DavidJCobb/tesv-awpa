
do
   local instance_members = {}
   awpa.actor = make_class({
      constructor = function(self, quest_info)
         self.source_xml_node = nil
         
         self.quest_info = quest_info
         self.editor_id  = nil
         self.name       = nil
         self.form       = nil
         self.redirects  = {
            begin_asking_to  = {}, -- vector<awpa.actor_redirect>
            begin_responding = {}, -- vector<awpa.actor_redirect>
         }
         self.overrides  = {
            begin_asking_about = {
               --
               -- Override whether other actors can be asked about this actor.
               --
               conditions = {},
            },
         }
      end,
      instance_members = instance_members,
   })
   do -- member functions
      function instance_members:visit_topic_helpers(visitor)
         for _, list in pairs(self.redirects) do
            for _, item in ipairs(list) do
               item:visit_topic_helpers(visitor)
            end
         end
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
            local function reject_multiple_nameless_redirect_topics(list, node)
               local has_nameless = false
               for i = 1, #list do
                  if awpa.actor_redirect_topic.is(list[i]) then
                     if list[i].slug == "" then
                        has_nameless = true
                        break
                     end
                  end
               end
               if has_nameless then
                  if not node.attributes["slug"] or node.attributes["slug"] == "" then
                     error("cannot have more than one unnamed redirect topic here; specify a `slug`")
                  end
               end
            end
         
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
               local list = self.redirects.begin_asking_to
               node:for_each_child_element(function(node)
                  if node.node_name == "bribe" then
                     for i = 1, #list do
                        if awpa.actor_redirect_bribe.is(list[i]) then
                           error("this actor has multiple bribe redirects")
                        end
                     end
                     local bribe = awpa.actor_redirect_bribe(self)
                     list[#list + 1] = bribe
                     --
                     bribe:from_xml(node)
                  elseif node.node_name == "topic" then
                     reject_multiple_nameless_redirect_topics(list, node)
                     local item = awpa.actor_redirect_topic(
                        self,
                        "%sTopic%sRedirectFromStart%s",
                        "%sLinkInfo%sRedirectFromStart%s"
                     )
                     list[#list + 1] = item
                     --
                     item:from_xml(node)
                     item.topic_text = string.format("<override start via: %s>", self.form.editor_id)
                  else
                     error("unexpected element: " .. node.node_name)
                  end
               end)
            elseif node.node_name == "begin-responding" then
               local list = self.redirects.begin_responding
               node:for_each_child_element(function(node)
                  if node.node_name == "topic" then
                     reject_multiple_nameless_redirect_topics(list, node)
                     local item = awpa.actor_redirect_topic(
                        self,
                        "%sTopic%sRedirectAnswer%s",
                        "%sLinkInfo%sRedirectAnswer%s"
                     )
                     list[#list + 1] = item
                     --
                     item:from_xml(node)
                     item.topic_text = string.format("<override answer from: %s>", self.form.editor_id)
                  else
                     error("unexpected element: " .. node.node_name)
                  end
               end)
            else
               error("unexpected element: " .. node.node_name)
            end
         end)
      end
      function instance_members:amend_xml_clone(nodemap)
         do
            local node <const> = nodemap[self.source_xml_node]
            node.attributes["editor-id"] = self.editor_id
            if self.name == self.editor_id then
               node.attributes["name"] = nil
            else
               node.attributes["name"] = self.name
            end
         end
         -- sub-objects:
         for _, list in pairs(self.redirects) do
            for _, item in ipairs(list) do
               item:amend_xml_clone(nodemap)
            end
         end
      end
      
   end
end