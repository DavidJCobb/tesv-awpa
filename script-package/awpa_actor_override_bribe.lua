
local BRIBE_TOPIC_NAMES = { "begin", "accept", "refuse", "poor" }

local bribe_topic
do
   local instance_members = {}
   bribe_topic = make_class({
      constructor = function(self, override, name)
         self.owner = override -- awpa.actor_override_bribe
         self.name  = name
         
         self.topic        = nil -- topic
         self.topic_helper = nil -- awpa.topic_helper
         
         self.children = {} -- vector<variant<awpa.line, awpa.group>>
      end,
      instance_members = instance_members
   })
   do -- member functions
      function instance_members:from_xml(node)
         local list = self.children
         node:for_each_child_element(function(node)
            if node.node_name == "line" then
               local item = awpa.line()
               list[#list + 1] = item
               item:from_xml(node)
            elseif node.node_name == "g" then
               local item = awpa.group()
               list[#list + 1] = item
               item.parent = self.owner.quest_info
               item:from_xml(node)
            else
               error("unexpected element: " .. node.node_name)
            end
         end)
      end
      function instance_members:get_or_create_topic(branch, branch_topics)
         if self.topic then
            return self.topic
         end
         local editor_id
         do
            local slug = ({
               begin  = "BribeBegin",
               accept = "BribeAccept",
               refuse = "BribeRefuse",
               poor   = "BribePoor",
            })[self.name]
            editor_id = string.format(
               "%sTopic%s%s",
               self.owner.quest_info.form.editor_id,
               self.owner.actor_info.form.editor_id,
               slug
            )
            self.topic = utils.get_or_create_topic(branch, editor_id, branch_topics)
         end
         self.topic_helper = awpa.topic_helper(self.topic)
         return self.topic
      end
      function instance_members:generate_infos(postprocess)
         local topic = self:get_or_create_topic(self.owner.forms.branch)
         for i = 1, #self.children do
            local item = self.children[i]
            if awpa.group.is(item) then
               item:generate_lines(topic, self.topic_helper)
            elseif awpa.line.is(item) then
               local a, b = item:generate_info(topic)
               self.topic_helper:append_desired_info(a)
               if b then
                  self.topic_helper:append_desired_info(b)
               end
            else
               error("unrecognized object type")
            end
         end
         if postprocess then
            local infos = self.topic_helper.infos.desired_order
            for i = 1, #infos do
               postprocess(infos[i])
            end
         end
      end
   end
end

do
   local instance_members = {}
   awpa.actor_override_bribe = make_class({
      constructor = function(self, quest_info, actor_info)
         self.conditions = {}
         self.quest_info = quest_info
         self.actor_info = actor_info
         
         self.contents = {}
         for _, v in ipairs(BRIBE_TOPIC_NAMES) do
            self.contents[v] = bribe_topic(self, v)
         end
         
         self.forms = {
            link_to_branch = nil, -- invisible-info
            branch         = nil,
         }
      end,
      instance_members = instance_members,
   })
   do -- member functions
      function instance_members:visit_topic_helpers(visitor)
         for _, v in ipairs(BRIBE_TOPIC_NAMES) do
            local data = self.contents[v]
            if data.topic_helper then
               visitor(data.topic_helper)
            end
         end
      end
      
      function instance_members:from_xml(element)
         if element.node_name ~= "bribe" then
            error("invalid node")
         end
         element:for_each_child_element(function(node)
            if node.node_name == "conditions" then
               awpa.condition.construct_list_from_xml(self, self.quest_info, node)
               return
            end
            
            for _, v in ipairs(BRIBE_TOPIC_NAMES) do
               if node.node_name == v .. "-lines" then
                  self.contents[v]:from_xml(node)
                  return
               end
            end
            error("unexpected element: " .. node.node_name)
         end)
      end
   
      function instance_members:generate_content(quest_info, actor_info, ask_begin_topic, results_topic)
         for _, v in ipairs(BRIBE_TOPIC_NAMES) do
            local data = self.contents[v]
            if #data.children == 0 then
               error("This bribe override doesn't define all of the needed content.")
            end
         end
         
         local quest = quest_info.form
      
         --
         -- Get or create our branch.
         --
         if not self.forms.branch then
            local editor_id = string.format(
               "%sBranch%sBribe",
               quest_info.form.editor_id,
               actor_info.form.editor_id
            )
            self.forms.branch = utils.get_or_create_branch(quest, editor_id)
         end
         local branch = self.forms.branch
         
         --
         -- Get or create our topics.
         --
         for _, v in ipairs(BRIBE_TOPIC_NAMES) do
            local data = self.contents[v]
            data:get_or_create_topic(branch)
         end
         branch.starting_topic = self.contents["begin"].topic
         branch.type = "normal"
         
         --
         -- Set topic text.
         --
         self.contents["begin"].text  = "<Bribe Root>"
         self.contents["accept"].text = "I can pay. (Bribe)"
         self.contents["refuse"].text = "Never mind."
         self.contents["poor"].text   = "I don't have enough gold."
         
         do
            local info = utils.make_invisible_info(
               ask_begin_topic,
               string.format(
                  "%sLinkInfo%sBribeStart",
                  quest_info.form.editor_id,
                  actor_info.form.editor_id
               ),
               self.contents["begin"].topic
            )
            self.forms.link_to_branch = info
            
            utils.replace_condition_list(info, {
               run_on        = "subject",
               function_name = "GetIsId",
               parameters    = { actor_info.form },
               comparison    = {
                  operator = "==",
                  operand  = 1,
               }
            })
            utils.append_condition_list(info, self.conditions)
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
                  local info = infos[i]
                  postprocess(info)
               end
            end
         end
         
         -- ACTOR: "If you want info, it'll cost you."
         self.contents["begin"]:generate_infos(
            function(info)
               utils.replace_info_link_to_list(info, {
                  self.forms.accept_topic,
                  self.forms.poor_topic,
                  self.forms.refuse_topic
               })
               info.walk_away_topic = self.forms.refuse_topic
            end
         )
         
         -- PLAYER: "I can pay."
         self.contents["accept"]:generate_infos(
            function(info)
               do -- Subject.GetBribeSuccess == 1
                  local cnd = info.conditions:insert()
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
         self.contents["poor"]:generate_infos(
            function(info)
               do -- Subject.GetBribeSuccess != 1
                  local cnd = info.conditions:insert()
                  cnd.run_on        = "subject"
                  cnd.function_name = "GetBribeSuccess"
                  cnd.comparison.operator = "!="
                  cnd.comparison.operand  = 1
               end
            end
         )
         
         -- PLAYER: "Never mind. I don't want to pay you."
         self.contents["refuse"]:generate_infos(
            nil -- can't think of any post-processing we need rn
         )
      end
   end
end