
if not awpa then
   error("incorrect file order")
end

--[[--

   This class manages the list of actor-selection topics available in an AWPA 
   quest, including the "cancel" topic. So for example, the instance of this 
   class belonging to the AWPA Riften quest would have a cancel topic, and a 
   topic for every actor in Riften that the player can conceivably inquire 
   about.
   
   The topic list is kept sorted. When you want any given info to link to the 
   selection topics, you can simply overwrite the info's link-to topics with 
   the topic list here (using the appropriate `utils` function).
   
--]]--
do
   local instance_members = {}
   awpa.actor_selection_topic_list = make_class({
      constructor = function(self, quest_info)
         self.quest_info = quest_info
         self.topics     = {} -- includes "cancel" topic
      end,
      instance_members = instance_members,
   })
   do -- member functions
      function instance_members:get_cancel_topic()
         local editor_id = self:get_cancel_topic_editor_id()
         local t         = self.topics[1]
         if t and t.editor_id == editor_id then
            return t
         end
         local branch = self.quest_info.branches.main
         do
            local topics = branch:get_all_topics()
            for i = 1, #topics do
               local t = topics[i]
               if t.editor_id == editor_id then
                  table.insert(self.topics, 1, t)
                  return t
               end
            end
         end
         local topic = dovah.create_form(form_types.topic, { parent = branch })
         topic.editor_id = editor_id
         topic.text      = "Actually, never mind."
         table.insert(self.topics, 1, topic)
         return topic
      end
      function instance_members:get_cancel_topic_editor_id()
         return string.format("%sTopicCancelActorSelection", self.quest_info.form.editor_id)
      end
      function instance_members:get_selection_topic_editor_id_for(actor_info)
         return string.format(
            "%sTopicSelectActor%s",
            self.quest_info.form.editor_id,
            actor_info.form.editor_id
         )
      end
      function instance_members:get_selection_topic_for(actor_info)
         local editor_id = self:get_selection_topic_editor_id_for(actor_info)
         for i = 1, #self.topics do
            local t = self.topics[i]
            if t.editor_id == editor_id then
               return t
            end
         end
         local branch = self.quest_info.branches.main
         do
            local topics = branch:get_all_topics()
            for i = 1, #topics do
               local t = topics[i]
               if t.editor_id == editor_id then
                  self:_insert_sorted_selection_topic(t)
                  return t
               end
            end
         end
         local topic = dovah.create_form(form_types.topic, { parent = branch })
         topic.editor_id = editor_id
         topic.text      = actor_info.name
         self:_insert_sorted_selection_topic(topic)
         return topic
      end

      function instance_members:_insert_sorted_selection_topic(topic)
         self.topics[#self.topics + 1] = topic
         
         local cancel_id = self:get_cancel_topic_editor_id()
         table.sort(self.topics, function(a, b)
            if a.editor_id == cancel_id then
               return true
            end
            if b.editor_id == cancel_id then
               return false
            end
            return a.text < b.text
         end)
      end
      
      function instance_members:setup_actor_selection_topic(actor_info, topic)
         if not topic then
            topic = self:get_selection_topic_for(actor_info)
         end
         
         local info
         do
            local infos = topic.infos
            local count = #infos
            if count > 1 then
               error("An actor-selection topic has multiple infos. How did this happen?")
            end
            if count == 1 then
               info = infos[1]
            end
         end
         if not info then
            info = dovah.create_form(form_types.topic_info, { parent = topic })
         end
         info.use_shared_info = awpa.env.built_in_shared_infos["ActorSelected"][0]
         do -- papyrus
            local papyrus = info.papyrus
            do
               local script = papyrus.scripts["AWPASelectActorScript"]
               if not script then
                  script = papyrus.scripts:insert("AWPASelectActorScript")
               end
               do
                  local prop = script.properties["pkSrcAlias"]
                  if not prop then
                     prop = script.properties:insert("pkSrcAlias")
                  end
                  prop.value = self.form.aliases[actor_info.form.editor_id]
               end
               do
                  local prop = script.properties["pkDstAlias"]
                  if not prop then
                     prop = script.properties:insert("pkDstAlias")
                  end
                  prop.value = self.form.aliases["ActorToFind"]
               end
            end
            local frag = papyrus.fragments.on_begin
            frag.script_name   = "AWPASelectActorScript"
            frag.function_name = "SetActor"
         end
         utils.replace_condition_list(info, {
            {
               run_on        = self.quest_info.form.aliases[actor_info.form.editor_id],
               function_name = "GetDead",
               comparison    = { operator = "==", operand = 0 }
            }
         })
         utils.replace_info_link_to_list(info, {
            self.quest_info:get_or_create_result_topic()
         })
      end
      
      function instance_members:generate_all_forms()
         do
            local topic = self:get_cancel_topic()
            local infos = topic.infos
            
            --
            -- TODO: Make the below a generic/global/awpa.env-scoped algorithm for:
            --
            --  - Replacing/recycling infos within a topic, to use a pool of 
            --    SharedInfos
            --
            --  - Configuring to-be-retained infos via a functor
            --
            --  - Globally tracking all recycled or generated infos, versus all 
            --    non-recycled infos
            --
            --  - Globally deleting non-recycled infos after all topics are 
            --    processed
            --
            
            --
            -- TODO: Handle the case of a SharedInfo having its pronouns changed 
            --       (i.e. a previously gendered info ceasing to be gendered, or 
            --       a previously non-gendered info becoming gendered).
            --
            
            local unused   = {}
            local recycled = {}
            local src      = awpa.env.built_in_shared_infos["CancelActorSelection"]
            do
               for i = 1, #infos do
                  local info = infos[i]
                  local si   = info.use_shared_info
                  for j = 1, #src do
                     if si == src[j] then
                        recycled[j] = info
                        goto found
                     end
                  end
                  ::not_found::
                  unused[#unused + 1] = info
                  ::found::
               end
            end
            local desired_order = {}
            do
               local consumed = {}
               for i = 1, #src do
                  local info = recycled[i]
                  if info then
                     --
                     -- TODO: Update GetIsSex conditions.
                     --
                     desired_order[i] = info
                     goto generate_next_shared_info
                  end
                  for j = 1, #unused do
                     if not consumed[j] then
                        info = unused[j]
                        
                        --
                        -- TODO: Update GetIsSex conditions.
                        --
                        info.use_shared_info = src[i]
                        utils.clear_info_responses(info)
                        utils.replace_condition_list(info, {})
                        utils.replace_info_link_to_list(info, {})
                        
                        consumed[j] = true
                        desired_order[i] = info
                        goto generate_next_shared_info
                     end
                  end
                  info = dovah.create_form(form_types.topic_info, { parent = topic })
                  info.use_shared_info = src[i]
                  desired_order[i] = info
                  ::generate_next_shared_info::
               end
            end
            for i = 1, #unused do
               if not consumed[i] then
                  unused[i]:delete()
               end
            end
            for i = 1, #desired_order do
               local prev
               if i > 1 then
                  prev = desired_order[i - 1]
               end
               topic:place_info_after(desired_order[i], prev)
            end
         end
         for i = 1, #self.quest_info.actors do
            local actor_info = self.quest_info.actors[i]
            self:setup_actor_selection_topic(actor_info)
         end
      end
   end
end