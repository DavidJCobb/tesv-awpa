
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
         local branch = self.quest_info.branch
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
         local branch = self.quest_info.branch
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
         local actor_alias <const> = self.quest_info.form.aliases[actor_info.form.editor_id]
         if not actor_alias then
            error("Missing alias: " .. actor_info.form.editor_id)
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
         info.use_shared_info = awpa.env.built_in_shared_infos["ActorSelected"][1]
         utils.set_papyrus_script_data(
            info,
            {
               ["AskWherePeopleAreFRAGMENTSelectActor"] = {
                  ["pkSrcAlias"] = actor_alias,
                  ["pkDstAlias"] = self.quest_info.alias_for_actor_to_find,
               }
            },
            {
               script_name = "AskWherePeopleAreFRAGMENTSelectActor",
               on_begin    = {
                  script_name   = "AskWherePeopleAreFRAGMENTSelectActor"
                  function_name = "Exec"
               }
            }
         )
         utils.replace_condition_list(info, {
            {  -- Cannot ask about dead actors.
               run_on        = actor_alias,
               function_name = "GetDead",
               comparison    = { operator = "==", operand = 0 }
            },
            {  -- Cannot ask an actor about themselves.
               run_on        = "subject",
               function_name = "GetIsID",
               parameters    = { actor_info.form },
               comparison    = { operator = "==", operand = 0 }
            }
         })
         do
            local list = actor_info.overrides.begin_asking_about.conditions
            for i = 1, #list do
               list[i]:apply_to_info(info)
            end
         end
         utils.replace_info_link_to_list(info, {
            self.quest_info:get_or_create_result_topic()
         })
         info.invisible_continue = true
      end
      
      function instance_members:generate_all_forms()
         do
            local topic = self:get_cancel_topic()
            awpa.env:replace_topic_infos_with_builtin_shared_infos(topic, "CancelActorSelection")
         end
         for i = 1, #self.quest_info.actors do
            local actor_info = self.quest_info.actors[i]
            self:setup_actor_selection_topic(actor_info)
         end
      end
   end
end