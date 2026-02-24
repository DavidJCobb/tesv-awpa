
do
   local instance_members = {}
   awpa.actor_override_bribe = make_class({
      constructor = function(self)
         self.conditions = {}
         self.content = {
            begin  = {}, -- awpa.group or awpa.line instances
            accept = {}, -- awpa.group or awpa.line instances
            refuse = {}, -- awpa.group or awpa.line instances
            poor   = {}, -- awpa.group or awpa.line instances
         }
         
         self.forms = {
            link_to_branch = nil,
            branch         = nil,
            begin_topic    = nil,
            accept_topic   = nil,
            refuse_topic   = nil,
            poor_topic     = nil,
         }
      end,
      instance_members = instance_members,
   })
   do -- member functions
      function instance_members:generate_content(quest_info, actor_info, ask_begin_topic, results_topic)
         for _, v in ipairs({ "begin", "accept", "refuse", "poor" }) do
            if #self.content[v] == 0 then
               error("This bribe override doesn't define all of the needed content.")
            end
         end
         
         local quest = quest_info.form
      
         --
         -- Get or create our branch.
         --
         if not self.forms.branch then
            self.forms.branch = quest:get_or_create_branch(string.format(
               "%sBranch%sBribe",
               quest_info.form.editor_id,
               actor_info.form.editor_id
            ))
         end
         local branch = self.forms.branch
         
         --
         -- Get or create our topics.
         --
         do
            local editor_id_slugs = {
               ["begin_topic"]  = "BribeBegin",
               ["accept_topic"] = "BribeAccept",
               ["refuse_topic"] = "BribeRefuse",
               ["poor_topic"]   = "BribePoor",
            }
            local prior_topics
            for k, v in pairs(editor_id_slugs) do
               local topic = self.forms[k]
               if not topic then
                  self.forms[k] = branch:get_or_create_topic(string.format(
                     "%sTopic%s%s",
                     quest_info.form.editor_id,
                     actor_info.form.editor_id,
                     v
                  ))
               end
            end
         end
         
         branch.starting_topic = self.forms.begin_topic
         
         --
         -- Set topic text.
         --
         self.forms.begin_topic.text  = "<Bribe Root>"
         self.forms.accept_topic.text = "I can pay. (Bribe)"
         self.forms.refuse_topic.text = "Never mind."
         self.forms.poor_topic.text   = "I don't have enough gold."
         
         do
            local info = ask_begin_topic:make_invisible_info(
               string.format(
                  "%sLinkInfo%sBribeStart",
                  quest_info.form.editor_id,
                  actor_info.form.editor_id
               ),
               self.forms.begin_topic
            )
            self.forms.link_to_branch = info
            
            info:replace_conditions({
               run_on        = "subject",
               function_name = "GetIsId",
               parameters    = { actor_info.form },
               comparison    = { operator = "==", operand = 1 }
            })
            info:append_conditions(self.conditions)
         end
         
         local function _generate_infos(source, topic, postprocess)
            for i = 1, #source do
               local item = source[i]
               if awpa.group.is(item) then
                  item:generate_lines(topic)
               elseif awpa.line.is(item) then
                  item:generate_info(topic)
               else
                  error("unrecognized object type")
               end
            end
            if postprocess then
               local infos = topic.infos
               for i = 1, #infos do
                  postprocess(infos[i])
               end
            end
         end
         
         -- ACTOR: "If you want info, it'll cost you."
         _generate_infos(
            self.content.begin,
            self.forms.begin_topic,
            function(info)
               info.link_to = {
                  self.forms.accept_topic,
                  self.forms.poor_topic,
                  self.forms.refuse_topic
               }
               info.walk_away_topic = self.forms.refuse_topic
            end
         )
         
         -- PLAYER: "I can pay."
         _generate_infos(
            self.content.accept,
            self.forms.accept_topic,
            function(info)
               info:append_condition({ -- Subject.GetBribeSuccess == 1
                  run_on        = "subject",
                  function_name = "GetBribeSuccess",
                  comparison    = { operator = "==", operand = 1 }
               })
               -- TODO: Set up script to pay the bribe
               info.link_to = { results_topic }
            end
         )
         
         -- PLAYER: "I don't have enough gold."
         _generate_infos(
            self.content.poor,
            self.forms.poor_topic,
            function(info)
               info:append_condition({ -- Subject.GetBribeSuccess != 1
                  run_on        = "subject",
                  function_name = "GetBribeSuccess",
                  comparison    = { operator = "!=", operand = 1 }
               })
            end
         )
         
         -- PLAYER: "Never mind. I don't want to pay you."
         _generate_infos(
            self.content.refuse,
            self.forms.refuse_topic,
            nil -- can't think of any post-processing we need rn
         )
      end
   end
end