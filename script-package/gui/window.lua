
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
         
         self.subwidgets = {
            generate_flat = nil,
            dont_generate = nil,
         }
         
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
            widget:add_spacer("h")
            do
               local button = ui.button.new("Perf log")
               widget:add_child(button)
               button:on("OnActivated", "", function()
                  self:show_perf_log()
               end)
               self.buttons[#self.buttons + 1] = button
            end
         end
         self.window:add_child(self.tabbox)
         do -- options area
            local widget = ui.widget.new()
            widget:set_layout("down")
            widget.layout_margins = 0
            self.window:add_child(widget)
            do
               local check = ui.checkbox.new("Generate flat (no sub-topics)")
               check.checked = true
               widget:add_child(check)
               self.subwidgets.generate_flat = check
            end
            do
               local check = ui.checkbox.new("Don't actually generate (i.e. debug loading)")
               widget:add_child(check)
               self.subwidgets.dont_generate = check
            end
         end
         do -- bottom row
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
         
         self._tracking_lines = false
         awpa.env.content_counts.on_change = function(extant, generated)
            if self._tracking_lines then
               self:progress_update(generated)
            else
               self:progress_start("Generating lines... (%v/%m)", extant)
               if generated > 0 then
                  self:progress_update(generated)
               end
               self._tracking_lines = true
            end
         end
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
      function instance_members:progress_start(text, max)
         self.progress.format  = text
         self.progress.minimum = 0
         self.progress.maximum = max
         self.progress.value   = 0
      end
      function instance_members:progress_update(value)
         self.progress.value = value
      end
      function instance_members:progress_indeterminate(text)
         self.progress.minimum = 0
         self.progress.maximum = 0
         self.progress.format  = text
         self.progress.value   = 0 -- avoids Qt API jank that hides the text
      end
      function instance_members:set_editing_enable_state(enabled)
         for i = 1, #self.tabs do
            self.tabs[i]:set_allow_editing(enabled)
         end
         for i = 1, #self.buttons do
            self.buttons[i].enabled = enabled
         end
         for _, v in pairs(self.subwidgets) do
            v.enabled = enabled
         end
      end
      function instance_members:show_perf_log()
         local win = ui.window.new()
         win.title = "Perf log"
         win:set_layout("down")
         do
            local tb = ui.textarea.new()
            win:add_child(tb)
            tb.text = awpa.perflog:to_string()
         end
         win:show()
      end
      function instance_members:generate(do_round_trip)
         self:set_editing_enable_state(false)
      
         awpa.env:reset()
         awpa.perflog:clear()
         
         awpa.env.generate_flat_results = self.subwidgets.generate_flat.checked
         
         local payload_count <const> = #self.tabs
      
         self:progress_start("Parsing XML payloads... (%v/%m)", payload_count)
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
local bench_a = benchmark.new()
local bench_b = benchmark.new()
            macros.transform(payload.xml_root_src)
bench_a:stop()
            process_xml(payload.xml_root_src)
bench_b:stop()
awpa.perflog:log(bench_a, "Macro process time for tab %d", i)
awpa.perflog:log(bench_b, "Post-parse XML load time for tab %d", i)
            self:progress_update(i)
         end
         if self.subwidgets.dont_generate.checked then
            self:progress_reset()
            self:set_editing_enable_state(true)
            return
         end
         self:progress_indeterminate("Generating content...")
         self._tracking_lines = false
         awpa.env:generate_content()
         do
            self:progress_start("Preparing to update XML payloads... (%v/%m)", payload_count)
            local all_clones_map = {}
            for i = 1, payload_count do
               local tab     = self.tabs[i]
               local payload = payloads[i]
               
               local clone_root, xml_to_clone_map = payload.xml_root_src:clone(true, true)
               payload.xml_root_dst = clone_root
               
               for k, v in pairs(xml_to_clone_map) do
                  all_clones_map[k] = v
               end
               self:progress_update(i)
            end
            self:progress_start("Generating updated XML payloads... (%v/%m)", #awpa.env.quests)
            for i = 1, #awpa.env.quests do
               awpa.env.quests[i]:amend_xml_clone(all_clones_map)
               self:progress_update(i)
            end
         end
         self:progress_start("Serializing updated XML payloads... (%v/%m)", payload_count)
         for i = 1, payload_count do
            local tab     = self.tabs[i]
            local payload = payloads[i]
            
            local builder = string_builder()
            payload.xml_root_dst:serialize(builder)
            tab:set_output_xml(builder:to_string())
            self:progress_update(i)
         end
         
         if do_round_trip then
            self:progress_indeterminate("Resetting state for round-trip...")
            awpa.env:reset()
            self:progress_start("Loading updated XML payloads... (%v/%m)", payload_count)
            for i = 1, payload_count do
               local tab     = self.tabs[i]
               local payload = payloads[i]
               
               local deep = payload.xml_root_dst:clone(true)
               macros.transform(deep)
               process_xml(deep)
               self:progress_update(i)
            end
            self:progress_indeterminate("Generating content...")
            print("Performing round-trip test. If any infos are deleted by topic-helpers, then we failed to recycle infos properly.")
            awpa.env.diagnose_topic_helper_deletions = true
            awpa.env:generate_content()
            awpa.env.diagnose_topic_helper_deletions = false
            print("Round-trip test done.")
         end
         
         self:progress_reset()
         self:set_editing_enable_state(true)
      end
      function instance_members:show()
         self.window:show()
      end
   end
end