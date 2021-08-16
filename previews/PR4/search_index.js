var documenterSearchIndex = {"docs":
[{"location":"#Asciicast.jl","page":"Home","title":"Asciicast.jl","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"","category":"page"},{"location":"#Simple-example","page":"Home","title":"Simple example","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"using Pkg\nPkg.status()\n1 + 1","category":"page"},{"location":"#Example-with-a-named-block","page":"Home","title":"Example with a named block","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"First block:","category":"page"},{"location":"","page":"Home","title":"Home","text":"x = -1\nx*x","category":"page"},{"location":"","page":"Home","title":"Home","text":"The next block continues:","category":"page"},{"location":"","page":"Home","title":"Home","text":"y = x+1\nsqrt(x)","category":"page"},{"location":"","page":"Home","title":"Home","text":"Then we move to a REPL block:","category":"page"},{"location":"","page":"Home","title":"Home","text":"@show y\nz = y^2","category":"page"},{"location":"#API-Reference","page":"Home","title":"API Reference","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Modules = [Asciicast]","category":"page"},{"location":"#Asciicast.Cast","page":"Home","title":"Asciicast.Cast","text":"Cast(file_or_io, header=Header(), start_time=time(); delay=0.0)\n\nCreate a Cast object which represents an asciicast file (see https://github.com/asciinema/asciinema/blob/asciicast-v2/doc/asciicast-v2.md for the format).\n\nSet delay to enforce a constant delay between events.\n\nUse write_event! to write an event to the cast.\n\n\n\n\n\n","category":"type"},{"location":"#Asciicast.write_event!-Tuple{Cast, Asciicast.EventType, AbstractString}","page":"Home","title":"Asciicast.write_event!","text":"write_event!(cast::Cast, event_type::EventType, event_data::AbstractString) -> time_since_start\n\nWrite an event to cast of type event_type (either OutputEvent or InputEvent) with data given by event_data.\n\n\n\n\n\n","category":"method"}]
}
