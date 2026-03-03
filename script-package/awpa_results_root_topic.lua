
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
         self.quest_info       = quest_info
         self.top_level_groups = {} -- vector<awpa.top_level_group>
         self.children = {} -- vector<variant<awpa.group, awpa.line, awpa.shared_info_reference>>
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
         for i = 1, #self.top_level_groups do
            local tlg = self.top_level_groups[i]
            if tlg.topic_helper then
               visitor(tlg.topic_helper)
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
            --
            -- TODO
            --
         end
         
         -- Top-level groups.
         for i = 1, #self.top_level_groups do
            local tlg       = self.top_level_groups[i]
            local dst_topic = tlg:get_or_create_topic()
            
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
            end
            self.forms.top_level_links[i] = link
            utils.replace_condition_list(link, {})
            for i = 1, #tlg.conditions do
               tlg.conditions[i]:apply_to_info(link, tlg)
            end
            
            tlg:generate_children()
         end
         
         -- Bare children.
         for i = 1, #self.children do
            local item = self.children[i]
            if awpa.line.is(item) then
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