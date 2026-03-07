
--[[--
progresswin = ui.window.new()
do
   progresswin:set_layout("down")
   progresswin.title = "Progress"
   
   progressbar = ui.progress_bar.new()
   progresswin:add_child(progressbar)
end

progresswin:show()
progressbar:reset()
progressbar.format = "Loading XML..."

local loaded_quest_count = 0
--]]--

function process_xml(root)
   root:for_each_child_element(function(node)
      if node.node_name == "shared-infos" then
         node:for_each_child_element(function(node)
            if node.node_name ~= "shared-info" then
               error("unexpected element: " .. node.node_name)
            end
            local item = awpa.shared_info_set()
            item:from_xml(node)
         end)
         return
      end
      if node.node_name == "quest" then
--[[--
         loaded_quest_count = loaded_quest_count + 1
         progressbar.value  = loaded_quest_count
--]]--
         
         local quest = awpa.quest()
         quest:from_xml(node)
         return
      end
   end)
end

WINDOW = gui.window()
WINDOW:show()

--[[--
local file = dovah.package.load_file({
   --path = "payload-test-simple-quest.xml",
   --path = "payload-test-simple-shared-info.xml",
   --path = "payload-test-simple-conditions.xml",
   --path = "payload-test-nested-conditions.xml",
   --path = "payload-test-condition-sets.xml",
   --path = "payload-test-actor-overrides-begin-asking-about.xml",
   --path = "payload-test-actor-overrides-bribe.xml",
   --path = "payload-test-macros.xml",
   path = "payload-test-kitchen-sink.xml",
   type = "text"
})
local parser = xml.parser()
parser.retain_comments = true
parser:parse(file)
if not parser.root then
   error("No root element")
end
macros.transform(parser.root)

do
   local quest_count = 0
   parser.root:for_each_child_element(function(node)
      if node.node_name == "quest" then
         quest_count = quest_count + 1
      end
   end)
   progressbar.format = "Loading quest data..."
   progressbar.value   = 0
   progressbar.maximum = quest_count
end

process_xml(parser.root)
macros.revert(parser.root)

progressbar:reset()
progressbar.format = "Generating data..."

awpa.env:generate_content()
print("Done generating game data!")

progressbar.format = "Cloning XML for output..."

print("Cloning XML for output...")
local clone_root, xml_to_clone_map = parser.root:clone(true, true)

progressbar.format  = "Amending cloned XML for output..."
progressbar.value   = 0
progressbar.maximum = #awpa.env.quests
print("Amending clone for output...")
for i = 1, #awpa.env.quests do
   awpa.env.quests[i]:amend_xml_clone(xml_to_clone_map)
   progressbar.value = i
end

progresswin:hide()
-- Show window for letting the user save the modified XML:
do
   win = ui.window.new()
   btn = ui.file_save_button.new()
   btn.label = "XML amended with newly generated forms"
   win:set_layout("down")
   win:add_child(btn)
   win:show()
   
   local builder = string_builder()
   clone_root:serialize(builder)
   btn.data = builder:to_string()
end

-- Testing: verify that forms are properly recycled when we round-trip
print("Re-processing based on clone...")
awpa.env:reset()
process_xml(clone_root)
print("Done generating game data from clone!")
--]]--
