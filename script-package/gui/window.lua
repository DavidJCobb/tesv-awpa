
if not gui then
   gui = {}
end

do
   local instance_members = {}
   gui.window = make_class({
      constructor = function(self, body)
         self.tabs = {} -- vector<gui.tab>
         
         self.window   = ui.window.new()
         self.tabbox   = ui.tabbox.new()
         self.progress = ui.progress_bar.new()
         self.buttons  = {}
         
         self.window.title = "Ask Where People Are - Generator"
         self.window:set_layout("down")
         do
            local widget = ui.widget.new()
            widget:set_layout("ltr")
            widget.layout_margins = 0
            self.window:add_child(widget)
            do
               local button = ui.button.new("Add Tab")
               widget:add_child(button)
               button:on("OnActivated", "", function()
                  self:add_tab()
               end)
               self.buttons[#self.buttons + 1] = button
            end
            widget:add_spacer("h")
            do
               local button = ui.button.new("Delete Current Tab")
               widget:add_child(button)
               button:on("OnActivated", "", function()
                  local i = self.tabbox.selected_index
                  if i then
                     self.tabbox:remove_tab(i)
                     table.remove(self.tabs, i)
                  end
               end)
               self.buttons[#self.buttons + 1] = button
            end
         end
         self.window:add_child(self.tabbox)
         do
            local widget = ui.widget.new()
            widget:set_layout("ltr")
            widget.layout_margins = 0
            self.window:add_child(widget)
            do
               local button = ui.button.new("Generate Data")
               widget:add_child(button)
               button:on("OnActivated", "", function()
                  self:generate(false)
               end)
               self.buttons[#self.buttons + 1] = button
            end
            do
               local button = ui.button.new("Round-Trip Test")
               widget:add_child(button)
               button:on("OnActivated", "", function()
                  self:generate(true)
               end)
               self.buttons[#self.buttons + 1] = button
            end
            widget:add_child(self.progress)
         end
         
         self:add_tab()
      end,
      instance_members = instance_members
   })
   do -- member functions
      function instance_members:add_tab()
         local body = self.tabbox:add_tab()
         if body then
            self.tabs[#self.tabs + 1] = gui.tab(body)
         end
      end
      function instance_members:error(text)
         -- TODO: modal
         error(text)
      end
      function instance_members:progress_reset()
         self.progress.format  = ""
         self.progress.value   = 0
         self.progress.maximum = 1
      end
      function instance_members:progress_update(text, value, max)
         if text then
            self.progress.format = text
         end
         self.progress.minimum = 0
         if max then
            self.progress.maximum = max
         end
         self.progress.value = value or 0
      end
      function instance_members:progress_update_indeterminate(text)
         self.progress.minimum = 0
         self.progress.maximum = 0
         self.progress.format = text
      end
      function instance_members:generate(do_round_trip)
         for i = 1, #self.tabs do
            self.tabs[i]:set_allow_editing(false)
         end
         for i = 1, #self.buttons do
            self.buttons[i].enabled = false
         end
      
         awpa.env:reset()
         
         local payload_count <const> = #self.tabs
      
         self:progress_update("Parsing XML payloads... (%v/%m)", nil, payload_count)
         local payloads = {}
         for i = 1, payload_count do
            local tab     = self.tabs[i]
            local payload = {
               xml_root_src = nil,
               xml_root_dst = nil,
            }
            payloads[i] = payload
            
            do
               local parser = xml.parser()
               parser.retain_comments = true
               parser:parse(tab:get_input_xml())
               if not parser.root then
                  self:error(string.format("No root element in tab %d's payload.", i))
               end
               payload.xml_root_src = parser.root
            end
            macros.transform(payload.xml_root_src)
            process_xml(payload.xml_root_src)
            self:progress_update(nil, i, nil)
         end
         self:progress_update_indeterminate("Generating content...")
         awpa.env:generate_content()
         do
            self:progress_update("Preparing to update XML payloads... (%v/%m)", nil, payload_count)
            local all_clones_map = {}
            for i = 1, payload_count do
               local tab     = self.tabs[i]
               local payload = payloads[i]
               
               local clone_root, xml_to_clone_map = payload.xml_root_src:clone(true, true)
               payload.xml_root_dst = clone_root
               
               for k, v in pairs(xml_to_clone_map) do
                  all_clones_map[k] = v
               end
               self:progress_update(nil, i, nil)
            end
            self:progress_update("Generating updated XML payloads... (%v/%m)", nil, #awpa.env.quests)
            for i = 1, #awpa.env.quests do
               awpa.env.quests[i]:amend_xml_clone(all_clones_map)
               self:progress_update(nil, i, nil)
            end
         end
         self:progress_update("Serializing updated XML payloads... (%v/%m)", nil, payload_count)
         for i = 1, payload_count do
            local tab     = self.tabs[i]
            local payload = payloads[i]
            
            local builder = string_builder()
            payload.xml_root_dst:serialize(builder)
            tab:set_output_xml(builder:to_string())
            self:progress_update(nil, i, nil)
         end
         
         if do_round_trip then
            self:progress_update_indeterminate("Resetting state for round-trip...")
            awpa.env:reset()
            self:progress_update("Loading updated XML payloads... (%v/%m)", nil, payload_count)
            for i = 1, payload_count do
               local tab     = self.tabs[i]
               local payload = payloads[i]
               
               local deep = payload.xml_root_dst:clone(true)
               macros.transform(deep)
               process_xml(deep)
               self:progress_update(nil, i, nil)
            end
            self:progress_update_indeterminate("Generating content...")
            print("Performing round-trip test. If any infos are deleted by topic-helpers, then we failed to recycle infos properly.")
            awpa.env.diagnose_topic_helper_deletions = true
            awpa.env:generate_content()
            awpa.env.diagnose_topic_helper_deletions = false
            print("Round-trip test done.")
         end
         
         self:progress_reset()
         for i = 1, #self.tabs do
            self.tabs[i]:set_allow_editing(true)
         end
         for i = 1, #self.buttons do
            self.buttons[i].enabled = true
         end
      end
      function instance_members:show()
         self.window:show()
      end
   end
end