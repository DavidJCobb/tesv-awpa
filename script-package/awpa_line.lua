
if not awpa then
   awpa = {}
end

do
   local instance_members = {}
   awpa.line = make_class({
      constructor = function(self)
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
               local cnd = info.conditions[1]
               if not cnd or cnd.function_name ~= "GetIsSex" then
                  cnd = info.conditions:insert()
               end
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
      
      function instance_members:generate_info(topic)
         local info = dovah.create_form(form_types.topic_info, { parent = topic })
         local resp = info.responses:insert({
            script_notes = self.script_notes,
            text         = self.text,
         })
         info.hours_until_reset = self.hours_until_reset
         info.is_random = true
         
         local fem_info
         if has_masc_pronouns(self.text) then
            local target_alias = nil
            do
               local quest = topic.parent_quest
               target_alias = quest.aliases["ActorToFind"]
            end
         
            do
               local cnd = info.conditions:insert()
               cnd.run_on        = target_alias
               cnd.function_name = "GetIsSex"
               cnd.parameters[1] = "Male"
               cnd.comparison.operator = "=="
               cnd.comparison.operand  = 1
            end
            
            local fem_text = swap_masc_pronouns_to_fem(self.text)
            fem_info = dovah.create_form(form_types.topic_info, { parent = topic })
            local fem_resp = fem_info.responses:insert({
               script_notes = self.script_notes,
               text         = fem_text,
            })
            fem_info.hours_until_reset = self.hours_until_reset
            fem_info.is_random = true
            do
               local cnd = fem_info.conditions:insert()
               cnd.run_on        = target_alias
               cnd.function_name = "GetIsSex"
               cnd.parameters[1] = "Female"
               cnd.comparison.operator = "=="
               cnd.comparison.operand  = 1
            end
         end
         
         return info, fem_info
      end
   end
end