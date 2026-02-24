
if (not fex) or (not fex.form) then
   error("files loaded in wrong order")
end

do
   local instance_members = {}
   local instance_getters = {}
   local instance_setters = {}
   local static_members   = {}
   
   local forms_to_instances = {}
   
   fex.topic = make_class({
      superclass  = fex.form,
      constructor = function(self, form)
         if form.form_type ~= form_types.topic then
            error("fex.topic cannot wrap a non-topic")
         end
         forms_to_instances[form] = self
         self._infos = nil
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
      return fex.topic(form)
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
         "do_all_before_repeating",
         "priority",
         "subtype",
         "text",
      }
      local read_only_props = {
         --"place_info_before",
         --
         "parent_branch",
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
   end
   do -- member functions
      function instance_members:append_info(src)
         local info = dovah.create_form(form_types.topic_info, { parent = self._form })
         info = fex.topic_info(info)
         if src then
            info:assign(src)
         end
         return info
      end
      function instance_members:assign(src)
         for k, v in pairs(src) do
            if k == "infos" then
               error("cannot pre-specify infos (yet?)")
            end
            self._form[k] = v
         end
      end
      function instance_members:make_invisible_info(editor_id, destination, src)
         local info = self:get_or_create_info(editor_id)
         info.use_shared_info = awpa.env.built_in_shared_infos["InvisibleInfo"][1]
         if destination then
            if type(destination) == "userdata" or fex.topic.is(destination) then
               destination = { destination }
            end
            info.link_to = destination
         end
         return info
      end
      function instance_members:get_or_create_info(editor_id, src)
         local list = self.infos
         local size = #list
         for i = 1, size do
            local item = list[i]
            if item.editor_id == editor_id then
               return item
            end
         end
         local item = dovah.create_form(form_types.topic_info, { parent = self._form })
         item.editor_id = editor_id
         item = fex.topic_info(item)
         list[size + 1] = item
         if src then
            info:assign(src)
         end
         return item
      end
      function instance_members:place_info_before(subject, target)
         self._form:place_info_before(subject, target)
         -- Update our cached info list.
         self._infos = nil
         local _ = self.infos
      end
   end
end
