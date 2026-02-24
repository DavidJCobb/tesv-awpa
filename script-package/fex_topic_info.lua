
if (not fex) or (not fex.form) then
   error("files loaded in wrong order")
end

do
   local instance_members = {}
   local instance_getters = {}
   local instance_setters = {}
   local static_members   = {}
   
   local forms_to_instances = {}
   
   fex.topic_info = make_class({
      superclass  = fex.form,
      constructor = function(self, form)
         if form.form_type ~= form_types.topic_info then
            error("fex.topic_info cannot wrap a non-topic_info")
         end
         forms_to_instances[form] = self
         self._link_to = nil
      end,
      static_members   = static_members,
      instance_members = instance_members,
      getters          = instance_getters,
      setters          = instance_setters,
   })
   
   function static_members.wrap(form)
      local inst = forms_to_instances[form]
      if inst then
         return inst
      end
      return fex.topic_info(form)
   end
   
   do -- [gs]etters
      function instance_getters:infos(self)
         if self._infos then
            return self._infos
         end
         local list = self._form.infos
         -- TODO: wrap infos
         self._infos = list
      end
   
      local props = {
         "can_move_while_greeting",
         "enable_audio_output_override",
         "enable_walk_away_topic",
         "force_subtitle",
         "hide_walk_away_topic",
         "invisible_continue",
         "is_goodbye",
         "is_random",
         "is_random_end",
         "requires_post_processing",
         "say_once",
         "spends_favor_points",
         --
         "favor_level",
         "has_lip_file",
         "hours_until_reset",
         "override_topic_text",
         "speaker",
         "use_shared_info",
         "walk_away_topic",
      }
      local read_only_props = {
         "conditions",
         "parent",
         "parent_quest",
         "parent_topic",
         "responses",
      }
      for _, v in ipairs(props) do
         instance_getters[v] = function(self, key)
            return self._form[key]
         end
         instance_setters[v] = function(self, key, value)
            self._form[key] = value
         end
      end
      for _, v in ipairs(read_only_props) do
         instance_getters[v] = function(self, key)
            return self._form[key]
         end
      end
      
      function instance_getters:link_to(self)
         return self._form.link_to
      end
      function instance_setters:link_to(self, list)
         local dst = self._form.link_to
         for i = #dst, 1 do
            dst:remove(i)
         end
         if list then
            for i = 1, #list do
               local item = list[i]
               if fex.topic.is(item) then
                  item = item._form
               end
               dst:insert(item)
            end
         end
      end
      
      function instance_getters:parent(self)
         return fex.topic.wrap(self._form.parent_topic)
      end
      function instance_getters:parent_quest(self)
         return fex.quest.wrap(self._form.parent_quest)
      end
      function instance_getters:parent_topic(self)
         return fex.topic.wrap(self._form.parent_topic)
      end
      
      function instance_getters:use_shared_info(self)
         return fex.topic_info.wrap(self._form.use_shared_info)
      end
      function instance_setters:use_shared_info(self, f)
         if fex.topic_info.is(f) then
            f = f._form
         end
         self._form.use_shared_info = f
      end
   end
   do -- member functions
      function instance_members:append_condition(src)
         if awpa.condition.is(src) then
            src:apply_to_info(self._form)
            return
         end
         local cnd = self._form.conditions:insert()
         if src then
            cnd.run_on        = src.run_on
            cnd.function_name = src.function_name
            if src.parameters then
               for j = 1, 2 do
                  cnd.parameters[j] = src.parameters[j]
               end
            end
            cnd.comparison.operator = src.comparison.operator
            cnd.comparison.operand  = src.comparison.operand
         end
         return cnd
      end
      function instance_members:append_conditions(src)
         for i = 1, #src do
            if awpa.condition.is(src) then
               src:apply_to_info(self._form)
            else
               self:append_condition(src)
            end
         end
      end
      function instance_members:assign(src)
         for k, v in pairs(src) do
            ::continue::
            if k == "conditions"
            or k == "responses"
            then
               goto continue
            end
            self._form[k] = v
         end
         if src.conditions then
            self:clear_conditions()
            for i = 1, #src.conditions do
               self:append_condition(src.conditions[i]
            end
         end
         if src.responses then
            local list = self._form.responses
            for i = #list, 1 do
               list:remove(i)
            end
            for i = 1, #src.responses do
               list:insert(src.responses[i])
            end
         end
      end
      function instance_members:clear_conditions()
         local list = self._form.conditions
         for i = #list, 1 do
            list:remove(i)
         end
      end
      function instance_members:replace_conditions(src)
         self:clear_conditions()
         if src then
            if src.function_name then
               self:append_condition(src)
               return
            end
            self:append_conditions(src)
         end
      end
   end
end
