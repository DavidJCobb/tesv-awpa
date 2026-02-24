
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
         self.form     = nil -- fex.quest
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
            self.form     = fex.quest.wrap(quest)
            self.recycled = true
            return quest
         end
         quest = fex.quest.wrap(dovah.create_form(form_types.quest))
         self.form = quest
         quest.editor_id = self.id
         quest.object_window_category = "Ask Where People Are"
         do
            local alias = quest:create_ref_alias()
            alias.name            = "ActorToFind"
            alias.allow_dead      = true
            alias.allow_destroyed = true
            alias.allow_disabled  = true
            alias.allow_reserved  = true
            alias.allow_reuse     = true
            alias.optional        = true
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
               alias.optional        = true
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
            topic = self.branches.result.starting_topic
            if not topic then
               topic = self.branches.result:append_topic()
               self.branches.result.starting_topic = topic
            end
            topic.text = "<Results>"
         end
         return topic
      end
      function instance_members:_generate_main_branch()
         local main_branch_topics = self.branches.main:get_all_topics()
         
         local begin_topic = self.branches.main.starting_topic
         if not begin_topic then
            begin_topic = self.branches.main:append_topic()
            self.branches.main.starting_topic = begin_topic
         end
         begin_topic.text = "Can you help me find someone?"
         
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
            local topic = self.branches.main:get_or_create_topic(
               self.form.editor_id .. "TopicCancelActorSelection",
               {
                  text = "Actually, never mind."
               }
            )
            replace_infos_with_builtin_shared(topic, "CancelActorSelection")
            return topic
         end
         local function get_or_create_actor_topic(actor_info)
            local topic = self.branches.main:get_or_create_topic(
               string.format("%sTopicSelectActor%s", self.form.editor_id, actor_info.form.editor_id)
            )
            topic.text = actor_info.name
            
            local info = topic:append_info()
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
            info.link_to:insert(result_topic._form)
            info:replace_conditions({
               run_on        = self.form.aliases[actor_info.form.editor_id],
               function_name = "GetDead",
               comparison    = { operator = "==", operand = 0 }
            })
            info:append_conditions(actor_info.overrides.begin_asking_about.conditions)
            
            return topic
         end
         
         local actor_topics = {}
         actor_topics[#actor_topics + 1] = get_or_create_cancel_topic()
         for i = 1, #self.actors do
            actor_topics[#actor_topics + 1] = get_or_create_actor_topic(self.actors[i])
         end
         
         for i = 1, #self.actors do
            local over = self.actors[i].overrides.begin_asking_to.bribe
            if over then
               over:generate_content(self, self.actors[i], begin_topic, result_topic)
            end
            -- TODO: other begin-asking-to override content (i.e. groups and lines)
         end
         do
            local shared = awpa.env.built_in_shared_infos["BeginActorSelection"]
            for i = 1, #shared do
               local info = begin_topic:append_info()
               utils.clear_info_responses(info)
               info.use_shared_info = shared[i]
               utils.replace_info_link_to_list(info, actor_topics)
            end
         end
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
         
         do
            local editor_id_main   = self.id .. "BranchMain"
            local editor_id_result = self.id .. "BranchResult"
            self.branches.main   = quest:get_or_create_branch(editor_id_main,   "top-level")
            self.branches.result = quest:get_or_create_branch(editor_id_result, "normal")
         end
         self:_generate_main_branch()
         self:_generate_results()
      end
   end
end