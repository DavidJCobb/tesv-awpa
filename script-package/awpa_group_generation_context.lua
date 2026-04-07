
if not awpa then
   error("incorrect file order")
end

do
   local instance_members = {}
   awpa.group_generation_context = make_class({
      constructor = function(self, topic_helper)
         assert(not not topic_helper)
         self.conditions   = {}
         self.speaker      = nil
         self.topic_helper = topic_helper
      end,
      instance_members = instance_members
   })
   do -- member functions
      function instance_members:_push_conditions_from(item)
         local dst = #self.conditions
         for i = 1, #item.conditions do
            self.conditions[dst + i] = item.conditions[i]
         end
      end
      function instance_members:_pop_conditions_after(count)
         local size = #self.conditions
         for i = size, count + 1, -1 do
            self.conditions[i] = nil
         end
      end
      
      function instance_members:generate_child(item, _is_recursive_invocation)
         local cond_count   <const> = #self.conditions
         local topic_helper <const> = self.topic_helper
         local topic        <const> = topic_helper.form
         
         local needs_random_end = false
         local speaker
         if not _is_recursive_invocation then
            speaker = self.speaker
         end
         
         local info_count_prior = #topic_helper.infos.desired_order
         if awpa.line.is(item) then
            local a, b = item:generate_infos(topic)
            utils.append_condition_list(a, self.conditions)
            topic_helper:append_desired_info(a)
            if b then
               utils.append_condition_list(b, self.conditions)
               topic_helper:append_desired_info(b)
            end
         elseif awpa.group.is(item) or awpa.top_level_group.is(item) then
            if not needs_random_end then
               if awpa.top_level_group.is(item) then
                  needs_random_end = true
               else
                  needs_random_end = item.exclusive
               end
            end
            self:_push_conditions_from(item)
            for i = 1, #item.children do
               self:generate_child(item.children[i], true)
            end
            self:_pop_conditions_after(cond_count)
         elseif awpa.shared_info_reference.is(item) then
            item:generate_infos(topic)
            local size = #item.forms
            for i = 1, size do
               local info = item.forms[i]
               for j = 1, cond_count do
                  self.conditions[j]:apply_to_info(info)
               end
               topic_helper:append_desired_info(info)
            end
         end
         if speaker or needs_random_end then
            local infos            = topic_helper.infos.desired_order
            local info_count_after = #infos
            if info_count_prior < info_count_after then
               if speaker then
                  for i = info_count_prior + 1, info_count_after do
                     infos[i].speaker = speaker
                  end
               end
               if needs_random_end then
                  local line = topic_helper.infos.desired_order[info_count_after]
                  line.is_random_end = true
               end
            end
         end
      end
   end
end