
-- TODO

function process_xml(root)
   function process_constant(scope, element)
      local item = awpa.constant()
      local list = scope.constants
      list[#list + 1] = item
      item:from_xml(node)
      return
   end

   function process_group(group, element)
      element:for_each_child_element(function(node)
         if node.node_name == "condition-set" then
            -- TODO
            return
         end
         if node.node_name == "conditions" then
            -- TODO
            return
         end
         if node.node_name == "constant" then
            process_constant(group, node)
            return
         end
         if node.node_name == "g" then
            local child = awpa.group()
            group.groups[#group.groups + 1] = child
            child.parent = group
            child:from_xml(node)
            process_group(child, node)
            return
         end
         if node.node_name == "line" then
            local item = awpa.line()
            local list = group.lines
            list[#list + 1] = item
            item:from_xml(node)
            return
         end
         if node.node_name == "shared-info" then
            -- TODO: generate references to shared infos
            return
         end
      end)
   end

   root:for_each_child_element(function(node)
      if node.node_name == "shared-infos" then
         local item = awpa.shared_info_set()
         item:from_xml(node)
         node:for_each_child_element(function(node)
            if node.node_name == "line" then
               local text = ""
               for i = 1, #node.children do
                  local child = node.children[i]
                  if xml.text.is(child) then
                     text = text .. child.data
                  end
               end
               if text then
                  item.lines[#item.lines + 1] = text
               end
            end
         end)
         return
      end
      if node.node_name == "quest" then
         local quest = awpa.quest()
         quest:from_xml(node)
         node:for_each_child_element(function(node)
            if node.node_name == "actors" then
               node:for_each_child_element(function(node)
                  if node.node_name ~= "actor" then
                     return -- TODO: warn: unexpected element
                  end
                  local actor = awpa.actor()
                  quest.actors[#quest.actors + 1] = actor
                  actor:from_xml(node)
               end)
               return
            end
            if node.node_name == "condition-set" then
               -- TODO
               return
            end
            if node.node_name == "constant" then
               process_constant(quest, node)
               return
            end
            if node.node_name == "g" then
               local group = awpa.group()
               quest.groups[#quest.groups + 1] = group
               group.parent = quest
               group:from_xml(node)
               process_group(group, node)
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
   path = "payload-test-simple-quest.xml",
   type = "text"
})
local parser = xml.parser()
parser:parse(file)
if not parser.root then
   error("No root element")
end

process_xml(parser.root)

dovah.dump(awpa.env)

awpa.env:generate_content()
dovah.dump(awpa.env)