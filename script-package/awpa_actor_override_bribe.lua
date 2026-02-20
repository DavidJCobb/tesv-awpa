
do
   local instance_members = {}
   awpa.actor_override_bribe = make_class({
      constructor = function()
         self.conditions = {}
         self.content = {
            begin  = {}, -- awpa.group or awpa.line instances
            accept = {}, -- awpa.group or awpa.line instances
            refuse = {}, -- awpa.group or awpa.line instances
            poor   = {}, -- awpa.group or awpa.line instances
         }
      end,
   })
end