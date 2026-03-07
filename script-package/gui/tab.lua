
if not gui then
   gui = {}
end

do
   local instance_members = {}
   gui.tab = make_class({
      constructor = function(self, body)
         self.body     = body
         self.edit_src = ui.textarea.new()
         self.edit_out = ui.textarea.new()
         self.edit_out.read_only = true
         self.save     = ui.file_save_button.new()
         
         body:set_layout("down")
         do
            local widget = ui.text.new()
            widget.text = "Input XML:"
            widget.font.bold = true
            body:add_child(widget)
         end
         body:add_child(self.edit_src)
         body:add_child(ui.line.new("h"))
         do
            local widget = ui.text.new()
            widget.text = "Output XML:"
            widget.font.bold = true
            body:add_child(widget)
         end
         body:add_child(self.edit_out)
         body:add_child(self.save)
         
         self.edit_src.placeholder = "Paste your XML payload into here."
         self.edit_out.placeholder = "After processing, your XML output will be placed here: a copy of your input, annotated with generated form IDs. Using this modified payload in the future will allow the script to reuse form IDs, instead of deleting and recreating TopicInfos."
         
         self.save.label   = "Output XML"
         self.save.enabled = false
      end,
      instance_members = instance_members
   })
   do -- member functions
      function instance_members:get_input_xml()
         return self.edit_src.text
      end
      function instance_members:set_output_xml(payload)
         self.edit_out.text = payload
         if payload and payload ~= "" then
            self.save.data    = payload
            self.save.enabled = true
         else
            self.save.enabled = false
         end
      end
      function instance_members:set_allow_editing(v)
         self.edit_src.enabled = v
      end
   end
end