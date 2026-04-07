
if not awpa then
   error("incorrect file order")
end

do
   local instance_members = {}
   awpa.shared_info_reference = make_class({
      constructor = function(self)
         self.source_xml_node = nil
         
         self.source   = nil -- awpa.shared_info_set
         self.form_ids = {} -- vector<int>
         self.forms    = {} -- vector<topic_info>
         
         awpa.env:on_content_object_constructed()
      end,
      instance_members = instance_members,
   })
   do -- member functions
      function instance_members:from_xml(element)
         self.source_xml_node = element
         
         do
            local id = element.attributes["id"]
            if not id then
               error("`shared-info` reference specifies no `id`")
            end
            local si = awpa.env.shared_infos_by_id[id]
            if not si then
               error("missing sharedinfo: " .. tostring(id))
            end
            self.source = si
         end
         
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
      function instance_members:amend_xml_clone(nodemap)
         local node = nodemap[self.source_xml_node]
         
         local id_list = {}
         for i = 1, #self.forms do
            id_list[i] = self.forms[i]:form_id_to_string()
         end
         node.attributes["form-ids"] = table.concat(id_list, ',')
      end
      
      function instance_members:generate_infos(topic)
         local bench = benchmark.new()
      
         self.forms = {}
         
         local form_ids_after = {}
         do
            local actor_to_find
            local form_ids_prior <const> = self.form_ids
            local form_ids_count <const> = #form_ids_prior
            
            local src_forms <const> = self.source.forms
            local src_count <const> = #src_forms
            for i = 1, src_count do
               local si     = src_forms[i]
               local gender = nil
               do
                  local c = si.editor_id:sub(-1)
                  if c == "M" then
                     gender = "Male"
                  elseif c == "F" then
                     gender = "Female"
                  end
               end
               local info
               for j = 1, form_ids_count do
                  local f = dovah.get_form_by_id(form_ids_prior[j])
                  if  f
                  and f.form_type == form_types.topic_info
                  and f.use_shared_info == si
                  then
                     info = f
                     utils.clear_condition_list(info)
                     goto configure_info
                  end
               end
               info = dovah.create_form(form_types.topic_info, { parent = topic })
               ::configure_info::
               self.forms[i] = info
               form_ids_after[i] = info.form_id
               info.use_shared_info = si
               info.is_random = true
               if gender then
                  local cnd = info.conditions:insert()
                  if not actor_to_find then
                     actor_to_find = topic.parent_quest.aliases["ActorToFind"]
                  end
                  cnd.run_on              = actor_to_find
                  cnd.function_name       = "GetIsSex"
                  cnd.parameters[1]       = gender
                  cnd.comparison.operator = "=="
                  cnd.comparison.operand  = 1
               end
            end
         end
         self.form_ids = form_ids_after
         
         awpa.perflog:log(bench, "awpa.shared_info_reference:generate_infos(...) given definition '%s'", self.source.id)
         awpa.env:on_content_object_processed()
      end
   end
end