
if (not fex) or (not fex.form) then
   error("files loaded in wrong order")
end

do
   local instance_members = {}
   local instance_getters = {}
   local instance_setters = {}
   local static_members   = {}
   
   local forms_to_instances = {}
   
   fex.quest = make_class({
      superclass  = fex.form,
      constructor = function(self, form)
         if form.form_type ~= form_types.quest then
            error("fex.quest cannot wrap a non-quest")
         end
         forms_to_instances[form] = self
         self._branches = nil
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
      return fex.quest(form)
   end
   
   do -- [gs]etters
      local props = {
         "name",
         "object_window_category",
         "priority",
         "quest_flags",
         "quest_type",
      }
      local read_only_props = {
         "create_loc_alias",
         "create_ref_alias",
         "get_all_dialogue_branches",
         "get_all_dialogue_topics",
         "get_all_scenes",
         --
         "aliases",
         "aliases_by_id",
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
      function instance_members:get_all_dialogue_branches()
         if not self._branches then
            local list = self._form:get_all_dialogue_branches()
            for i = 1, #list do
               list[i] = fex.branch(list[i])
            end
            self._branches = list
         end
         return self._branches
      end
      function instance_members:get_or_create_branch(editor_id, branch_type)
         local list = self:get_all_dialogue_branches()
         local size = #list
         for i = 1, size do
            local item = list[i]
            if item.editor_id == editor_id then
               if branch_type then
                  item.type = branch_type
               end
               return item
            end
         end
         local item = dovah.create_form(form_types.dialogue_branch, { parent = self._form })
         item.editor_id = editor_id
         item = fex.branch(item)
         list[size + 1] = item
         if branch_type then
            item.type = branch_type
         end
         return item
      end
   end
end
