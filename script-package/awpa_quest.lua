
if (not awpa) or (not awpa.scope) then
   error("incorrect file order")
end

do
   local instance_members = {}
   awpa.quest = make_class({
      superclass  = awpa.scope,
      constructor = function(self)
         self.source_xml_node = nil
         
         self.actors = {}
         
         local list = awpa.env.quests
         list[#list + 1] = self
         
         self.recycled = false
         self.form     = nil -- quest
         self.branch   = nil -- dialogue_branch
         self.ask_root_topic       = awpa.ask_root_topic(self)
         self.selection_topic_list = awpa.actor_selection_topic_list(self)
         self.results_root_topic   = awpa.results_root_topic(self)
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
      function instance_members:visit_topic_helpers(visitor)
         for i = 1, #self.actors do
            self.actors[i]:visit_topic_helpers(visitor)
         end
         self.results_root_topic:visit_topic_helpers(visitor)
      end
   
      function instance_members:from_xml(element)
         self.source_xml_node = element
         awpa.env:set_object_id(self, element.attributes["id"])
      end
      function instance_members:to_xml(element)
         element.attributes["id"] = self.id
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
         return self.results_root_topic:get_or_create_topic()
      end
      function instance_members:generate_dialogue()
         local quest = self:get_or_create_form()
         
         self:ensure_actor_selection_aliases()
         
         local branch_main = nil
         do
            local editor_id_main = self.id .. "BranchMain"
            
            local branches = quest:get_all_dialogue_branches()
            branch_main = utils.get_or_create_branch(quest, editor_id_main)
            branch_main.type = "top-level"
         end
         self.branch = branch_main
         
         local result_topic = self:get_or_create_result_topic()
         
         local desired_infos = {}
         for i = 1, #self.actors do
            local over = self.actors[i].overrides.begin_asking_to.bribe
            if over then
               over:generate_content(self, self.actors[i], self.ask_root_topic:get_or_create_topic(), result_topic)
               desired_infos[#desired_infos + 1] = over.forms.link_to_branch
            end
            -- TODO: other begin-asking-to override content (i.e. groups and lines)
         end
         
         self.selection_topic_list:generate_all_forms()
         self.ask_root_topic:generate_all_forms()
         self.results_root_topic:generate_all_forms()
      end
   end
end