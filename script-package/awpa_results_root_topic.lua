
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
         self.forms = {
            topic            = nil,
            override_links   = {}, -- topic-infos linking to overrides
            top_level_groups = {}, -- vector<pair<topic, topic_info>>
            bare_infos       = {}, -- vector<topic_info>
         }
      end,
      instance_members = instance_members,
   })
   do -- member functions
      function instance_members:get_or_create_topic()
         if self.forms.topic then
            return self.forms.topic
         end
         local branch    = self.quest_info.branches.main
         local editor_id = string.format("%sResultsRootTopic", self.quest_info.form.editor_id)
         do
            local topics = branch:get_all_topics()
            for i = 1, #topics do
               local t = topics[i]
               if t.editor_id == editor_id then
                  self.forms.topic = t
                  return t
               end
            end
         end
         local topic = dovah.create_form(form_types.topic, { parent = branch })
         topic.editor_id = editor_id
         topic.text      = "<Results>"
         self.forms.topic = topic
         return topic
      end
   end
end