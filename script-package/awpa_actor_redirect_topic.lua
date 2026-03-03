
do
   local instance_members = {}
   awpa.actor_redirect_topic = make_class({
      superclass  = awpa.actor_redirect,
      constructor = function(
         self,
         actor_info,
         
         -- Format string. Params:
         --  - quest editor ID
         --  - actor editor ID
         --  - slug, if specified
         topic_editor_id_format,
         
         -- Format string. Params:
         --  - quest editor ID
         --  - actor editor ID
         --  - slug, if specified
         link_info_editor_id_format
      )
         self.forms.topic  = nil
         self.topic_helper = nil
         
         self.slug     = ""
         self.children = {} -- vector<variant<awpa.line, awpa.group, awpa.shared_info_reference>>
         
         self.topic_editor_id_format = topic_editor_id_format
         
         self.link_info_editor_id_format = link_info_editor_id_format
         
         self.topic_text = "<Redirect>"
      end,
      instance_members = instance_members,
   })
   do -- member functions
      function instance_members:visit_topic_helpers(visitor)
         visitor(self.topic_helper)
      end
      
      function instance_members:from_xml(element)
         if element.attributes["slug"] then
            self.slug = element.attributes["slug"]
         end
         
         element:for_each_child_element(function(node)
            if node.node_name == "conditions" then
               awpa.condition.construct_list_from_xml(self, self.quest_info, node)
               return
            end
            
            if node.node_name == "g" then
               local item = awpa.group()
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
               local si = awpa.env.shared_infos_by_id[node.attributes["id"]]
               if not si then
                  error("missing sharedinfo")
               end
               local item = awpa.shared_info_reference()
               local list = self.children
               list[#list + 1] = item
               item.source = si
               item:from_xml(node)
               return
            end
            error("unexpected element: " .. node.node_name)
         end)
      end
      function instance_members:amend_xml_clone(nodemap)
         for i = 1, #self.children do
            self.children[i]:amend_xml_clone(nodemap)
         end
      end
      
      function instance_members:get_or_create_topic()
         local topic = self.forms.topic
         if topic then
            return topic
         end
         local branch    = self.quest_info.branch
         local editor_id = string.format(
            self.topic_editor_id_format,
            --
            self.quest_info.form.editor_id,
            self.actor_info.form.editor_id,
            self.slug
         )
         do
            local topics = branch:get_all_topics()
            for i = 1, #topics do
               local t = topics[i]
               if t.editor_id == editor_id then
                  self.forms.topic  = t
                  self.topic_helper = awpa.topic_helper(t)
                  return t
               end
            end
         end
         topic = dovah.create_form(form_types.topic, { parent = branch })
         topic.editor_id = editor_id
         topic.text      = self.topic_text or "<Redirect>"
         self.forms.topic  = topic
         self.topic_helper = awpa.topic_helper(topic)
         return topic
      end
      
      function instance_members:generate_content(redirect_from_topic)
         local topic = self:get_or_create_topic()
         topic.text = self.topic_text or "<Redirect>"
         do
            local info = utils.make_invisible_info(
               redirect_from_topic,
               string.format(
                  self.link_info_editor_id_format,
                  --
                  self.quest_info.form.editor_id,
                  self.actor_info.form.editor_id,
                  self.slug
               ),
               topic
            )
            self.forms.inbound_link = info
            
            utils.replace_condition_list(info, {
               run_on        = "subject",
               function_name = "GetIsId",
               parameters    = { self.actor_info.form },
               comparison    = {
                  operator = "==",
                  operand  = 1,
               }
            })
            utils.append_condition_list(info, self.conditions)
         end
         
         for i = 1, #self.children do
            local item = self.children[i]
            if awpa.group.is(item) then
               item:generate_infos(topic, self.topic_helper)
            elseif awpa.line.is(item) then
               local a, b = item:generate_infos(topic)
               self.topic_helper:append_desired_info(a)
               if b then
                  self.topic_helper:append_desired_info(b)
               end
            else
               error("unrecognized object type")
            end
         end
         
         local list = topic.infos
         for i = 1, #list do
            local info = list[i]
            info.speaker = self.actor_info.form
         end
      end
   end
end