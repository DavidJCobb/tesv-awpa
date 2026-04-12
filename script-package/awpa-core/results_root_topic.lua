
if not awpa then
   error("incorrect file order")
end

--[[--

   This class manages the root topic for AWPA results: after the player 
   selects an actor to ask about, they are routed to this topic.
   
   This topic should contain the following infos:
   
    - Invisible infos linking to actors' begin-responding overrides.
    
    - Invisible infos linking to the topics generated for top-level line 
      groups.
      
    - Visible infos representing lines not in a top-level line group.
   
--]]--
do
   local instance_members = {}
   awpa.results_root_topic = make_class({
      constructor = function(self, quest_info)
         self.quest_info = quest_info
         self.children = {} -- vector<variant<awpa.top_level_group, awpa.group, awpa.line, awpa.shared_info_reference>>
         self.forms = {
            topic = nil,
         }
         self.topic_helper = nil
      end,
      instance_members = instance_members,
   })
   do -- member functions
      function instance_members:amend_xml_clone(nodemap)
         for i = 1, #self.children do
            self.children[i]:amend_xml_clone(nodemap)
         end
      end
      function instance_members:visit_topic_helpers(visitor)
         if self.topic_helper then
            visitor(self.topic_helper)
         end
         if not awpa.env.generate_flat_results then
            for i = 1, #self.children do
               local item = self.children[i]
               if awpa.top_level_group.is(item) then
                  if item.topic_helper then
                     visitor(item.topic_helper)
                  end
               end
            end
         end
      end
   
      function instance_members:get_or_create_topic()
         if self.forms.topic then
            if not self.topic_helper then
               self.topic_helper = awpa.topic_helper(self.forms.topic)
            end
            return self.forms.topic
         end
         local branch    = self.quest_info.branch
         local editor_id = string.format("%sResultsRootTopic", self.quest_info.form.editor_id)
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
         topic.text      = "<Results>"
         self.forms.topic = topic
         self.topic_helper = awpa.topic_helper(topic)
         return topic
      end
      
      function instance_members:generate_all_forms()
         local topic = self:get_or_create_topic()
         local pre_existing_infos = topic.infos
         
         local context = awpa.group_generation_context(self.topic_helper)
         if awpa.env.generate_flat_results then
            -- Handle begin-responding overrides.
            for i = 1, #self.quest_info.actors do
               local actor_info = self.quest_info.actors[i]
               for _, redirect in ipairs(actor_info.redirects.begin_responding) do
                  redirect:generate_content(context)
               end
               context.conditions = {}
               context.speaker    = nil
            end
            
            -- Handle child content.
            for i = 1, #self.children do
               context:generate_child(self.children[i])
            end
            return
         end
         
         -- Invisible-infos for linking to begin-responding overrides.
         for i = 1, #self.quest_info.actors do
            local actor_info = self.quest_info.actors[i]
            for _, redirect in ipairs(actor_info.redirects.begin_responding) do
               redirect:get_or_create_topic()
               redirect:get_or_create_link(topic)
               redirect:generate_content()
               --
               local form = redirect.forms.inbound_link
               if not form then
                  error("actor redirect wasn't generated")
               end
               self.topic_helper:append_desired_info(form)
            end
         end
         
         -- Bare children.
         for i = 1, #self.children do
            local item = self.children[i]
            if awpa.top_level_group.is(item) then
               item:create_link_info(self.topic_helper, pre_existing_infos) -- Create topic and link
               local nest_context = awpa.group_generation_context(item.topic_helper)
               for i = j, #item.children do
                  nest_context:generate_child(item.chilren[j])
               end
            else
               context:generate_child(item)
            end
         end
      end
   end
end