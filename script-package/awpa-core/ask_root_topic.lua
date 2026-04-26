
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
         self.topic_helper = nil
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
         
         local prior_infos <const> = topic.infos
         
         --
         -- Handle begin-asking-to actor redirects.
         --
         local infos_to_keep_at_the_top = {} -- set, i.e. s[info] = true
         local infos_at_top_order       = {}
         do
            local throwaway <const> = awpa.topic_helper(topic)
            for i = 1, #self.quest_info.actors do
               local actor_info = self.quest_info.actors[i]
               local list       = actor_info.redirects.begin_asking_to
               for j = 1, #list do
                  local redirect = list[j]
local bench_a = benchmark.new()
                  local rlg_list = redirect:fold()
awpa.perflog:log(bench_a, "Time taken to RLG-fold `begin-asking-to` redirect for actor %s", actor_info.name)
                  for k = 1, #rlg_list do
                     rlg_list[k]:generate(throwaway)
                  end
               end
            end
            infos_at_top_order = throwaway.infos.desired_order
            for i = 1, #infos_at_top_order do
               local info = infos_at_top_order[i]
               infos_to_keep_at_the_top[info] = true
            end
         end
         
         -- cache to skip redundant lookups:
         local actor_selection_topics <const> = self.quest_info.selection_topic_list.topics
         
         local infos_to_keep_at_the_bottom = {}
         awpa.env:replace_topic_infos_with_builtin_shared_infos(
            topic,
            "BeginActorSelection",
            {
               prior_infos = prior_infos,
               
               process_shared = function(info)
                  infos_to_keep_at_the_bottom[info] = true
                  
                  utils.clear_condition_list(info)
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
                  local top = infos_at_top_order
                  local bot = {}
                  do
                     local k = 1
                     for i = 1, #list do
                        local info = list[i]
                        if infos_to_keep_at_the_top[info] then
                        elseif infos_to_keep_at_the_bottom[info] then
                           bot[k] = info
                           k = k + 1
                        end
                     end
                  end
                  local top_count = #top
                  local bot_count = #bot
                  for i = 1, top_count do
                     list[i] = top[i]
                  end
                  for i = 1, bot_count do
                     list[i + top_count] = bot[i]
                  end
                  for i = #list, top_count + bot_count + 1, -1 do
                     list[i] = nil
                  end
               end,
               --[[--
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
               --]]--
            }
         )
      end
   end
end