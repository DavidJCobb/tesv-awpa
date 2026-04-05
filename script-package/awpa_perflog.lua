
awpa.perflog = {
   _builder = string_builder()
}

function awpa.perflog:log(bench, message, ...)
   bench:stop()
   message = string.format(message, ...)
   message = string.format("%s | %s\n", bench:time_to_string(), message)
   self._builder:append(message)
end

function awpa.perflog:clear()
   self._builder = string_builder()
end
function awpa.perflog:to_string()
   return self._builder:to_string()
end