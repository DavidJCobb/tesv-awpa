
if not awpa then
   awpa = {}
end

do
   local instance_members = {}
   awpa.line = make_class({
      constructor = function(self)
         self.source_xml_node = nil
         
         self.hours_until_reset = 0
         self.script_notes      = ""
         self.text              = ""
         self.vanilla           = nil
         
         self.form_ids = {
            unisex = nil,
            male   = nil,
            female = nil,
         }
         self.forms = {
            unisex = nil,
            male   = nil,
            female = nil,
         }
      end,
      instance_members = instance_members,
   })
   do -- member functions
      function instance_members:from_xml(element)
         self.source_xml_node = element
         
         local hours = tonumber(element.attributes["hours-until-reset"])
         if hours then
            self.hours_until_reset = hours
            -- TODO: validate
         end
         
         local notes = element.attributes["script-notes"]
         if notes then
            self.script_notes = notes
         end
         
         local vanilla = element.attributes["vanilla"]
         if vanilla then
            -- TODO: parse form reference
         else
            vanilla = element.attributes["vanilla-fragment"]
            if vanilla then
               -- TODO: parse form reference
            end
         end
         
         self.text = element:get_text_content()
         
         do
            local id = element.attributes["form-id-m"]
            if id then
               id = tonumber(id, 16)
               self.form_ids.male = id
            end
         end
         do
            local id = element.attributes["form-id-f"]
            if id then
               id = tonumber(id, 16)
               self.form_ids.female = id
            end
         end
         do
            local id = element.attributes["form-id-u"]
            if id then
               id = tonumber(id, 16)
               self.form_ids.unisex = id
            end
         end
      end
      function instance_members:amend_xml_clone(nodemap)
         local node = nodemap[self.source_xml_element]
         if (self.hours_until_reset or 0) > 0 then
            node.attributes["hours-until-reset"] = self.hours_until_reset
         else
            node.attributes["hours-until-reset"] = nil
         end
         if self.script_notes and self.script_notes ~= "" then
            node.attributes["script-notes"] = self.script_notes
         else
            node.attributes["script-notes"] = nil
         end
         
         -- TODO: `vanilla`
         -- TODO: `vanilla-fragment`
         
         if self.form_ids.male then
            node.attributes["form-id-m"] = string.format("%08X", self.form_ids.male)
         else
            node.attributes["form-id-m"] = nil
         end
         if self.form_ids.female then
            node.attributes["form-id-f"] = string.format("%08X", self.form_ids.female)
         else
            node.attributes["form-id-f"] = nil
         end
         if self.form_ids.unisex then
            node.attributes["form-id-u"] = string.format("%08X", self.form_ids.unisex)
         else
            node.attributes["form-id-u"] = nil
         end
      end
      
      function instance_members:generate_infos(topic)
         local gendered = has_masc_pronouns(self.text)
         
         local target_alias = nil
         if gendered then
            target_alias = topic.parent_quest.aliases["ActorToFind"]
         end
         
         local function _get_or_create_by_id(id)
            if id then
               local info = dovah.get_form_by_id(id)
               if info and info.form_type == form_types.topic_info then
                  utils.replace_condition_list(info, {}) -- let group conditions be rebuilt from scratch
                  return info
               end
            end
            return dovah.create_form(form_types.topic_info, { parent = topic })
         end
         local function _configure(info, fem)
            info.hours_until_reset = self.hours_until_reset
            info.use_shared_info   = nil
            info.is_random = true
            
            if gendered then
               local cnd = info.conditions:insert()
               cnd.run_on        = target_alias
               cnd.function_name = "GetIsSex"
               if fem then
                  cnd.parameters[1] = "Female"
               else
                  cnd.parameters[1] = "Male"
               end
               cnd.comparison.operator = "=="
               cnd.comparison.operand  = 1
            end
         
            local resp = info.responses[1]
            if not resp then
               info.responses:insert()
               resp = info.responses[1]
            end
            resp.script_notes = self.script_notes
            if fem then
               resp.text = swap_masc_pronouns_to_fem(self.text)
            else
               resp.text = self.text
            end
         end
         
         if gendered then
            local info_m = _get_or_create_by_id(self.form_ids.male)
            local info_f = _get_or_create_by_id(self.form_ids.female)
            self.form_ids.unisex = nil
            self.form_ids.male   = info_m.form_id
            self.form_ids.female = info_f.form_id
            _configure(info_m, false)
            _configure(info_f, true)
            return info_m, info_f
         else
            local info_u = _get_or_create_by_id(self.form_ids.unisex)
            self.form_ids.unisex = info_u.form_id
            self.form_ids.male   = nil
            self.form_ids.female = nil
            _configure(info_u, false)
            return info_u
         end
      end
   end
end