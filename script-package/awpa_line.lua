
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
         
         local text = ""
         for i = 1, #element.children do
            local node = element.children[i]
            if xml.text:is(node) then
               text = text .. node.data
            end
         end
         self.text = text
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
               cnd.function_name = "GetSex"
               cnd.comparison.operator = "=="
               cnd.comparison.operand  = 0
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
               cnd.function_name = "GetSex"
               cnd.comparison.operator = "=="
               cnd.comparison.operand  = 1
            end
         end
         
         return info, fem_info
      end
   end
end