var documenterSearchIndex = {"docs":
[{"location":"#Asciicast.jl","page":"Home","title":"Asciicast.jl","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"","category":"page"},{"location":"#Simple-example","page":"Home","title":"Simple example","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"","category":"page"},{"location":"#Macro-example","page":"Home","title":"Macro example","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"using Asciicast\ncast\"\"\"\nx = 1\nx+1\ny = x-1\n\"\"\"0.5","category":"page"},{"location":"#Example-with-a-named-block","page":"Home","title":"Example with a named block","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"First block:","category":"page"},{"location":"","page":"Home","title":"Home","text":"","category":"page"},{"location":"","page":"Home","title":"Home","text":"The next block continues:","category":"page"},{"location":"","page":"Home","title":"Home","text":"","category":"page"},{"location":"","page":"Home","title":"Home","text":"Then we move to a REPL block:","category":"page"},{"location":"","page":"Home","title":"Home","text":"@show y\nz = y^2","category":"page"},{"location":"#Modifying-the-delay","page":"Home","title":"Modifying the delay","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Delay of 0:","category":"page"},{"location":"","page":"Home","title":"Home","text":"","category":"page"},{"location":"","page":"Home","title":"Home","text":"Delay of 1:","category":"page"},{"location":"","page":"Home","title":"Home","text":"","category":"page"},{"location":"#API-Reference","page":"Home","title":"API Reference","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Modules = [Asciicast]","category":"page"},{"location":"#Asciicast.Cast","page":"Home","title":"Asciicast.Cast","text":"Cast(file_or_io=IOBuffer(), header=Header(), start_time=time(); delay=0.0)\n\nCreate a Cast object which represents an asciicast file (see https://github.com/asciinema/asciinema/blob/asciicast-v2/doc/asciicast-v2.md for the format).\n\nSet delay to enforce a constant delay between events.\n\nUse write_event! to write an event to the cast.\n\n\n\n\n\n","category":"type"},{"location":"#Asciicast.record_output-Tuple{Any, AbstractString, Vararg{Any}}","page":"Home","title":"Asciicast.record_output","text":"record_output(f, filepath::AbstractString, h::Header=Header(), start_time::Float64=time(); delay=0) -> filepath\nrecord_output(f, io::IO,  h::Header=Header(), start_time::Float64=time(); delay=0)\n\nExecutes f() while saving all output to a cast whose data is saved to io, or to a file at filepath.\n\nThe parameters of the cast may be passed here; see Cast for more details.\n\nReturns a Cast object.\n\n\n\n\n\n","category":"method"},{"location":"#Asciicast.save-Tuple{Any, Cast}","page":"Home","title":"Asciicast.save","text":"save(output, cast::Cast)\n\nWrites the contents of a Cast cast to output.\n\n\n\n\n\n","category":"method"},{"location":"#Asciicast.write_event!-Tuple{Cast, Asciicast.EventType, AbstractString}","page":"Home","title":"Asciicast.write_event!","text":"write_event!(cast::Cast, event_type::EventType, event_data::AbstractString) -> time_since_start\n\nWrite an event to cast of type event_type (either OutputEvent or InputEvent) with data given by event_data.\n\n\n\n\n\n","category":"method"},{"location":"#Asciicast.@cast_str","page":"Home","title":"Asciicast.@cast_str","text":"@cast_str(code_string, delay=0) -> Cast\n\nCreates a Cast object by executing the code in code_string in a REPL-like environment.\n\nExample\n\nusing Asciicast\n\nc = cast\"x=1\"0.25 # note we set a delay of 0.25 here\n\nAsciicast.save(\"test.cast\", c)\n\n\n\n\n\n","category":"macro"}]
}
