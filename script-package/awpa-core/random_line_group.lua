
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
         self.name         = "" -- for debugging
      end,
      instance_members = instance_members,
      static_members   = static_members
   })
   do -- static member functions
      function static_members.fold(container)
         local function _is_content_object(o)
            if awpa.line.is(o)
            or awpa.shared_info_reference.is(o)
            or awpa.top_level_group.is(o)
            or awpa.group.is(o)
            then
               return true
            end
            return false
         end
         
         local dst_top = {}
         local mapping = {}
         local dummy_parent
         
         local function _get_dummy_parent()
            if not dummy_parent then
               dummy_parent = awpa.random_line_group()
            end
            return dummy_parent
         end
         
         local function _handle_leaf(src_object, dst_parent)
            if awpa.line.is(src_object)
            or awpa.shared_info_reference.is(src_object)
            then
               dst_parent = dst_parent or _get_dummy_parent()
               dst_parent.children[#dst_parent.children + 1] = src_object
               return true
            end
            return false
         end
         local function _handle_inner(src_object, dst_parent)
            if _handle_leaf(src_object, dst_parent) then
               return true
            end
            if awpa.group.is(src_object) and not src_object.exclusive then
               local dst_object = awpa.random_line_subgroup()
               utils.join(dst_object.conditions, src_object.conditions)
               dst_object.name = src_object.name or dst_object.name
               
               dst_parent = dst_parent or _get_dummy_parent()
               local dst_i = #dst_parent.children + 1
               dst_parent.children[dst_i] = dst_object
               
               for i = 1, #src_object.children do
                  _handle_inner(src_object.children[i], dst_object)
               end
               
               if #dst_object.children == 0 then
                  --
                  -- Do not retain empty groups.
                  --
                  dst_parent.children[dst_i] = nil
               end
               
               return true
            end
            return false
         end
         local function _handle_outer(src_object, dst_parent)
            if _handle_inner(src_object, dst_parent) then
               return
            end
            if awpa.top_level_group.is(src_object)
            or awpa.group.is(src_object)
            then
               if awpa.random_line_subgroup.is(dst_parent) then
                  error("random top-group not allowed inside of random sub-group")
               end
               local dst_object = awpa.random_line_group()
               dst_object.name = src_object.name or src_object.editor_id_slug or dst_object.name
               do
                  local subject   = src_object
                  local ancestors = {}
                  while subject do
                     ancestors[#ancestors + 1] = subject
                     subject = subject.parent
                     if not _is_content_object(subject) then
                        break
                     end
                  end
                  for i = #ancestors, 1, -1 do
                     local item = ancestors[i]
                     utils.join(dst_object.conditions, item.conditions)
                  end
               end
               for i = 1, #src_object.children do
                  _handle_outer(src_object.children[i], dst_object)
               end
               
               --
               -- Insert outer groups after their contents are generated, so that when random 
               -- top-groups are nested, the more-specific ones are checked before their less-
               -- specific parents. (We can also take this opportunity to filter out groups 
               -- that have no direct children.)
               --
               if #dst_object.children > 0 then
                  dst_top[#dst_top + 1] = dst_object
               end
               
               return
            end
            
            dovah.dump(src_object)
            error("unknown child type")
         end
         
         if _is_content_object(container) then
            _handle_outer(container)
         else
            for i = 1, #container.children do
               _handle_outer(container.children[i])
            end
         end
         if dummy_parent then
            dst_top[#dst_top + 1] = dummy_parent
         end
         
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
      function instance_members:generate(topic_helper, postprocess)
         local topic   <const> = topic_helper.form
         local results <const> = {
            top_level_lines = awpa.line_collection(),
            specific_lines  = awpa.line_collection(),
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
         
         if postprocess then
            results.top_level_lines:for_each_line(postprocess)
            results.specific_lines:for_each_line(postprocess)
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