
local BRIBE_TOPIC_NAMES = { "begin", "accept", "refuse", "poor" }

local bribe_topic
do
   local instance_members = {}
   bribe_topic = make_class({
      constructor = function(self, override, name)
         self.source_xml_node = nil
         
         self.owner = override -- awpa.actor_redirect_bribe
         self.name  = name
         
         self.topic        = nil -- topic
         self.topic_helper = nil -- awpa.topic_helper
         
         self.children = {} -- vector<variant<awpa.line, awpa.group, awpa.shared_info_reference>>
      end,
      instance_members = instance_members
   })
   do -- member functions
      function instance_members:from_xml(node)
         self.source_xml_node = node
      
         local list = self.children
         node:for_each_child_element(function(node)
            if node.node_name == "line" then
               local item = awpa.line()
               list[#list + 1] = item
               item:from_xml(node)
            elseif node.node_name == "g" then
               local item = awpa.group(self.owner.quest_info)
               list[#list + 1] = item
               item.parent = self.owner
               item:from_xml(node)
            else
               error("unexpected element: " .. node.node_name)
            end
         end)
      end
      function instance_members:amend_xml_clone(nodemap)
         for i = 1, #self.children do
            self.children[i]:amend_xml_clone(nodemap)
         end
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
         
         local rlg_list = awpa.random_line_group.fold(self)
         for i = 1, #rlg_list do
            rlg_list[i].postprocess = postprocess
            rlg_list[i]:generate(self.topic_helper)
         end
      end
   end
end

do
   local instance_members = {}
   awpa.actor_redirect_bribe = make_class({
      superclass  = awpa.actor_redirect,
      constructor = function(self, actor_info)
         self.contents = {}
         for _, v in ipairs(BRIBE_TOPIC_NAMES) do
            self.contents[v] = bribe_topic(self, v)
         end
         
         self.forms.branch = nil
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
               awpa.condition.construct_list_from_xml(node, self.conditions, {
                  scope      = self.quest_info,
                  quest_info = self.quest_info,
               })
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
      function instance_members:amend_xml_clone(nodemap)
         for _, v in ipairs(BRIBE_TOPIC_NAMES) do
            self.contents[v]:amend_xml_clone(nodemap)
         end
      end
      
      function instance_members:get_or_create_branch()
         if not self.forms.branch then
            local editor_id = string.format(
               "%sBranch%sBribe",
               self.quest_info.form.editor_id,
               self.actor_info.form.editor_id
            )
            self.forms.branch = utils.get_or_create_branch(self.quest_info:get_or_create_form(), editor_id)
         end
         return self.forms.branch
      end
      function instance_members:get_or_create_link(src_topic)
         if self.forms.inbound_link then
            return self.forms.inbound_link
         end
         local dst_topic = self.contents["begin"]:get_or_create_topic(self:get_or_create_branch())
         
         local info = utils.make_invisible_info(
            src_topic,
            string.format(
               "%sLinkInfo%sBribeStart",
               self.quest_info.form.editor_id,
               self.actor_info.form.editor_id
            ),
            dst_topic
         )
         self.forms.inbound_link = info
         
         utils.replace_condition_list(info, {
            run_on        = "subject",
            function_name = "GetIsId",
            parameters    = { self.actor_info.form },
            comparison    = {
               operator = "==",
               operand  = 1,
            }
         })
         utils.append_condition_list(info, self.conditions)
         
         return info
      end
      
      function instance_members:_generate_inner_content()
         local branch = self:get_or_create_branch()
         
         --
         -- Get or create our topics.
         --
         for _, v in ipairs(BRIBE_TOPIC_NAMES) do
            if v ~= "begin" then
               local data = self.contents[v]
               data:get_or_create_topic(branch)
            end
         end
         branch.starting_topic = self.contents["accept"].topic
         branch.type = "normal"
         
         --
         -- Set topic text.
         --
         self.contents["accept"].topic.text = "I'll pay. (<BribeCost> gold)"
         self.contents["refuse"].topic.text = "Never mind."
         self.contents["poor"].topic.text   = "I don't have enough gold."
         
         -- PLAYER: "I can pay. (Bribe)"
         local result_topic = self.quest_info:get_or_create_result_topic()
         self.contents["accept"]:generate_infos(
            function(info)
               info.speaker = self.actor_info.form
               do -- Subject.GetBribeSuccess == 1
                  local cnd = info.conditions:insert(1, {
                     run_on        = "subject",
                     function_name = "GetBribeSuccess",
                     comparison    = {
                        operator = "==",
                        operand  = 1
                     }
                  })
               end
               utils.set_papyrus_script_data(
                  info,
                  {
                     ["AskWherePeopleAreFRAGMENTBribe"] = {
                        ["pFDS"] = dovah.get_form_by_editor_id("DialogueFavorGeneric", form_types.quest)
                     }
                  },
                  {
                     script_name = "AskWherePeopleAreFRAGMENTBribe",
                     on_begin    = {
                        script_name   = "AskWherePeopleAreFRAGMENTBribe",
                        function_name = "Exec"
                     }
                  }
               )
               utils.replace_info_link_to_list(info, self.quest_info.selection_topic_list.topics)
            end
         )
         
         -- PLAYER: "I don't have enough gold."
         self.contents["poor"]:generate_infos(
            function(info)
               info.speaker = self.actor_info.form
               do -- Subject.GetBribeSuccess != 1
                  local cnd = info.conditions:insert(1, {
                     run_on        = "subject",
                     function_name = "GetBribeSuccess",
                     comparison    = {
                        operator = "!=",
                        operand  = 1
                     }
                  })
               end
            end
         )
         
         -- PLAYER: "Never mind. I don't want to pay you."
         self.contents["refuse"]:generate_infos(
            function(info)
               info.speaker = self.actor_info.form
            end
         )
      end
      function instance_members:fold()
         for _, v in ipairs(BRIBE_TOPIC_NAMES) do
            local data = self.contents[v]
            if #data.children == 0 then
               error("This bribe override doesn't define all of the needed content.")
            end
         end
         
         self:_generate_inner_content()
         
         local actor_condition <const> = {
            run_on        = "subject",
            function_name = "GetIsId",
            parameters    = { self.actor_info.form },
            comparison    = {
               operator = "==",
               operand  = 1,
            }
         }
         local function postprocess(info)
            info.speaker = self.actor_info.form
            utils.replace_info_link_to_list(info, {
               self.forms.accept_topic,
               self.forms.poor_topic,
               self.forms.refuse_topic
            })
            info.walk_away_topic = self.forms.refuse_topic
         end
         
         local rlg_list = awpa.random_line_group.fold(self.contents["begin"])
         for i = 1, #rlg_list do
            local dst_item = rlg_list[i]
            do -- conditions
               local cnd_list = { actor_condition }
               utils.join(cnd_list, self.conditions)
               utils.join(cnd_list, dst_item.conditions)
               dst_item.conditions = cnd_list
            end
            dst_item.postprocess = postprocess
         end
         return rlg_list
      end
   end
end