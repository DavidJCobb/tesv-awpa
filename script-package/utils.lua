
utils = {}

function utils.join(dst, src)
   local src_size = #src
   if src_size == 0 then
      return
   end
   local dst_i = #dst + 1
   for src_i = 1, src_size do
      dst[dst_i] = src[src_i]
      dst_i      = dst_i + 1
   end
end

--
-- XML-loading utils
--

function utils.fail_load_on_unexpected_element(node)
   if node.source_location then
      error(string.format("unexpected element `%s` at line %d col %d", node.node_name, node.source_location.line, node.source_location.col))
   end
   error(string.format("unexpected element `%s`", node.node_name))
end
function utils.fail_load(message, context_node)
   if not context_node then
      error(message)
   end
   local loc = context_node.source_location
   if loc then
      error(string.format("%s (see node at line %d col %d)", message, loc.line, loc.col))
   end
   error(message)
end

--

function utils.get_or_create_branch(quest, editor_id, prior_branches)
   if not prior_branches then
      prior_branches = quest:get_all_dialogue_branches()
   end
   for i = 1, #prior_branches do
      local branch = prior_branches[i]
      if branch.editor_id == editor_id then
         return branch, prior_branches
      end
   end
   local branch = dovah.create_form(form_types.dialogue_branch, { parent = quest })
   branch.editor_id = editor_id
   branch.type      = "normal"
   return branch, prior_branches
end

function utils.get_or_create_topic(branch, editor_id, prior_topics)
   if not prior_topics then
      prior_topics = branch:get_all_topics()
   end
   for i = 1, #prior_topics do
      local topic = prior_topics[i]
      if topic.editor_id == editor_id then
         return topic, prior_topics
      end
   end
   local topic = dovah.create_form(form_types.topic, { parent = branch })
   topic.editor_id = editor_id
   return topic, prior_topics
end

--

function utils.make_invisible_info(topic, editor_id, destination)
   local infos = topic.infos
   local info
   for i = 1, #infos do
      local item = infos[i]
      if item.editor_id == editor_id then
         info = item
         break
      end
   end
   if not info then
      info = dovah.create_form(form_types.topic_info, { parent = topic })
      info.editor_id = editor_id
   end
   
   info.use_shared_info = awpa.env.built_in_shared_infos["InvisibleInfo"][1]
   info.invisible_continue = true
   
   if type(destination) == "userdata" then
      destination = { destination }
   end
   utils.replace_info_link_to_list(info, destination)
   
   return info
end

local function _append_conditions_to(info, dst_list, src_list)
   if src_list.function_name then
      src_list = { src_list }
   end
   for i = 1, #src_list do
      local src = src_list[i]
      if awpa.condition.is(src) then
         if not src:is_no_op() then
            dst_list:insert(src:to_native_compatible_table())
         end
         goto continue
      end
      dst_list:insert(src)
      ::continue::
   end
end

function utils.replace_condition_list(info, conditions)
   local list = info.conditions
   list:clear()
   _append_conditions_to(info, list, conditions)
end
function utils.append_condition_list(info, src_list)
   _append_conditions_to(info, info.conditions, src_list)
end

function utils.replace_info_link_to_list(info, topics)
   local list = info.link_to
   list:clear()
   for i = 1, #topics do
      list:insert(topics[i])
   end
end

function utils.replace_info_responses(info, text)
   local list = info.responses
   list:clear()
   list:insert({ text = text })
end

function utils.resolve_form_reference(text, optional)
   local SIGS = {
      ACHR = form_types.actor,
      ACTI = form_types.activator,
      ALCH = form_types.potion,
      AMMO = form_types.ammo,
      ARMO = form_types.armor,
      BOOK = form_types.book,
      FURN = form_types.furniture,
      GLOB = form_types.global,
      KEYM = form_types.key,
      MISC = form_types.misc_item,
      MSTT = form_types.movable_static,
      NPC_ = form_types.actor_base,
      QUST = form_types.quest,
      REFR = form_types.reference,
      SCRL = form_types.scroll,
      SLGM = form_types.soul_gem,
      STAT = form_types.static,
      WEAP = form_types.weapon,
   }
   
   local sig, form_id, editor_id = text:match("^%[(....):(%x%x%x%x%x%x%x%x)%](.*)$")
   if not form_id then
      sig, editor_id = text:match("^%[(....)%](.*)$")
      if not sig then
         if optional then
            return
         end
         error("malformed form reference: " .. text)
      end
   end
   
   local ft = SIGS[sig]
   if not ft then
      error("bad form-reference signature: " .. sig)
   end
   
   local form
   if form_id then
      form_id = tonumber(form_id, 16)
      form    = dovah.get_form_by_id(form_id)
   else
      form = dovah.get_form_by_editor_id(editor_id, ft)
   end
   
   if not form then
      error(string.format(
         "form not found: %s",
         text
      ))
   end
   if form_id then
      if form.form_type ~= ft then
         error(string.format(
            "form is of the wrong type: %X (expected %s)",
            form_id,
            sig
         ))
      end
      if editor_id and form.editor_id ~= editor_id then
         error(string.format(
            "form has the wrong editor ID: %X (expected '%s'; saw '%s')",
            form_id,
            editor_id,
            form.editor_id
         ))
      end
   end
   return form
end

function utils.set_papyrus_script_data(form, script_spec, fragment_spec)
   local papyrus = form.papyrus
   for scriptname, src_script in pairs(script_spec) do
      local dst_script = papyrus.scripts[scriptname]
      if not dst_script then
         dst_script = papyrus.scripts:insert(scriptname)
      end
      local dst_properties = dst_script.properties
      for propname, propval in pairs(src_script) do
         local dst_prop = dst_properties[propname]
         if not dst_prop then
            dst_prop = dst_properties:insert(propname)
         end
         dst_prop.value = propval
      end
   end
   if fragment_spec then
      local dst_fragments = papyrus.fragments
      for k, v in pairs(fragment_spec) do
         if k == "script_name" then
            dst_fragments[k] = v
         else
            local frag = dst_fragments[k]
            for l, w in pairs(v) do
               frag[l] = w
            end
         end
      end
   end
end

