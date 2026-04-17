
if not awpa then
   error("incorrect file order")
end

do
   local instance_members = {}
   awpa.random_line_subgroup = make_class({
      constructor = function(self)
         self.conditions = {}
         self.children   = {} -- vector<variant<shared_info_reference, line, random_line_subgroup>>
         self.name         = "" -- for debugging
      end,
      instance_members = instance_members
   })
   do -- member functions
      --[[--
         
         Returns a table:
         
            {
               male   = {}, -- vector<topic_info>
               female = {}, -- vector<topic_info>
               unisex = {}, -- vector<topic_info>
            }
         
      --]]--
      function instance_members:generate(topic, conditions)
         local results <const> = awpa.line_collection.new()
         
         do
            local j = #conditions + 1
            for i = 1, #self.conditions do
               conditions[j] = self.conditions[i]
               j = j + 1
            end
         end
         local cnd_count = #conditions
         
         for i = 1, #self.children do
            local item = self.children[i]
            if awpa.line.is(item) then
               results:generate_line(item, topic, conditions)
            elseif awpa.shared_info_reference.is(item) then
               results:generate_shared_info(item, topic, conditions)
            elseif awpa.random_line_subgroup.is(item) then
               local subresults = item:generate(topic, conditions)
               for j = #conditions, cnd_count + 1, -1 do
                  conditions[j] = nil
               end
               results:absorb(subresults)
            else
               error("unexpected object")
            end
         end
         
         return results
      end
   end
end