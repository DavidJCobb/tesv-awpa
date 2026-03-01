
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
      local dst_is_cset = awpa.condition_set.is(owner)
      
      local last_or_linked = nil
      element:for_each_child_element(function(node)
         local function _make_condition(node)
            local cls = CONDITION_ELEMENT_NAMES_TO_CONSTRUCTORS[node.node_name]
            if not cls then
               error("unrecognized tag in condition list: " .. node.node_name)
            end
            local item = cls()
            owner.conditions[#owner.conditions + 1] = item
            item.owning_scope = scope
            item:from_xml(node)
            return item
         end
      
         if node.node_name == "or" then
            node:for_each_child_element(function(node)
               if node.node_name == "condition-set"
               or node.node_name == "or"
               then
                  error("can't nest these in an OR")
               end
               last_or_linked = _make_condition(node)
               last_or_linked.is_or_linked = true
            end)
         else
            if last_or_linked then
               last_or_linked.is_or_linked = false
               last_or_linked = nil
            end
            if node.node_name == "condition-set" then
               if dst_is_cset then
                  error("condition sets cannot reference each other")
               end
               local name = node.attributes["name"]
               if not name then
                  error("condition set reference with no name (is this a misplaced definition?)")
               end
               name = tostring(name)
               local cs = scope:resolve_condition_set(name)
               if not cs then
                  error("condition set `" .. name .. "` not found")
               end
               cs:apply_to(owner, node)
            else
               _make_condition(node)
            end
         end
      end)
      if last_or_linked then
         last_or_linked.is_or_linked = false
      end
   end

   local function process_condition_set(scope, element)
      local cset = awpa.condition_set()
      local list = scope.condition_sets
      list[#list + 1] = cset
      cset:from_xml(element)
      cset.owning_scope = scope
      
      process_condition_list(cset, scope, element)
      
      return
   end

   local function process_constant(scope, element)
      local item = awpa.constant()
      local list = scope.constants
      list[#list + 1] = item
      item:from_xml(node)
      scope.constants_by_name[item.name] = item
      return
   end

   local function process_group(group, element)
      element:for_each_child_element(function(node)
         if node.node_name == "condition-set" then
            process_condition_set(group, node)
            return
         end
         if node.node_name == "conditions" then
            process_condition_list(group, group, node)
            return
         end
         if node.node_name == "constant" then
            process_constant(group, node)
            return
         end
         if node.node_name == "top-g" then
            error("top-level groups cannot be nested")
         end
         if node.node_name == "g" then
            local item = awpa.group()
            local list  = group.children
            list[#list + 1] = item
            item.parent = group
            item:from_xml(node)
            process_group(item, node)
            return
         end
         if node.node_name == "line" then
            local item = awpa.line()
            local list = group.children
            list[#list + 1] = item
            item:from_xml(node)
            return
         end
         if node.node_name == "shared-info" then
            local si = awpa.env.shared_infos_by_id[node.attributes["id"]]
            if not si then
               error("missing sharedinfo")
            end
            local item = awpa.shared_info_reference()
            local list = group.children
            list[#list + 1] = item
            item.source = si
            item:from_xml(node)
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
                  
                  node:for_each_child_element(function(node)
                     if node.node_name == "begin-asking-about" then
                        node:for_each_child_element(function(node)
                           if node.node_name == "conditions" then
                              local over = actor.overrides.begin_asking_about
                              process_condition_list(over, quest, node)
                              for i = 1, #over.conditions do
                                 over.conditions[i].is_override = actor
                              end
                              return
                           end
                        end)
                     elseif node.node_name == "begin-asking-to" then
                        local over = actor.overrides.begin_asking_to
                        node:for_each_child_element(function(node)
                           if node.node_name == "bribe" then
                              local bribe = over.bribe
                              if not bribe then
                                 over.bribe = awpa.actor_override_bribe()
                                 bribe = over.bribe
                              end
                              node:for_each_child_element(function(node)
                                 if node.node_name == "conditions" then
                                    process_condition_list(bribe, quest, node)
                                 else
                                    local function _read_line_set(key, node)
                                       node:for_each_child_element(function(node)
                                          local list = bribe.content[key]
                                          if node.node_name == "line" then
                                             local item = awpa.line()
                                             list[#list + 1] = item
                                             item:from_xml(node)
                                          elseif node.node_name == "g" then
                                             local child = awpa.group()
                                             list[#list + 1] = child
                                             child.parent = nil
                                             child:from_xml(node)
                                             process_group(child, node)
                                          elseif node.node_name == "top-g" then
                                             error("top-level groups cannot appear here")
                                          end
                                       end)
                                    end
                                    if node.node_name == "begin-lines" then
                                       _read_line_set("begin", node)
                                    elseif node.node_name == "accept-lines" then
                                       _read_line_set("accept", node)
                                    elseif node.node_name == "refuse-lines" then
                                       _read_line_set("refuse", node)
                                    elseif node.node_name == "poor-lines" then
                                       _read_line_set("poor", node)
                                    end
                                 end
                              end)
                           elseif node.node_name == "line" then
                              local list = over.results
                              local item = awpa.line()
                              list[#list + 1] = item
                              item:from_xml(node)
                           elseif node.node_name == "g" then
                              local list  = over.results
                              local child = awpa.group()
                              list[#list + 1] = child
                              child.parent = nil
                              child:from_xml(node)
                              process_group(child, node)
                           elseif node.node_name == "top-g" then
                              error("top-level groups cannot appear here")
                           end
                        end)
                     elseif node.node_name == "begin-responding" then
                        -- TODO
                     end
                  end)
                  
               end)
               return
            end
            if node.node_name == "condition-set" then
               process_condition_set(quest, node)
               return
            end
            if node.node_name == "constant" then
               process_constant(quest, node)
               return
            end
            if node.node_name == "top-g" then
               local group = awpa.top_level_group()
               local list  = quest.results_root_topic.children
               list[#list + 1] = group
               group.parent = quest
               group:from_xml(node)
               process_group(group, node)
               return
            end
            if node.node_name == "g" then
               local group = awpa.group()
               local list  = quest.results_root_topic.children
               list[#list + 1] = group
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
   --path = "payload-test-nested-conditions.xml",
   --path = "payload-test-condition-sets.xml",
   --path = "payload-test-actor-overrides-begin-asking-about.xml",
   path = "payload-test-actor-overrides-bribe.xml",
   type = "text"
})
local parser = xml.parser()
parser:parse(file)
if not parser.root then
   error("No root element")
end

process_xml(parser.root)

--dovah.dump(awpa.env)

awpa.env:generate_content()
print("Done!")