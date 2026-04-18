
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
         for _, v in { "male", "female", "unisex" } do
            local list = self[v]
            for i = 1, #list do
               functor(list[i])
            end
         end
      end
      function instance_members:generate_line(line, topic, conditions)
         assert(awpa.line.is(line))
         local m, f = line:generate_infos(topic)
         assert(not not m)
         utils.append_condition_list(m, conditions)
         cndlib.strip_redundant_conditions(m.conditions)
         if m and f then
            utils.append_condition_list(f, conditions)
            cndlib.strip_redundant_conditions(f.conditions)
            
            local j = #self.male + 1
            self.male[j]   = m
            self.female[j] = f
         else
            self.unisex[#self.unisex + 1] = m
         end
      end
      function instance_members:generate_shared_info(si_ref, topic, conditions)
         assert(awpa.shared_info_reference.is(si_ref))
         si_ref:generate_infos(topic)
         local src_list = si_ref.forms
         for j = 1, #src_list do
            local info = src_list[j]
            local dst_list
            if #info.conditions > 0 then
               dst_list = self.male
               if info.conditions[1].parameters[1] == "Female" then
                  dst_list = self.female
               end
            else
               dst_list = self.unisex
            end
            dst_list[#dst_list + 1] = info
            utils.append_condition_list(info, conditions)
            cndlib.strip_redundant_conditions(info.conditions)
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