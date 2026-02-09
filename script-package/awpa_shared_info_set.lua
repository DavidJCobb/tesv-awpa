
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
      end
      function instance_members:find_or_create_forms(topic, existing_infos)
         local found_indices = {}
         local j = 1
         for i = 1, #self.lines do
            local text = self.lines[i]
            if has_masc_pronouns(text) then
               local text_m = text
               local text_f = swap_masc_pronouns_to_fem(text_m)
               
               local info_m = dovah.create_form(form_types.topic_info, { parent = topic })
               local info_f = dovah.create_form(form_types.topic_info, { parent = topic })
               info_m.responses:insert({ text = text_m })
               info_f.responses:insert({ text = text_f })
               info_m.editor_id = string.format("AWPASharedInfo%s%02dM", self.slug, i)
               info_f.editor_id = string.format("AWPASharedInfo%s%02dF", self.slug, i)
               
               self.forms[j] = info_m
               j = j + 1
               self.forms[j] = info_f
               j = j + 1
            else
               local info = dovah.create_form(form_types.topic_info, { parent = topic })
               local resp = info.responses:insert({
                  text = self.text,
               })
               info.editor_id = string.format("AWPASharedInfo%s%02d", self.slug, i)
               
               self.forms[j] = info
               j = j + 1
            end
         end
         
      end
   end
end