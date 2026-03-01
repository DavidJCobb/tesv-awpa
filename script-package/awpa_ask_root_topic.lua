
if not awpa then
   error("incorrect file order")
end

--[[--

   This class manages the root topic for an AWPA interaction: the "Can 
   you help me find someone?" topic.
   
   This topic should contain the following infos:
   
    - Invisible infos linking to actors' begin-asking-to overrides.
    
    - Visible infos i.e. "Sure. Who are you looking for?" linking to 
      all actor-selection topics.
   
--]]--
do
   local instance_members = {}
   awpa.ask_root_topic = make_class({
      constructor = function(self, quest_info)
         self.quest_info = quest_info
         self.forms = {
            topic           = nil,
            override_links  = {}, -- topic-infos linking to overrides
            selection_links = {}, -- topic-infos linking to actor-selection topics
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
         local editor_id = string.format("%sBeginTopic", self.quest_info.form.editor_id)
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
         self.forms.topic = topic
         return topic
      end
      
      function instance_members:generate_all_forms()
         local topic <const> = self:get_or_create_topic()
         topic.text = "Can you help me find someone?"
         
         --
         -- Process begin-asking-to actor overrides; get-or-create their link infos.
         -- Store all such link infos in `self.forms.override_links`.
         --
         local links_to_actor_overrides = {} -- set, i.e. s[info] = true
         for i = 1, #self.quest_info.actors do
            local actor_info = self.quest_info.actors[i]
            do
               local over = self.actors[i].overrides.begin_asking_to.bribe
               if over then
                  local form = over.forms.link_to_branch
                  if not form then
                     error("bribe override wasn't generated")
                  end
                  self.forms.override_links[#self.forms.override_links + 1] = form
                  links_to_actor_overrides[form] = true
               end
            end
            --
            -- TODO: begin-asking-to non-bribe overrides
            --
         end
         
         -- cache to skip redundant lookups:
         local actor_selection_topics <const> = self.quest_info.selection_topic_list.topics
         
         local links_to_actor_selection = {}
         awpa.env:replace_topic_infos_with_builtin_shared_infos(
            topic,
            "BeginActorSelection",
            {
               process_shared = function(info)
                  links_to_actor_selection[info] = true
                  
                  utils.replace_condition_list(info, {})
                  -- TODO: conditions for whether you're allowed to ask the current 
                  -- speaker at all; for example, you should not even see the "Can 
                  -- you help me find someone?" topic when speaking to Maven if you 
                  -- are in the Thieves Guild (i.e. you should not have the option 
                  -- to annoy her)
                  
                  -- Link these responses to the actor-selection topics.
                  utils.replace_info_link_to_list(info, actor_selection_topics)
               end,
               process_unused = function(info)
                  if links_to_actor_overrides[info] then
                     return true -- this is an actor override link; retain it
                  end
                  return false -- this is an unrecognized info (deleted from XML?); discard
               end,
               reorder = function(list)
                  --
                  -- Move the "BeginActorSelection" infos to the end.
                  --
                  local dst = {}
                  local j   = 1
                  for i = 1, #list do
                     local info = list[i]
                     if not links_to_actor_selection[info] then
                        dst[j] = info
                        j = j + 1
                     end
                  end
                  for i = 1, #list do
                     local info = list[i]
                     if links_to_actor_selection[info] then
                        dst[j] = info
                        j = j + 1
                     end
                  end
                  --
                  -- Modify `list` itself.
                  --
                  for i = 1, #dst do
                     list[i] = dst[i]
                  end
               end,
               process_all_retained = function(info)
                  --
                  -- TODO: Consider attaching a Papyrus fragment to all possible 
                  --       infos under "Can you help me find someone?" which would 
                  --       clear the ActorToFind alias (and any similar "state" 
                  --       aliases we add in the future). This would help prevent 
                  --       state for a player's previous query from "bleeding 
                  --       through" if the player asks while script lag is happening.
                  --
               end,
            }
         )
         self.forms.selection_links = links_to_actor_selection
      end
   end
end