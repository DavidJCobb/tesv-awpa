
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
         
         self.forms = {
            branch       = nil,
            begin_topic  = nil,
            accept_topic = nil,
            refuse_topic = nil,
            poor_topic   = nil,
         }
      end,
   })
   do -- member functions
      function instance_members:generate_content(quest_info, actor_info, results_topic)
         for _, v in ipairs({ "begin", "accept", "refuse", "poor" }) do
            if #self.content[v] == 0 then
               error("This bribe override doesn't define all of the needed content.")
            end
         end
      
         --
         -- Get or create our branch.
         --
         if not self.forms.branch then
            local editor_id = string.format(
               "%sBranch%sBribe",
               quest_info.form.editor_id,
               actor_info.form.editor_id
            )
            local branches = quest:get_all_dialogue_branches()
            for i = 1, #branches do
               local branch = branches[i]
               if branch.editor_id == editor_id then
                  self.forms.branch = branch
                  break
               end
            end
            if not self.forms.branch then
               local branch = dovah.create_form(form_types.dialogue_branch, { parent = quest })
               branch.editor_id = editor_id
               branch.type      = "normal"
               self.forms.branch = branch
            end
         end
         local branch = self.forms.branch
         
         --
         -- Get or create our topics.
         --
         do
            local editor_id_slugs = {
               "begin_topic"  = "BribeBegin",
               "accept_topic" = "BribeAccept",
               "refuse_topic" = "BribeRefuse",
               "poor_topic"   = "BribePoor",
            }
            local prior_topics
            for k, v in pairs(editor_id_slugs) do
               local topic = self.forms[k]
               if not topic then
                  local editor_id = string.format(
                     "%sTopic%s%s",
                     quest_info.form.editor_id,
                     actor_info.form.editor_id,
                     v
                  )
                  if not prior_topics then
                     prior_topics = branch:get_all_dialogue_topics()
                  end
                  for i = 1, #prior_topics do
                     local t = prior_topics[i]
                     if t.editor_id == editor_id then
                        topic = t
                        break
                     end
                  end
                  if not topic then
                     topic = dovah.create_form(form_types.topic, { parent = branch })
                     topic.editor_id = editor_id
                     self.forms[k] = topic
                  end
               end
            end
         end
         
         branch.starting_topic = self.forms.begin_topic
         
         --
         -- Set topic text.
         --
         self.forms.begin_topic.text  = "<Bribe>"
         self.forms.accept_topic.text = "I can pay. (Bribe)"
         self.forms.refuse_topic.text = "Never mind."
         self.forms.poor_topic.text   = "I don't have enough gold."
         -- Other params:
         self.forms.begin_topic.walk_away_topic = self.forms.refuse_topic
         
         -- TODO: Where do we enforce the initial bribe conditions?
         --       Do we want to generate an invisible info that leads to our begin topic?
         --       We'd need to insert that at the start of the quest's list of responses 
         --       to "Can you help me find someone?"
         --
         --       Right now, we don't have the means to prepend infos...
         
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
                  local info = infos[i]
                  postprocess(info)
               end
            end
         end
         
         -- ACTOR: "If you want info, it'll cost you."
         _generate_infos(
            self.content.begin,
            self.forms.begin_topic,
            function(info)
               utils.replace_info_link_to_list(info, {
                  self.forms.accept_topic,
                  self.forms.poor_topic,
                  self.forms.refuse_topic
               })
            end
         )
         
         -- PLAYER: "I can pay."
         _generate_infos(
            self.content.accept,
            self.forms.accept_topic,
            function(info)
               do -- Subject.GetBribeSuccess == 1
                  local cnd = infos.conditions:insert()
                  cnd.run_on        = "subject"
                  cnd.function_name = "GetBribeSuccess"
                  cnd.comparison.operator = "=="
                  cnd.comparison.operand  = 1
               end
               -- TODO: Set up script to pay the bribe
               utils.replace_info_link_to_list(info, { results_topic })
            end
         )
         
         -- PLAYER: "I don't have enough gold."
         _generate_infos(
            self.content.poor,
            self.forms.poor_topic,
            function(info)
               do -- Subject.GetBribeSuccess != 1
                  local cnd = infos.conditions:insert()
                  cnd.run_on        = "subject"
                  cnd.function_name = "GetBribeSuccess"
                  cnd.comparison.operator = "!="
                  cnd.comparison.operand  = 1
               end
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