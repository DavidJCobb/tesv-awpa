
if not awpa then
   error("incorrect file order")
end

do
   local instance_members = {}
   local static_members   = {}
   awpa.random_line_group = make_class({
      constructor = function(self)
         self.conditions   = {}
         self.children     = {} -- vector<variant<shared_info_reference, line, random_line_subgroup>>
      end,
      instance_members = instance_members,
      static_members   = static_members
   })
   do -- static member functions
      function static_members.fold(container)
         local function _copy_conditions(src_list, dst_list)
            local dst_i = #dst_list
            for i = 1, #src_list do
               dst_i = dst_i + 1
               dst_list[dst_i] = src_list[i]
            end
         end
         
         local dst_top = {}
         
         local inherit_conditions  = {}
         local dst_for_loose_lines = nil
         local function _walk(src_object, dst_object, outermost_subgroup)
            local src_list = src_object.children
            local dst_list
            if dst_object then
               dst_list = dst_object.children
            else
               dst_list = dst_top
            end
            
            local dst_has_own_lines = false
            for i = 1, #src_list do
               local src_item = src_list[i]
               if awpa.line.is(src_item)
               or awpa.shared_info_reference.is(src_item)
               then
                  dst_has_own_lines = true
                  break
               end
            end
            
            for i = 1, #src_list do
               local src_item = src_list[i]
               
               if awpa.line.is(src_item)
               or awpa.shared_info_reference.is(src_item)
               then
                  if dst_object then
                     dst_object.children[#dst_object.children + 1] = src_item
                  else
                     if not dst_for_loose_lines then
                        dst_for_loose_lines = awpa.random_line_group()
                        dst_top[#dst_top + 1] = dst_for_loose_lines
                     end
                     dst_for_loose_lines.children[#dst_for_loose_lines.children + 1] = src_item
                  end
                  goto continue
               end
               dst_for_loose_lines = nil
               
               if awpa.group.is(src_item)
               or awpa.top_level_group.is(src_item)
               then
                  local exclusive = true
                  if awpa.group.is(src_item) and not src_item.exclusive then
                     exclusive = false
                  end
                  
                  if exclusive and outermost_subgroup then
                     local name_outer = outermost_subgroup.name or "<UNNAMED>"
                     local name_inner = src_item.name or "<UNNAMED>"
                     error(string.format("group %g is nested in subgroup %s", tostring(name_inner), tostring(name_outer)))
                  end
                  
                  if not exclusive and not dst_object then
                     local name_inner = src_item.name or "<UNNAMED>"
                     error(string.format("group %g is a non-exclusive group with no parent/ancestor exclusive group", tostring(name_inner)))
                  end
                  
                  local src_subgroup
                  local conditions_to_keep
                  local dst_item
                  if exclusive then
                     if dst_has_own_lines then
                        dst_item = awpa.random_line_group()
                        dst_top[#dst_top + 1] = dst_item
                     end
                     if src_object.conditions then -- top-level internal objects e.g. `results_root_topic` lack these
                        conditions_to_keep = #inherit_conditions
                        _copy_conditions(src_object.conditions, inherit_conditions)
                     end
                  else
                     dst_item = awpa.random_line_subgroup()
                     dst_list[#dst_list + 1] = dst_item
                     src_subgroup = src_item
                  end
                  if dst_item then
                     _copy_conditions(inherit_conditions, dst_item.conditions)
                     _copy_conditions(src_item.conditions, dst_item.conditions)
                  end
                  _walk(src_item, dst_item, src_subgroup)
                  if conditions_to_keep then
                     for i = #inherit_conditions, conditions_to_keep + 1, -1 do
                        inherit_conditions[i] = nil
                     end
                  end
                  
                  goto continue
               end
               
               dovah.dump(src_item)
               error("unknown child type")
               
               ::continue::
            end
         end
         
         _walk(container, nil, nil)
         
         return dst_top
      end
   end
   do -- member functions
      --[[--
         
         Returns a table:
         
            {
               top_level_lines = { -- lines belonging directly to the group
                  male   = {}, -- vector<topic_info>
                  female = {}, -- vector<topic_info>
                  unisex = {}, -- vector<topic_info>
               },
               specific_lines = { -- lines belonging to random info subgroups
                  male   = {}, -- vector<topic_info>
                  female = {}, -- vector<topic_info>
                  unisex = {}, -- vector<topic_info>
               },
            }
         
      --]]--
      function instance_members:generate(topic_helper)
         local topic   <const> = topic_helper.form
         local results <const> = {
            top_level_lines = awpa.line_collection.new(),
            specific_lines  = awpa.line_collection.new(),
         }
         
         for i = 1, #self.children do
            local item = self.children[i]
            if awpa.line.is(item) then
               results.top_level_lines:generate_line(item, topic, self.conditions)
            elseif awpa.shared_info_reference.is(item) then
               results.top_level_lines:generate_shared_info(item, topic, self.conditions)
            elseif awpa.random_line_subgroup.is(item) then
               local conditions = { table.unpack(self.conditions) }
               results.specific_lines:absorb(item:generate(topic, conditions))
            else
               error("unexpected object")
            end
         end
         
         local function _store_list(list, last_is_random_end)
            local size = #list
            for i = 1, size do
               topic_helper:append_desired_info(list[i])
            end
            if last_is_random_end and size > 0 then
               list[size].is_random_end = true
            end
         end
         if #results.top_level_lines.male > 0 then
            --
            -- If the outermost group has gendered lines, then the ordering is:
            --
            --  - Unisex lines (all)
            --  - Inner male lines
            --  - Outer male lines
            --     - Last one is Random End
            --  - Inner female lines
            --  - Outer female lines
            --     - Last one is Random End
            --
            _store_list(results.top_level_lines.unisex)
            _store_list(results.specific_lines.unisex)
            _store_list(results.specific_lines.male)
            _store_list(results.top_level_lines.male, true)
            _store_list(results.specific_lines.female)
            _store_list(results.top_level_lines.female, true)
         elseif #results.top_level_lines.unisex > 0 then
            --
            -- If the outermost group has no gendered lines, then the ordering is:
            --
            --  - Inner male lines
            --  - Inner female lines
            --  - Inner unisex lines
            --  - Outer unisex lines
            --     - Last one is Random End
            --
            _store_list(results.specific_lines.male)
            _store_list(results.specific_lines.female)
            _store_list(results.specific_lines.unisex)
            _store_list(results.top_level_lines.unisex, true)
         else
            --
            -- If a group is empty, it shouldn't exist; the children should've been made 
            -- groups of their own instead.
            --
            assert(false, "not implemented")
         end
         
         return results
      end
   end
end