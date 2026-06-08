
if not awpa then
   error("incorrect file order")
end

do
   local instance_members = {}
   awpa.topic_helper = make_class({
      constructor = function(self, form)
         self.form  = form
         self.infos = {
            desired_order = {}, -- vector<topic_info>
            desired_set   = {}, -- map<topic_info, bool>
         }
      end,
      instance_members = instance_members
   })
   do -- member functions
      function instance_members:append_desired_info(info)
         if self.infos.desired_set[info] then
            error("info is already desired")
         end
         self.infos.desired_order[#self.infos.desired_order + 1] = info
         self.infos.desired_set[info] = true
      end
      function instance_members:append_desired_infos(src_list)
         local dst_set = self.infos.desired_set
         for _, info in ipairs(src_list) do
            if dst_set[info] then
               error("info is already desired")
            end
         end
         local dst_list = self.infos.desired_order
         local dst_i    = #dst_list + 1
         for _, info in ipairs(src_list) do
            dst_list[dst_i] = info
            dst_set[info] = true
            dst_i = dst_i + 1
         end
      end
      function instance_members:prepend_desired_info(info)
         if self.infos.desired_set[info] then
            error("info is already desired")
         end
         table.insert(self.infos.desired_order, 1, info)
         self.infos.desired_set[info] = true
      end
      
      -- Reorder all to-be-retained infos. Pre-existing infos that haven't 
      -- been recycled will be forced to the end of the topic; after all 
      -- topic-helpers have finalized info ordering, they should all then 
      -- use the deletion function (below) to delete any leftover infos 
      -- that weren't recycled.
      function instance_members:finalize_info_order()
         local desired_order <const> = self.infos.desired_order
         local count_to_keep <const> = #desired_order
         local wrapped_topic <const> = self.form
         for i = 1, count_to_keep do
            local info = desired_order[i]
            local prev = desired_order[i - 1]
            wrapped_topic:place_info_after(info, prev)
         end
      end
      
      -- Delete any pre-existing infos that were never recycled (by this topic 
      -- or any other).
      function instance_members:finalize_leftover_info_deletion()
         local infos         = self.form:get_infos_as_table()
         local count_of_all  = #infos
         local count_to_keep = #self.infos.desired_order
         if count_of_all == count_to_keep then
            return
         end
         print(string.format("attempting to delete %u unused infos from [DIAL:%08X]%s...",
            count_of_all - count_to_keep,
            self.form.form_id,
            self.form.editor_id
         ))
         local desired_set <const> = self.infos.desired_set
         if awpa.env.diagnose_topic_helper_deletions then
            for i = count_to_keep + 1, count_of_all do
               local info = infos[i]
               if desired_set[info] then
                  error("failed to enforce info order; a desired info is near the end")
               end
               local text
               do
                  local si = info.use_shared_info
                  if si then
                     text = string.format("shared from: [%08X]%s", si.form_id, si.editor_id)
                  else
                     local resp = info.responses[1]
                     if resp then
                        text = '"' .. resp.text .. '"'
                     else
                        text = "<<NO RESPONSE DATA>>"
                     end
                  end
                  print(string.format(" - [INFO:%08X]%s: \"%s\"",
                     info.form_id,
                     info.editor_id,
                     text
                  ))
               end
               info:delete()
            end
         else
            for i = count_to_keep + 1, count_of_all do
               local info = infos[i]
               if desired_set[info] then
                  error("failed to enforce info order; a desired info is near the end")
               end
               info:delete()
            end
         end
      end
   end
end