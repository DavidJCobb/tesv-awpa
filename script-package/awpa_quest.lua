
if (not awpa) or (not awpa.scope) then
   error("incorrect file order")
end

do
   local instance_members = {}
   awpa.quest = make_class({
      superclass  = awpa.scope,
      constructor = function(self)
         self.actors = {}
         self.groups = {}
         
         local list = awpa.env.quests
         list[#list + 1] = self
         
         self.recycled = false
         self.form     = nil
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
            self.form     = quest
            self.recycled = true
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
      
      function instance_members:ensure_actor_selection_aliases()
         local quest = self:get_or_create_form()
         
         local aliases_by_actor = {}
         local alias_ids_in_use = {}
         local max_alias_id     = 1
      
         local list = quest.aliases
         local size = #list
         for i = 1, size do
            local alias    = list[i]
            local alias_id = alias.id
            
            local keep = false
            local fill = alias.fill
            if fill and fill.form_type == form_types.actor_base then
               for i = 1, #self.actors do
                  if fill == self.actors[i].form then
                     keep = true
                     aliases_by_actor[fill] = alias
                     break
                  end
               end
            end
            alias_ids_in_use[alias_id] = true
            if alias_id > max_alias_id then
               max_alias_id = alias_id
            end
         end
         
         local min_alias_id = 1
         local function _get_next_id()
            for i = min_alias_id, max_alias_id do
               if not alias_ids_in_use[i] then
                  return i
               end
            end
            max_alias_id = max_alias_id + 1
            min_alias_id = max_alias_id
            return max_alias_id
         end
         
         for i = 1, #self.actors do
            local actor_info = self.actors[i]
            local actor_form = actor_info.form
            if not aliases_by_actor[actor_form] then
               local alias_id = _get_next_id()
               local alias    = quest:create_ref_alias()
               alias.id              = alias_id
               alias.name            = actor_form.editor_id
               alias.allow_dead      = true
               alias.allow_destroyed = true
               alias.allow_disabled  = true
               alias.allow_reserved  = true
               alias.allow_reuse     = true
               alias.fill            = actor_form
               
               aliases_by_actor[actor_form] = alias
               alias_ids_in_use[alias_id]   = true
               min_alias_id = alias_id + 1
            end
         end
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
         local main_branch_topics = self.branches.main:get_all_topics()
         local function find_preexisting_topic(editor_id)
            local size = #main_branch_topics
            for i = 1, size do
               local t = main_branch_topics[i]
               if t.editor_id == editor_id then
                  return t
               end
            end
         end
         
         local begin_topic = self.branches.main.starting_topic
         if not begin_topic then
            begin_topic = dovah.create_form(form_types.topic, { parent = self.branches.main })
            begin_topic.text = "Can you help me find someone?"
            self.branches.main.starting_topic = begin_topic
         end
         local result_topic = self:get_or_create_result_topic()
         
         local function replace_infos_with_builtin_shared(topic, key, configure)
            local shared     = awpa.env.built_in_shared_infos[key]
            local prior_list = topic.infos
            local prior_size = #prior_list
            local after_size = #shared
            for i = 1, after_size do
               local info
               if i <= prior_size then
                  info = prior_list[i]
                  utils.clear_info_responses(info)
               else
                  info = dovah.create_form(form_types.topic_info, { parent = topic })
               end
               info.use_shared_info = shared[i]
               if configure then
                  configure(info)
               end
            end
            if prior_size > after_size then
               for i = prior_size + 1, after_size do
                  dovah.delete_form(prior_list[i])
               end
            end
         end
         
         local function get_or_create_cancel_topic()
            local editor_id = self.form.editor_id .. "TopicCancelActorSelection"
            local topic     = find_preexisting_topic(editor_id)
            if topic then
               return topic
            end
            topic = dovah.create_form(form_types.topic, { parent = self.branches.main })
            topic.editor_id = editor_id
            topic.text      = "Actually, never mind."
            replace_infos_with_builtin_shared(topic, "CancelActorSelection")
            return topic
         end
         local function get_or_create_actor_topic(actor_info)
            local editor_id = self.form.editor_id .. "TopicSelectActor" .. actor_info.form.editor_id
            do
               local size = #main_branch_topics
               for i = 1, size do
                  local t = main_branch_topics[i]
                  if t.editor_id == editor_id then
                     return t
                  end
               end
            end
            local topic = dovah.create_form(form_types.topic, { parent = self.branches.main })
            topic.editor_id = editor_id
            topic.text      = actor_info.name
            
            local info = dovah.create_form(form_types.topic_info, { parent = topic })
            info.use_shared_info = awpa.env.built_in_shared_infos["ActorSelected"][0]
            do -- papyrus
               local papyrus = info.papyrus
               do
                  local script = papyrus.scripts:insert("AWPASelectActorScript")
                  do
                     local prop = script.properties:insert("pkSrcAlias")
                     prop.value = self.form.aliases[actor_info.form.editor_id]
                  end
                  do
                     local prop = script.properties:insert("pkDstAlias")
                     prop.value = self.form.aliases["ActorToFind"]
                  end
               end
               local frag = papyrus.fragments.on_begin
               frag.script_name   = "AWPASelectActorScript"
               frag.function_name = "SetActor"
            end
            info.link_to:insert(result_topic)
            
            local cnd_list = actor_info.overrides.begin_asking_about.conditions
            for i = 1, #cnd_list do
               cnd_list[i]:apply_to_info(info)
            end
            
            return topic
         end
         
         local actor_topics = {}
         actor_topics[#actor_topics + 1] = get_or_create_cancel_topic()
         for i = 1, #self.actors do
            actor_topics[#actor_topics + 1] = get_or_create_actor_topic(self.actors[i])
         end
         
         replace_infos_with_builtin_shared(
            begin_topic,
            "BeginActorSelection",
            function(info)
               utils.replace_info_link_to_list(info, actor_topics)
            end
         )
      end
      function instance_members:_generate_results()
         local topic = self:get_or_create_result_topic()
         for i = 1, #self.groups do
            local group = self.groups[i]
            group:generate_lines(topic)
         end
      end
      
      function instance_members:generate_dialogue()
         local quest = self:get_or_create_form()
         
         self:ensure_actor_selection_aliases()
         
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