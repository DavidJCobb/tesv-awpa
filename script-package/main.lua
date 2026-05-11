
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

WINDOW = gui.window()
WINDOW:show()
