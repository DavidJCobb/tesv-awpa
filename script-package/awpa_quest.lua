
do
   local instance_members = {}
   awpa.quest = make_class({
      superclass  = awpa.scope,
      constructor = function(self)
         self.actors = {}
         self.groups = {}
         
         local list = awpa.env.quests
         list[#list + 1] = self
         
         self.form = nil
         self.branches = {
            main   = nil,
            result = nil,
         }
      end,
      instance_members = instance_members,
   })
   do -- member functions
      function instance_members:actor_by_name(name)
         for i = 1, #self.actors do
            local actor = self.actors[i]
            if actor.name == name then
               return actor
            end
         end
      end
   
      function instance_members:from_xml(element)
         awpa.env:set_object_id(self, element.attributes["id"])
      end
      function instance_members:get_or_create_form()
         if self.form then
            return self.form
         end
         local quest = dovah.get_form_by_editor_id(self.id, form_types.quest)
         if quest then
            self.form = quest
            return quest
         end
         quest = dovah.create_form(form_types.quest)
         self.form = quest
         quest.editor_id = self.id
         quest.object_window_category = "Ask Where People Are"
         do
            local alias = quest:create_ref_alias()
            alias.name = "ActorToFind"
         end
         return quest
      end
      
      function instance_members:get_or_create_result_topic()
         local topic = nil
         do
            local topics = self.branches.result:get_all_topics()
            topic = topics[1]
            if not topic then
               topic = dovah.create_form(form_types.topic, { parent = self.branches.result })
            end
            topic.text = "<Results>"
         end
         return topic
      end
      function instance_members:_generate_main_branch()
         local topic = nil
         do
            local topics = self.branches.main:get_all_topics()
            topic = topics[1]
            if not topic then
               topic = dovah.create_form(form_types.topic, { parent = self.branches.main })
            end
            topic.text = "Can you help me find someone?"
         end
         self.branches.main.starting_topic = topic
         
         local result_topic = self:get_or_create_result_topic()
         
         local actor_topics = {}
         do
            local topic = dovah.create_form(form_types.topic, { parent = self.branches.main })
            topic.text = "Actually, never mind."
            actor_topics[#actor_topics + 1] = topic
            
            local shared = awpa.env.built_in_shared_infos["CancelActorSelection"]
            for i = 1, #shared do
               local info = dovah.create_form(form_types.topic_info, { parent = topic })
               info.use_shared_info = shared[i]
            end
         end
         for i = 1, #self.actors do
            local actor = self.actors[i]
            local topic = dovah.create_form(form_types.topic, { parent = self.branches.main })
            topic.text = actor.name
            actor_topics[#actor_topics + 1] = topic
            
            local info = dovah.create_form(form_types.topic_info, { parent = topic })
            info.use_shared_info = awpa.env.built_in_shared_infos["ActorSelected"][0]
            do -- papyrus
               local papyrus = info.papyrus
               do
                  local script = papyrus.scripts:insert("AWPASelectActorScript")
                  local prop   = script.properties:insert("pkActor")
                  prop.value = actor.form
               end
               local frag = papyrus.fragments.on_begin
               frag.script_name   = "AWPASelectActorScript"
               frag.function_name = "SetActor"
               --
               -- TODO: This won't actually work. What we'll need to do is have 
               -- the quest pre-fill with one alias per unique actor in the 
               -- town/city, and then have the script force one of those aliases' 
               -- refs into the "ActorToFind" alias.
               --
            end
            info.link_to:insert(result_topic)
         end
         
         local shared = awpa.env.built_in_shared_infos["BeginActorSelection"]
         for i = 1, #shared do
            local info = dovah.create_form(form_types.topic_info, { parent = topic })
            info.use_shared_info = shared[i]
            for j = 1, #actor_topics do
               info.link_to:insert(actor_topics[j])
            end
         end
      end
      function instance_members:_generate_results()
         local topic = self:get_or_create_result_topic()
         for i = 1, #self.groups do
            local group = self.groups[i]
            group:generate_lines(topic)
         end
         --[[--
            -- TODO: Do this in the XML content instead; easier that way
         --
         -- If there aren't any unconditional lines, then generate fallbacks.
         --
         local needs_fallback = true
         do
            local infos = topic.infos
            if #infos > 0 then
               local last = infos[#infos]
               if #last.conditions == 0 then
                  needs_fallback = false
               end
            end
         end
         if needs_fallback then
            local info_texts = {
               "Hm... Sorry. I don't know where he is.",
               "I'm afraid I haven't seen him around.",
               "No clue, sorry.",
            }
            for i = 1, #info_texts do
               local info = dovah.create_form(form_types.topic_info, { parent = topic })
               local resp = info.responses:insert({
                  text = info_texts[i]
               })
            end
         end
         ]]--
      end
      
      function instance_members:generate_dialogue()
         local quest         = self:get_or_create_form()
         local branch_main   = nil
         local branch_result = nil
         do
            local editor_id_main   = self.id .. "BranchMain"
            local editor_id_result = self.id .. "BranchResult"
            do
               local branches  = quest:get_all_dialogue_branches()
               for i = 1, #branches do
                  local b = branches[i]
                  if b.editor_id == editor_id_main then
                     branch_main = b
                     if branch_result then
                        break
                     end
                  elseif b.editor_id == editor_id_result then
                     branch_result = b
                     if branch_main then
                        break
                     end
                  end
               end
            end
            if not branch_main then
               branch_main = dovah.create_form(form_types.dialogue_branch, { parent = quest })
               branch_main.editor_id = editor_id_main
               branch_main.type      = "top-level"
            end
            if not branch_result then
               branch_result = dovah.create_form(form_types.dialogue_branch, { parent = quest })
               branch_result.editor_id = editor_id_result
               branch_result.type      = "normal"
            end
         end
         self.branches.main   = branch_main
         self.branches.result = branch_result
         self:_generate_main_branch()
         self:_generate_results()
      end
   end
end