
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
            topic            = nil,
            override_links   = {}, -- topic-infos linking to overrides
            top_level_links  = {}, -- topic-infos linking to top-level groups
            bare_infos       = {}, -- vector<topic_info>
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
         for i = 1, #self.children do
            local item = self.children[i]
            if awpa.top_level_group.is(item) then
               if item.topic_helper then
                  visitor(item.topic_helper)
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
         
         -- Invisible-infos for linking to begin-responding overrides.
         for i = 1, #self.quest_info.actors do
            local actor_info = self.quest_info.actors[i]
            for _, redirect in ipairs(actor_info.redirects.begin_responding) do
               local form = redirect.forms.inbound_link
               if not form then
                  error("actor redirect wasn't generated")
               end
               self.forms.override_links[#self.forms.override_links + 1] = form
               self.topic_helper:append_desired_info(form)
            end
         end
         
         -- Bare children.
         for i = 1, #self.children do
            local item = self.children[i]
            if awpa.top_level_group.is(item) then
               do -- Create topic and link
                  local dst_topic = item:get_or_create_topic()
                  
                  local link
                  for i = 1, #pre_existing_infos do
                     local pei = pre_existing_infos[i]
                     if pei.link_to[1] == dst_topic then
                        link = pei
                        break
                     end
                  end
                  if not link then
                     link = dovah.create_form(form_types.topic_info, { parent = topic })
                     link.use_shared_info = awpa.env.built_in_shared_infos["InvisibleInfo"][1]
                     link.link_to:insert(dst_topic)
                     link.invisible_continue = true
                  end
                  self.forms.top_level_links[i] = link
                  self.topic_helper:append_desired_info(link)
                  utils.replace_condition_list(link, {})
                  for i = 1, #item.conditions do
                     item.conditions[i]:apply_to_info(link)
                  end
               end
               
               item:generate_children()
            elseif awpa.line.is(item) then
               local a, b = item:generate_infos(topic)
               self.topic_helper:append_desired_info(a)
               if b then
                  self.topic_helper:append_desired_info(b)
               end
            elseif awpa.group.is(item) then
               item:generate_infos(topic, self.topic_helper)
            elseif awpa.shared_info_reference.is(item) then
               item:generate_infos(topic)
               for i = 1, #item.forms do
                  self.topic_helper:append_desired_info(item.forms[i])
               end
            end
         end
      end
   end
end