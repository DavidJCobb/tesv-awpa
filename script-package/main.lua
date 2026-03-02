
-- TODO

function process_xml(root)
   local CONDITION_ELEMENT_NAMES_TO_CONSTRUCTORS = {
      ["actor-base"]   = awpa.conditions.actor_base,
      ["death-count"]  = awpa.conditions.death_count,
      ["enable-state"] = awpa.conditions.enable_state,
      ["global"]       = awpa.conditions.global,
      ["location"]     = awpa.conditions.location,
      ["papyrus-quest-variable"] = awpa.conditions.papyrus_quest_variable,
      ["parent-cell"]  = awpa.conditions.parent_cell,
      ["quest-stage"]  = awpa.conditions.quest_stage,
      ["x"]            = awpa.conditions.position,
      ["y"]            = awpa.conditions.position,
      ["z"]            = awpa.conditions.position,
   }
   
   local function process_condition_list(owner, scope, element)
      awpa.condition.construct_list_from_xml(owner, scope, element)
   end

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
         node:for_each_child_element(function(node)
            if quest:_consume_xml_child_as_scope(node) then
               return
            end
            if node.node_name == "actors" then
               node:for_each_child_element(function(node)
                  if node.node_name ~= "actor" then
                     error("unexpected element: " .. node.node_name)
                  end
                  local actor = awpa.actor(quest)
                  quest.actors[#quest.actors + 1] = actor
                  actor:from_xml(node)
               end)
               return
            end
            if node.node_name == "top-g" then
               local group = awpa.top_level_group()
               local list  = quest.results_root_topic.children
               list[#list + 1] = group
               group.parent = quest
               group:from_xml(node)
               return
            end
            if node.node_name == "g" then
               local group = awpa.group()
               local list  = quest.results_root_topic.children
               list[#list + 1] = group
               group.parent = quest
               group:from_xml(node)
               return
            end
            if node.node_name == "macro" then
               -- TODO
               return
            end
         end)
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
do
   local function shallow_update(item)
      local src_node = item.source_xml_node
      local dst_node = xml_to_clone_map[src_node]
      item:to_xml(dst_node)
   end
   
   local function child_list_update(item)
      local src_node = item.source_xml_node
      local dst_node = xml_to_clone_map[src_node]
      item:to_xml(dst_node)
      
      if awpa.group.is(item)
      or awpa.top_level_group.is(item)
      then
         for i = 1, #item.children do
            child_list_update(item.children[i])
         end
      end
   end
   
   for i = 1, #awpa.env.quests do
      local item = awpa.env.quests[i]
      shallow_update(item)
      
      for j = 1, #item.actors do
         local actor_info = item.actors[j]
         shallow_update(actor_info)
         do -- bribe override
            local over = actor_info.overrides.begin_asking_to.bribe
            if over then
               for _, v in ipairs({ "begin", "accept", "refuse", "poor" }) do
                  local t = over.contents[v]
                  for i = 1, #t.children do
                     child_list_update(t.children[i])
                  end
               end
            end
         end
         -- TODO: other actor overrides
      end
      
      do
         local list = item.results_root_topic.children
         for i = 1, #list do
            child_list_update(list[i])
         end
      end
   end
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
