
if not awpa then
   error("incorrect file order")
end

do
   local instance_members = {}
   awpa.top_level_group = make_class({
      superclass  = awpa.scope,
      constructor = function(self)
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
               awpa.condition.construct_list_from_xml(self, self, node)
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
            error("invalid child of a `g`: " .. node.node_name)
         end)
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
                  self.forms.topic  = t
                  self.topic_helper = awpa.topic_helper(t)
                  return t
               end
            end
         end
         local topic = dovah.create_form(form_types.topic, { parent = branch })
         topic.editor_id = editor_id
         topic.text      = "<Results Group>"
         self.forms.topic = topic
         self.topic_helper = awpa.topic_helper(topic)
         return topic
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