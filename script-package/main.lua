
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
         local quest = awpa.quest()
         quest:from_xml(node)
         return
      end
   end)
end

local file = dovah.package.load_file({
   --path = "payload-test-simple-quest.xml",
   --path = "payload-test-simple-shared-info.xml",
   --path = "payload-test-simple-conditions.xml",
   --path = "payload-test-nested-conditions.xml",
   --path = "payload-test-condition-sets.xml",
   --path = "payload-test-actor-overrides-begin-asking-about.xml",
   path = "payload-test-actor-overrides-bribe.xml",
   type = "text"
})
local parser = xml.parser()
parser.retain_comments = true
parser:parse(file)
if not parser.root then
   error("No root element")
end

process_xml(parser.root)

awpa.env:generate_content()
print("Done generating game data!")

print("Cloning XML for output...")
local clone_root, xml_to_clone_map = parser.root:clone(true, true)
print("Amending clone for output...")
for i = 1, #awpa.env.quests do
   awpa.env.quests:amend_xml_clone(xml_to_clone_map)
end

do
   win = ui.window.new()
   btn = ui.file_save_button.new()
   win:set_layout("down")
   win:add_child(btn)
   win:show()
   
   local builder = string_builder()
   clone_root:serialize(builder)
   btn.data = builder:to_string()
end

print("Re-processing based on clone...")
awpa.env:reset()
process_xml(clone_root)
print("Done generating game data from clone!")
