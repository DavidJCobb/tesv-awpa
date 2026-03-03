
--[[--

   An "actor redirect" is any collection of content wherein an actor's 
   normal response to part of the AWPA flow is preempted, i.e. an 
   invisible TopicInfo is used to redirect you to some other Topic 
   whose contents are defined by the actor redirect.

--]]--
do
   local instance_members = {}
   awpa.actor_redirect = make_class({
      constructor = function(self, actor_info)
         self.conditions = {}
         self.actor_info = actor_info
         self.quest_info = actor_info.quest_info
         
         self.forms = {
            inbound_link = nil, -- invisible info
         }
      end,
      instance_members = instance_members,
   })
   do -- member functions
      function instance_members:visit_topic_helpers(visitor)
         error("purecall")
      end
      
      function instance_members:from_xml(element)
         error("purecall")
      end
      function instance_members:amend_xml_clone(nodemap)
         error("purecall")
      end
      
      function instance_members:generate_content(redirect_from_topic)
         error("purecall")
      end
   end
end