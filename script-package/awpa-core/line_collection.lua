
if not awpa then
   error("incorrect file order")
end

do
   local instance_members = {}
   awpa.line_collection = make_class({
      constructor = function(self)
         self.male   = {}
         self.female = {}
         self.unisex = {}
      end,
      instance_members = instance_members
   })
   do -- member functions
      function instance_members:for_each_line(functor)
         for _, v in ipairs({ "male", "female", "unisex" }) do
            local list = self[v]
            for i = 1, #list do
               functor(list[i])
            end
         end
      end
      function instance_members:generate_line(line, topic, conditions, conditions_are_pre_stripped, conditions_are_sexed)
         assert(awpa.line.is(line))
         -- `conditions` must be a list of native-compatible tables
         
         local m, f = line:generate_infos(topic)
         assert(not not m)
         if m and f then
            do
               local cnd_list_m = m.conditions
               local cnd_list_f = f.conditions
               for i = 1, #conditions do
                  local cnd = conditions[i]
                  cnd_list_m:insert(cnd)
                  cnd_list_f:insert(cnd)
               end
            end
            if conditions_are_pre_stripped then
               if conditions_are_sexed then
                  cndlib.strip_redundant_GetIsSex_conditions(m.conditions)
                  cndlib.strip_redundant_GetIsSex_conditions(f.conditions)
               end
            else
               cndlib.strip_redundant_conditions(m.conditions)
               cndlib.strip_redundant_conditions(f.conditions)
            end
            local j = #self.male + 1
            self.male[j]   = m
            self.female[j] = f
         else
            utils.append_native_compatible_conditions(m.conditions, conditions)
            if not conditions_are_pre_stripped then
               cndlib.strip_redundant_conditions(m.conditions)
            end
            self.unisex[#self.unisex + 1] = m
         end
      end
      function instance_members:generate_shared_info(si_ref, topic, conditions, conditions_are_pre_stripped, conditions_are_sexed)
         assert(awpa.shared_info_reference.is(si_ref))
         -- `conditions` must be a list of native-compatible tables
         
         si_ref:generate_infos(topic)
         local src_list    = si_ref.forms
         local src_genders = si_ref.genders
         for j = 1, #src_list do
            local info = src_list[j]
            local dst_list
            utils.append_native_compatible_conditions(info.conditions, conditions)
            if src_genders[j] ~= "unisex" then
               dst_list = self.male
               if src_genders[j] == "female" then
                  dst_list = self.female
               end
               
               if conditions_are_pre_stripped then
                  if conditions_are_sexed then
                     cndlib.strip_redundant_GetIsSex_conditions(info.conditions)
                  end
               else
                  cndlib.strip_redundant_conditions(info.conditions)
               end
            else
               dst_list = self.unisex
               if not conditions_are_pre_stripped then
                  cndlib.strip_redundant_conditions(info.conditions)
               end
            end
            dst_list[#dst_list + 1] = info
         end
      end
      function instance_members:absorb(other)
         assert(awpa.line_collection.is(other))
         for _, v in ipairs({ "male", "female", "unisex" }) do
            local src_list = other[v]
            local dst_list = self[v]
            local dst_j    = #dst_list + 1
            for src_j = 1, #src_list do
               dst_list[dst_j] = src_list[src_j]
               dst_j = dst_j + 1
            end
         end
      end
   end
end