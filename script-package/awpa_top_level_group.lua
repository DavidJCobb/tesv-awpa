
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
      
      function instance_members:get_or_create_topic()
         if self.topic then
            if not self.topic_helper then
               self.topic_helper = awpa.topic_helper(self.topic)
            end
            return self.topic
         end
         if not self.parent then
            error("awpa.top_level_group instance can't find its parent awpa.quest")
         end
         local branch    = self.parent.branch
         local editor_id = string.format("%sResultsTopic%s", self.parent.form.editor_id, self.editor_id_slug)
         do
            local topics = branch:get_all_topics()
            for i = 1, #topics do
               local t = topics[i]
               if t.editor_id == editor_id then
                  self.topic        = t
                  self.topic_helper = awpa.topic_helper(t)
                  return t
               end
            end
         end
         local topic = dovah.create_form(form_types.topic, { parent = branch })
         topic.editor_id = editor_id
         topic.text      = "<Results Group>"
         self.topic        = topic
         self.topic_helper = awpa.topic_helper(topic)
         return topic
      end
      function instance_members:create_link_info(from_topic_helper, pre_existing_infos)
         local src_topic = from_topic_helper.form
         local dst_topic = self:get_or_create_topic()
         if not pre_existing_infos then
            pre_existing_infos = src_topic.infos
         end
         
         local link
         for i = 1, #pre_existing_infos do
            local pei = pre_existing_infos[i]
            if pei.link_to[1] == dst_topic then
               link = pei
               break
            end
         end
         if not link then
            link = dovah.create_form(form_types.topic_info, { parent = src_topic })
            link.use_shared_info = awpa.env.built_in_shared_infos["InvisibleInfo"][1]
            link.link_to:insert(dst_topic)
            link.invisible_continue = true
         end
         from_topic_helper:append_desired_info(link)
         utils.replace_condition_list(link, {})
         for i = 1, #self.conditions do
            self.conditions[i]:apply_to_info(link)
         end
         
         return link
      end
      
      function instance_members:generate_children()
         local topic        = self:get_or_create_topic()
         local topic_helper = self.topic_helper
         for i = 1, #self.children do
            local item = self.children[i]
            if awpa.line.is(item) then
               local a, b = item:generate_infos(topic)
               topic_helper:append_desired_info(a)
               if b then
                  topic_helper:append_desired_info(b)
               end
            elseif awpa.group.is(item) then
               item:generate_infos(topic, topic_helper)
            elseif awpa.shared_info_reference.is(item) then
               item:generate_infos(topic)
               for i = 1, #item.forms do
                  topic_helper:append_desired_info(item.forms[i])
               end
            end
         end
      end
   end
end