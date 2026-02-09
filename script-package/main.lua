
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
            node:for_each_child_element(function(node)
               if node.node_name == "condition-set" then
                  -- TODO
               elseif node.node_name == "or" then
                  node:for_each_child_element(function(node)
                     if node.node_name == "condition-set"
                     or node.node_name == "or"
                     then
                        error("can't nest these in an OR")
                     end
                     local item = awpa.condition()
                     item.is_or_linked = true
                     group.conditions[#group.conditions + 1] = item
                     item:from_xml(node)
                  end)
               else
                  local item = awpa.condition()
                  group.conditions[#group.conditions + 1] = item
                  item:from_xml(node)
               end
            end)
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
            local si = awpa.env.shared_infos_by_id[node.attributes["id"]]
            if not si then
               error("missing sharedinfo")
            end
            group.shared_infos[#group.shared_infos + 1] = si
            return
         end
      end)
   end

   root:for_each_child_element(function(node)
      if node.node_name == "shared-infos" then
         node:for_each_child_element(function(node)
            if node.node_name ~= "shared-info" then
               return
            end
            local item = awpa.shared_info_set()
            item:from_xml(node)
            node:for_each_child_element(function(node)
               if node.node_name == "line" then
                  local text = node:get_text_content()
                  if text then
                     item.lines[#item.lines + 1] = text
                  end
               end
            end)
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
   --path = "payload-test-simple-quest.xml",
   --path = "payload-test-simple-shared-info.xml",
   --path = "payload-test-simple-conditions.xml",
   path = "payload-test-nested-conditions.xml",
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