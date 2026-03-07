
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
         for i = 1, #self.children do
            local item = self.children[i]
            if awpa.group.is(item) then
               item:generate_infos(topic, self.topic_helper)
            elseif awpa.line.is(item) then
               local a, b = item:generate_infos(topic)
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
   
      function instance_members:generate_content()
         for _, v in ipairs(BRIBE_TOPIC_NAMES) do
            local data = self.contents[v]
            if #data.children == 0 then
               error("This bribe override doesn't define all of the needed content.")
            end
         end
         
         local quest = self.quest_info.form
      
         --
         -- Get or create our branch.
         --
         if not self.forms.branch then
            local editor_id = string.format(
               "%sBranch%sBribe",
               self.quest_info.form.editor_id,
               self.actor_info.form.editor_id
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
         self.contents["begin"].topic.text  = "<Bribe Root>"
         self.contents["accept"].topic.text = "I'll pay. (<BribeCost> gold)"
         self.contents["refuse"].topic.text = "Never mind."
         self.contents["poor"].topic.text   = "I don't have enough gold."
         
         do
            local info = utils.make_invisible_info(
               self.quest_info.ask_root_topic:get_or_create_topic(),
               string.format(
                  "%sLinkInfo%sBribeStart",
                  self.quest_info.form.editor_id,
                  self.actor_info.form.editor_id
               ),
               self.contents["begin"].topic
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
               info.speaker = self.actor_info.form
               utils.replace_info_link_to_list(info, {
                  self.forms.accept_topic,
                  self.forms.poor_topic,
                  self.forms.refuse_topic
               })
               info.walk_away_topic = self.forms.refuse_topic
            end
         )
         
         -- PLAYER: "I can pay. (Bribe)"
         local result_topic = self.quest_info:get_or_create_result_topic()
         self.contents["accept"]:generate_infos(
            function(info)
               info.speaker = self.actor_info.form
               do -- Subject.GetBribeSuccess == 1
                  local cnd = info.conditions:insert()
                  cnd.run_on        = "subject"
                  cnd.function_name = "GetBribeSuccess"
                  cnd.comparison.operator = "=="
                  cnd.comparison.operand  = 1
               end
               do -- papyrus
                  local papyrus = info.papyrus
                  do
                     local script = papyrus.scripts["AskWherePeopleAreFRAGMENTBribe"]
                     if not script then
                        script = papyrus.scripts:insert("AskWherePeopleAreFRAGMENTBribe")
                     end
                     do
                        local prop = script.properties["pFDS"]
                        if not prop then
                           prop = script.properties:insert("pFDS")
                        end
                        prop.value = dovah.get_form_by_editor_id("DialogueFavorGeneric", form_types.quest)
                     end
                  end
                  local frag = papyrus.fragments.on_begin
                  frag.script_name   = "AskWherePeopleAreFRAGMENTBribe"
                  frag.function_name = "Exec"
               end
               utils.replace_info_link_to_list(info, { result_topic })
            end
         )
         
         -- PLAYER: "I don't have enough gold."
         self.contents["poor"]:generate_infos(
            function(info)
               info.speaker = self.actor_info.form
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
            function(info)
               info.speaker = self.actor_info.form
            end
         )
      end
   end
end