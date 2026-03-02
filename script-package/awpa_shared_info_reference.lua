
if not awpa then
   error("incorrect file order")
end

do
   local instance_members = {}
   awpa.shared_info_reference = make_class({
      superclass  = awpa.scope,
      constructor = function(self)
         self.source_xml_node = nil
         
         self.source   = nil -- awpa.shared_info_set
         self.form_ids = {} -- vector<int>
         self.forms    = {} -- vector<topic_info>
      end,
      instance_members = instance_members,
   })
   do -- member functions
      function instance_members:from_xml(element)
         self.source_xml_node = element
         
         local id_list = element.attributes["form-ids"]
         if id_list then
            local i = 1
            for id in id_list:gmatch('([^,]+)') do
               id = tonumber(id, 16)
               self.form_ids[i] = id
               i = i + 1
            end
         end
      end
      function instance_members:to_xml(node)
         local id_list = {}
         for i = 1, #self.forms do
            id_list[i] = self.forms[i]:form_id_to_string()
         end
         node.attributes["form-ids"] = table.concat(id_list, ',')
      end
      
      function instance_members:generate_infos(topic)
         self.forms = {}
         for i = 1, #self.source.forms do
            local si     = self.source.forms[i]
            local gender = nil
            do
               local id = si.editor_id
               local c  = id:sub(#id)
               if c == "M" then
                  gender = "Male"
               elseif c == "F" then
                  gender = "Female"
               end
            end
            local info
            for i = 1, #self.form_ids do
               local f = dovah.get_form_by_id(self.form_ids[i])
               if f and f.form_type == form_types.topic_info then
                  info = f
                  break
               end
            end
            if not info then
               info = dovah.create_form(form_types.topic_info, { parent = topic })
            end
            self.forms[i] = info
            info.use_shared_info = si
            info.is_random = true
            utils.replace_condition_list(info, {})
            if gender then
               local cnd = info.conditions:insert()
               cnd.run_on              = topic.parent_quest.aliases["ActorToFind"]
               cnd.function_name       = "GetIsSex"
               cnd.parameters[1]       = gender
               cnd.comparison.operator = "=="
               cnd.comparison.operand  = 1
            end
         end
         local ids = {}
         for i = 1, #self.forms do
            ids[i] = self.forms[i].form_id
         end
         self.form_ids = ids
      end
   end
end