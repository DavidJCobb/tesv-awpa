
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
            topic = nil,
         }
      end,
      instance_members = instance_members,
   })
   do -- member functions
      function instance_members:get_or_create_topic()
         if self.forms.topic then
            return self.forms.topic
         end
         local branch    = self.quest_info.branch
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
            if #topics == 1 then
               local t = topics[1]
               if t == branch.starting_topic then -- should always be true
                  --
                  -- If the branch is newly-created, it may have been created with 
                  -- a blank starting topic.
                  --
                  if #t.infos == 0 and t.editor_id == "" and t.text == "" then
                     t.editor_id = editor_id
                     self.forms.topic = t
                     return t
                  end
               end
            end
         end
         local topic = dovah.create_form(form_types.topic, { parent = branch })
         topic.editor_id = editor_id
         self.forms.topic = topic
         branch.starting_topic = topic
         return topic
      end
      
      function instance_members:generate_all_forms()
         local topic <const> = self:get_or_create_topic()
         topic.text     = "Can you help me find someone?"
         topic.priority = 0 -- place at bottom
         
         --
         -- Handle begin-asking-to actor redirects.
         --
         local infos_to_keep_at_the_top = {} -- set, i.e. s[info] = true
         if awpa.env.generate_flat_results then
            local throwaway <const> = awpa.topic_helper(topic)
            local context   <const> = awpa.group_generation_context(throwaway)
            for i = 1, #self.quest_info.actors do
               local actor_info = self.quest_info.actors[i]
               local list       = actor_info.redirects.begin_asking_to
               for j = 1, #list do
                  list[j]:generate_content(context)
               end
               context.conditions = {}
               context.speaker    = nil
            end
            for i = 1, #throwaway.infos.desired_order do
               local info = throwaway.infos.desired_order[i]
               infos_to_keep_at_the_top[info] = true
            end
         else -- if not flat results
            for i = 1, #self.quest_info.actors do
               local actor_info = self.quest_info.actors[i]
               local list       = actor_info.redirects.begin_asking_to
               for i = 1, #list do
                  local redirect = list[i]
                  redirect:get_or_create_topic()
                  redirect:get_or_create_link(topic)
                  redirect:generate_content()
                  --
                  local form = redirect.forms.inbound_link
                  if not form then
                     error("actor redirect wasn't generated")
                  end
                  infos_to_keep_at_the_top[form] = true
               end
            end
         end
         
         -- cache to skip redundant lookups:
         local actor_selection_topics <const> = self.quest_info.selection_topic_list.topics
         
         local infos_to_keep_at_the_bottom = {}
         awpa.env:replace_topic_infos_with_builtin_shared_infos(
            topic,
            "BeginActorSelection",
            {
               process_shared = function(info)
                  infos_to_keep_at_the_bottom[info] = true
                  
                  utils.replace_condition_list(info, {})
                  
                  -- Link these responses to the actor-selection topics.
                  utils.replace_info_link_to_list(info, actor_selection_topics)
               end,
               process_unused = function(info)
                  if infos_to_keep_at_the_top[info] then
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
                     if not infos_to_keep_at_the_bottom[info] then
                        dst[j] = info
                        j = j + 1
                     end
                  end
                  for i = 1, #list do
                     local info = list[i]
                     if infos_to_keep_at_the_bottom[info] then
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
      end
   end
end