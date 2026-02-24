
if not fex then
   fex = {}
end

do
   local instance_members = {}
   local instance_getters = {}
   local instance_setters = {},
   fex.branch = make_class({
      constructor = function(self, form)
         self._form = form
      end,
      instance_members = instance_members,
      getters          = instance_getters,
      setters          = instance_setters,
   })
   do -- [gs]etters
      local props = {
         "editor_id",
         "form_id",
      }
      local read_only_props = {
         "delete",
         "duplicate",
         "form_id_to_string",
         "get_last_source_file",
         "get_source_file_list",
         "get_user_forms",
         --
         "flags",
         "form_type",
         "papyrus",
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
   end
end
