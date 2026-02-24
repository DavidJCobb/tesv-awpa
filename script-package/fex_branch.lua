
if (not fex) or (not fex.form) then
   error("files loaded in wrong order")
end

do
   local instance_members = {}
   local instance_getters = {}
   local instance_setters = {}
   local static_members   = {}
   
   local forms_to_instances = {}
   
   fex.branch = make_class({
      superclass  = fex.form,
      constructor = function(self, form)
         if form.form_type ~= form_types.dialogue_branch then
            error("fex.branch cannot wrap a non-branch")
         end
         forms_to_instances[form] = self
         self._topics = nil
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
      return fex.branch(form)
   end
   
   do -- [gs]etters
      local props = {
         "exclusive",
         "starting_topic",
         "type",
      }
      local read_only_props = {
         "get_all_topics",
         --
         "parent_quest",
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
      
      function instance_getters:starting_topic(self)
         return fex.topic.wrap(self._form.starting_topic)
      end
      function instance_setters:starting_topic(self, f)
         if fex.topic.is(f) then
            f = f._form
         end
         self._form.starting_topic = f
      end
   end
   do -- member functions
      function instance_members:append_topic(src)
         local topic = dovah.create_form(form_types.topic, { parent = self._form })
         if src then
            for k, v in pairs(src) do
               ::continue::
               if k == "infos" then
                  error("cannot pre-specify infos (yet?)")
               end
               topic[k] = v
            end
         end
         topic = fex.topic(topic)
         if self._topics then
            self._topics[#self._topics + 1] = topic
         end
         return topic
      end
      function instance_members:get_all_topics()
         if self._topics then
            return self._topics
         end
         local list = self._form:get_all_topics()
         for i = 1, #list do
            list[i] = fex.topic(list[i])
         end
         self._topics = list
         return list
      end
      function instance_members:get_or_create_topic(editor_id, src)
         local list = self:get_all_topics()
         local size = #list
         for i = 1, size do
            local topic = list[i]
            if topic.editor_id == editor_id then
               if src then
                  topic:assign(src)
               end
               return topic
            end
         end
         local topic = dovah.create_form(form_types.topic, { parent = self._form })
         topic.editor_id = editor_id
         topic = fex.topic(topic)
         list[size + 1] = topic
         if src then
            topic:assign(src)
         end
         return topic
      end
   end
end
