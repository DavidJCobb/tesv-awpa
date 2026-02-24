
if not awpa then
   awpa = {}
end

do
   local instance_members = {}
   awpa.line = make_class({
      constructor = function(self)
         self.hours_until_reset  = 0
         self.script_notes       = ""
         self.text               = ""
         self.vanilla            = nil
         self.source_xml_element = nil
      end,
      instance_members = instance_members,
   })
   do -- member functions
      function instance_members:from_xml(element)
         self.source_xml_element = element
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
      end
      function instance_members:generate_info(topic)
         local info = topic:append_info({
            hours_until_reset = self.hours_until_reset,
            is_random = true,
            responses = {
               {
                  script_notes = self.script_notes,
                  text         = self.text,
               }
            }
         })
         
         local fem_info
         if has_masc_pronouns(self.text) then
            local target_alias = topic.parent_quest.aliases["ActorToFind"]
            info:append_condition({
               run_on        = target_alias,
               function_name = "GetIsSex",
               parameters    = { "Male" },
               comparison    = { operator = "==", operand = 1 }
            })
            
            fem_info = topic:append_info({
               conditions = {
                  {
                     run_on        = target_alias,
                     function_name = "GetIsSex",
                     parameters    = { "Female" },
                     comparison    = { operator = "==", operand = 1 }
                  }
               },
               hours_until_reset = self.hours_until_reset,
               is_random = true,
               responses = {
                  {
                     script_notes = self.script_notes,
                     text         = swap_masc_pronouns_to_fem(self.text),
                  }
               },
            })
         end
         
         return info, fem_info
      end
   end
end