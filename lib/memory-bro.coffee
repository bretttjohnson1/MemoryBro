MemoryBroView = require './memory-bro-view'
{CompositeDisposable} = require 'atom'

module.exports = MemoryBro =
   memoryBroView: null
   modalPanel: null
   subscriptions: null

   activate: (state) ->
      @memoryBroView = new MemoryBroView(state.memoryBroViewState)
      @modalPanel = atom.workspace.addModalPanel(item: @memoryBroView.getElement(), visible: false)

      # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
      @subscriptions = new CompositeDisposable

      # Register command that toggles this view
      @subscriptions.add atom.commands.add 'atom-workspace', 'memory-bro:toggle': => @toggle()

   deactivate: ->
      @modalPanel.destroy()
      @subscriptions.dispose()
      @memoryBroView.destroy()

   serialize: ->
      memoryBroViewState: @memoryBroView.serialize()


   getNumLoopIterations: (line_array, text_array) ->
      num_iter = 0
      # Iterate through each line to obtain the num_iter and start_iter values
      for item, i in line_array
         if line_array[i] == "="
            start_iter_loc = i + 1
            start_iter = parseInt(line_array[start_iter_loc], 10)

         if line_array[i] == "<"
            iter_loc = i + 1
            # number of iterations is stored in a variable
            if /[a-z]/.test(line_array[iter_loc])
               variable = line_array[iter_loc].replace(';', '')
               re = new RegExp("int " + variable + " = ", "g")

               for line in text_array
                  if re.test(line)
                     l_array = line.split(" ")
                     for w, j in l_array
                        if l_array[j] == "="
                           var_loc = j + 1
                           num_iter = parseInt(l_array[var_loc], 10)

            # number of iterations is explicity declared
            else
               num_iter = parseInt(line_array[iter_loc], 10)

      return num_iter

   getLoopBoundries: (start_index, text_array) ->
      loop_info = []
      end_index = -1
      num_iters = -1
      depth = 0

      line_array = text_array[start_index].split(" ")
      num_iters = @getNumLoopIterations(line_array, text_array)  # Get number of iterations for the loop

      # Get the depth of the for loop
      for word in text_array[start_index].split(" ")
         if word == ""
            depth = depth + 1
         else
            break

      # determine at what index the loop ends
      for i in [start_index + 1...text_array.length]
         _depth = 0
         for word in text_array[i].split(" ")
            if word == ""
               _depth = _depth + 1
            else
               break

         if depth == _depth
            end_index = i
            break

      # loop_info = [<start_index>, <end_index>, <num_iters>]
      loop_info.push(start_index)
      loop_info.push(end_index)
      loop_info.push(num_iters)

      return loop_info

   findLoops: ->
      if editor = atom.workspace.getActiveTextEditor()
         text = editor.getText()  # Get text from the buffer
         text_array = text.split("\n")  # Split the text by line into an array
         loop_infos = []
         for line, index in text_array
            if /(for \()/.test(line) and not /\/\//.test(line)
               loop_infos.push(loop_boundry = @getLoopBoundries(index, text_array))

         return loop_infos



   toggle: ->
      console.log 'MemoryBro was toggled!'
      loop_infos = @findLoops()
      console.log loop_infos
      # if editor = atom.workspace.getActiveTextEditor()
      #    text = editor.getText()
      #    text_array = text.split("\n")
      #    # console.log(text_array)
      #
      #    malloc_count = 0
      #    free_count = 0
      #
      #    for word, index in text_array
      #       if /malloc(...)/.test(word) and not /\/\//.test(word)  # malloc() is found
      #          prev_line = index - 1
      #
      #          # Check to see if malloc() is embedded in a 'for loop'
      #          if /(for \()/.test(text_array[prev_line])
      #             line_array = text_array[prev_line].split(" ")  # split text buffer by space
      #             num_iter = 0  # number at which the loop ends
      #             start_iter = 0  # number at which the loop starts
      #             # Iterate through each line to obtain the num_iter and start_iter values
      #             for item, i in line_array
      #                if line_array[i] == "="
      #                   start_iter_loc = i + 1
      #                   start_iter = parseInt(line_array[start_iter_loc], 10)
      #                   console.log "Start Iter = " + start_iter
      #
      #                if line_array[i] == "<"
      #                   iter_loc = i + 1
      #                   # number of iterations is stored in a variable
      #                   if /[a-z]/.test(line_array[iter_loc])
      #                      variable = line_array[iter_loc].replace(';', '')
      #                      console.log "Is variable: " + variable
      #                      re = new RegExp("int " + variable + " = ", "g")
      #
      #                      for line in text_array
      #                         if re.test(line)
      #                            l_array = line.split(" ")
      #                            for w, j in l_array
      #                               if l_array[j] == "="
      #                                  var_loc = j + 1
      #                                  num_iter = parseInt(l_array[var_loc], 10)
      #
      #                   # number of iterations is explicity declared
      #                   else
      #                      num_iter = parseInt(line_array[iter_loc], 10)
      #                      console.log "Num iter =  " + num_iter;
      #
      #                if line_array[i] == "<="
      #                   iter_loc = i + 1
      #                   num_iter = parseInt(line_array[iter_loc], 10) + 1
      #                   console.log "Num iter =  " + num_iter;
      #             malloc_count = malloc_count + (num_iter - start_iter)
      #
      #          else
      #             malloc_count = malloc_count + 1
      #
      #
      #
      #    console.log "#{malloc_count} malloc(...)"
      #    console.log "#{free_count} free(...)"
      #
      #    if @modalPanel.isVisible()
      #       @modalPanel.hide()
      #    else
      #       @memoryBroView.setOutput(malloc_count, free_count)
      #       @modalPanel.show()
