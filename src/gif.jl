
function gif()

    ```
    agg --font-size 28 input.cast output.gif
    ```
end


"""
Function walk! will walk! `Pandoc` document abstract source tree (AST) and apply filter function on each element of the document AST.
Returns a modified tree.

  action must be a function which takes four arguments, `tag, content, format, meta`,
  and should return

  * `nothing` to leave the element unchanged
  * `[]` to delete the element
  * A Pandoc element to replace the element
  * or a list of Pandoc elements which will be spliced into the list the original object belongs to.
"""

function walk(x :: Any, action :: Function)
    return x
end

function walk(x :: Array, action :: Function)
  array = []
    for item in x
      if (typeof(item)<:Dict) && haskey(item,"t")
        res = action(item["t"], get(item, "c", nothing))
        if res === nothing
          append!(array, [walk(item, action)])
        elseif typeof(res)<:Array
          append!(array, walk(res, action))
        else
          append!(array, [walk(res, action)])
        end
      else
        append!(array, [walk(item, action)])
      end #if
    end #for
  return array
end

function walk(dict :: Dict, action :: Function)
    [key=>walk(value,action) for (key,value) in dict]
end

function show_action(args...)
    # @show args
    return nothing
end

function xyz()
    doc = JSON3.read(stdin, Dict)
    format = (length(ARGS) <= 0) ? "" : ARGS[1]
    if "meta" in keys(doc)
        meta = doc["meta"]
    elseif doc isa AbstractArray  # old API
        meta = doc[1]["test"]
    else
        meta = Dict()
    end
    for action in [show_action]
        doc = walk(doc, (t,c)->action(t,c,format,meta))
    end
    JSON3.write(stdout, doc)
end
