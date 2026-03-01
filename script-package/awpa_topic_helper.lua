
if not awpa then
   error("incorrect file order")
end

do
   local instance_members = {}
   awpa.topic_helper = make_clas({
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
      function instance_members:prepend_desired_info(info)
         if self.infos.desired_set[info] then
            error("info is already desired")
         end
         table.insert(self.infos.desired_order, 1, info)
         self.infos.desired_set[info] = true
      end
      
      function instance_members:generate_line(line)
         local a, b = line:generate_infos(self.form)
         self:append_desired_info(a)
         if b then
            self:append_desired_info(b)
         end
      end
      
      function instance_members:finalize_infos()
         local infos         = self.form.infos
         local count_of_all  = #infos
         local count_to_keep = #self.infos.desired_order
         for i = 1, count_to_keep do
            local info = self.infos.desired_order[i]
            local prev
            if i > 1 then
               prev = self.infos.desired_order[i - 1]
            end
            self.form:place_info_after(info, prev)
         end
         if count == #self.infos.desired_order then
            return
         end
         for i = count_to_keep + 1, count_of_all do
            if self.infos.desired_set[infos[i]] then
               error("failed to enforce info order; a desired info is near the end")
            end
            infos[i]:delete()
         end
      end
   end
end