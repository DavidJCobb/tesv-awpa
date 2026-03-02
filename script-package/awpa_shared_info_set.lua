
if not awpa then
   awpa = {}
end

do
   local instance_members = {}
   awpa.shared_info_set = make_class({
      constructor = function(self)
         self.id    = nil
         self.value = nil
         self.slug  = nil
         self.lines = {}
         
         local list = awpa.env.shared_infos
         list[#list + 1] = self
         
         self.forms = {}
      end,
      instance_members = instance_members,
   })
   do -- member functions
      function instance_members:from_xml(element)
         awpa.env:set_object_id(self, element.attributes["id"])
         self.slug = element.attributes["editor-id-slug"]
         if not self.id then
            error("Shared infos must have an ID")
         end
         if not self.slug then
            error("Shared infos must have an editor ID slug")
         end
         
         element:for_each_child_element(function(node)
            if node.node_name == "line" then
               local text = node:get_text_content()
               if text then
                  self.lines[#self.lines + 1] = text
               end
               return
            end
            error("node name is not allowed here: " .. node.node_name)
         end)
      end
      
      function instance_members:find_or_create_forms(topic, existing_infos)
         local found_indices = {}
         local j = 1
         for i = 1, #self.lines do
            local text         = self.lines[i]
            local has_pronouns = has_masc_pronouns(text)
            
            local editor_id_u = string.format("AWPASharedInfo%s%02d", self.slug, i)
            local editor_id_m = editor_id_u .. "M"
            local editor_id_f = editor_id_u .. "F"
         
            -- Find existing infos, if any exist.
            local prior_u
            local prior_m
            local prior_f
            for j = 1, #existing_infos do
               local ei = existing_infos[j]
               if ei.editor_id == editor_id_u then
                  prior_u = ei
                  break
               elseif ei.editor_id == editor_id_m then
                  prior_m = ei
                  if prior_f then
                     break
                  end
               elseif ei.editor_id == editor_id_f then
                  prior_f = ei
                  if prior_m then
                     break
                  end
               end
            end
            
            -- Recycle existing infos.
            local after_u
            local after_m
            local after_f
            if prior_u then
               if has_pronouns then
                  after_m = prior_u
               else
                  after_u = prior_u
               end
            end
            if prior_m or prior_f then
               if has_pronouns then
                  after_m = prior_m
                  after_f = prior_f
               else
                  after_u = prior_m or prior_f
                  if prior_m and prior_f then
                     prior_f:delete()
                  end
               end
            end
         
            if has_pronouns then
               local text_m = text
               local text_f = swap_masc_pronouns_to_fem(text_m)
               
               if not after_m then
                  after_m = dovah.create_form(form_types.topic_info, { parent = topic })
               end
               if not after_f then
                  after_f = dovah.create_form(form_types.topic_info, { parent = topic })
               end
               after_m.editor_id = editor_id_m
               after_f.editor_id = editor_id_f
               utils.replace_info_responses(after_m, text_m)
               utils.replace_info_responses(after_f, text_f)
               
               self.forms[j] = after_m
               j = j + 1
               self.forms[j] = after_f
               j = j + 1
            else
               if not after_u then
                  after_u = dovah.create_form(form_types.topic_info, { parent = topic })
               end
               after_u.editor_id = editor_id_u
               utils.replace_info_responses(after_u, text)
               
               self.forms[j] = after_u
               j = j + 1
            end
         end
      end
   end
end