
globals [
  wall-color
  clear-colors ; list of colors that patches the snakes can enter have
  level tool ; ignore these two variables they are here to prevent warnings when loading the world/map.
]

patches-own [
  age ; if not part of a snake, age=-1. Otherwise age = ticks spent being a snake patch.
  visited ; Once the patch has been visited by the search method, usually
  parent  ; We use parent for recovering the path once the goal has been found
  path-cost ; When implementing algorithms that need a path cost
  claimed? ; If the snakes get an insight on what the other's goal is
]

breed [snakes snake]
snakes-own [
  team ; either red team or blue team
  mode ; how is the snake controlled.
  snake-age ; i.e., how long is the snake
  snake-color ; color of the patches that make up the snake

  planned_path ; planned path fpr each snake
  goal_location ; The patch containing the food
  going-to-starve? ; Wether the snake is blocked in with no food or not
]


;;=======================================================
;; Setup

to setup ; observer
  clear-all
  setup-walls
  setup-snakes

  set clear-colors [black green]
  ; Add food to enviroment
  check-fruit-amount
  reset-ticks
  reset-patches

end

;;--------------------------------

to reset-patches ; to reset variables between algorithm calls
  ask patches with [pcolor != wall-color] [
    set visited false
    set parent nobody
    set path-cost -1


    if pcolor = 105 or pcolor = 108 [ set pcolor black] ;for viewing algorithm calculation in real time
  ]
end


to setup-walls  ; observer
                ; none-wall patches are colored black:
  ask patches [ set age -1
    set pcolor black ]

  set wall-color gray ; IMPORTANT: IF THIS GETS CHANGED IT WILL ALSO NEED TO BE CHANGED IN THE START-DRAWING FUNCTION BELOW

  ; save current user values to restore later. There are limited options for saving files in netlogo and this seemed like it would be the most straightforward method.
  let temp-number-of-players number-of-players
  let temp-max-snake-age max-snake-age
  let temp-keep-dead-snakes keep-dead-snakes
  let temp-amount-of-food amount-of-food
  let temp-can-claim-food can-claim-food
  let temp-smart-snakes smart-snakes
  let temp-a-star-greedy-weighting a-star-greedy-weighting
  let temp-blue-team-mode blue-team-mode
  let temp-red-team-mode red-team-mode
  let temp-pink-team-mode pink-team-mode
  let temp-yellow-team-mode yellow-team-mode
  let temp-map-file map-file
  let temp-brush-type brush-type
  let temp-file-name file-name


  ; Set the edge of the environment to the wall-color:
  ask patches with [abs pxcor = max-pxcor or abs pycor = max-pycor] [set pcolor wall-color]
  if map-file != "empty" [  ; load the map:
    let map_file_path (word "maps/" map-file ".csv")
    ifelse (file-exists? map_file_path) [
      import-world map_file_path
    ] [
      user-message "Cannot find map file. Please check the \"maps\" directory is in the same directory as this Netlogo model."
    ]
    ; set the patch size (so that the larger maps don't cover the controls)
    ifelse map-file = "snake-map-3" [ set-patch-size 11 ]
                                    [ set-patch-size 14 ]
  ]

  ; restore user values
  set number-of-players temp-number-of-players
  set max-snake-age temp-max-snake-age
  set keep-dead-snakes temp-keep-dead-snakes
  set amount-of-food temp-amount-of-food
  set can-claim-food temp-can-claim-food
  set smart-snakes temp-smart-snakes
  set a-star-greedy-weighting temp-a-star-greedy-weighting
  set blue-team-mode temp-blue-team-mode
  set red-team-mode temp-red-team-mode
  set pink-team-mode temp-pink-team-mode
  set yellow-team-mode temp-yellow-team-mode
  set map-file temp-map-file
  set brush-type temp-brush-type
  set file-name temp-file-name
end



to save-map

  ; Remove snakes from map
  ask patches with [pcolor != wall-color and pcolor != green] [set pcolor black]
  ask snakes [die]

  ; save map under filename
  let save_file_name (word "maps/" file-name ".csv")
  export-world save_file_name

  user-message (word "Map saved under " save_file_name ".\n Please add this as an option above to select file")


  ; Setup world
  setup



end

;;--------------------------------

to setup-snakes  ; observer
                 ; create the snakes:

  ; create the red snake: ---------------
  create-snakes 1 [
    set team "red" ; /orange
    set xcor max-pxcor - 2
    set color red - 2
    set snake-color red + 11

    set mode red-team-mode

    ; Spawn position ---------

    ; set direction
    set heading 270

    ; create snake body
    ask patch [xcor] of self 0 [set pcolor [snake-color] of myself
      set age 0 ]
    ask patch ([xcor] of self + 1) 0 [set pcolor [snake-color] of myself
      set age 1]
  ]

  ; create the blue snake: ---------------
  if number-of-players >= 2 [
    create-snakes 1 [
      set team "blue" ;/purple
      set xcor 2 -(max-pxcor)
      set color blue - 2
      set snake-color blue + 11

      set mode blue-team-mode

      ; Spawn position ---------

      ; set direction
      set heading 90

      ; create snake body
      ask patch [xcor] of self 0 [set pcolor [snake-color] of myself
        set age 0 ]
      ask patch ([xcor] of self - 1) 0 [set pcolor [snake-color] of myself
        set age 1]

    ]
  ]


  ; create the pink snakes: ---------------
  if number-of-players >= 3 [
    create-snakes 1 [
      set team "pink"
      set ycor 2 - max-pycor
      set color pink - 3
      set snake-color pink

      set mode pink-team-mode

      ; Spawn position ---------

      ; set direction
      set heading 0

      ; create snake body
      ask patch 0 [ycor] of self [set pcolor [snake-color] of myself
        set age 0 ]
      ask patch 0 ([ycor] of self - 1) [set pcolor [snake-color] of myself
        set age 1]

    ]
  ]

  ; create the yellow snakes: ---------------
  if number-of-players >= 4 [
    create-snakes 1 [
      set team "yellow"
      set ycor max-pycor - 2
      set color yellow - 3
      set snake-color yellow
      set mode yellow-team-mode

      ; Spawn position ---------

      ; set direction
      set heading 180

      ; create snake body
      ask patch 0 [ycor] of self [set pcolor [snake-color] of myself
        set age 0 ]
      ask patch 0 ([ycor] of self + 1) [set pcolor [snake-color] of myself
        set age 1]

    ]
  ]


  ; set the attributes that are the same for all snakes:
  ask snakes [
    set snake-age 2 ; i.e. body contains two patches
    set planned_path [] ; set planned_path to an empty list
    set goal_location nobody ; no goal yet
    set going-to-starve? false

  ]
end

;;=======================================================

;;;
; Make a random patch green (e.g. the color of the food)
to make-food
  ask one-of patches with [pcolor = black] [
    set pcolor green
    set claimed? false

    ; Give the snakes some hope that the food spawned near them
    ask snakes [ set going-to-starve? false ]
  ]

end

; Allows the user to draw while the mouse is down
to start-drawing

  while [mouse-down?][

    ; Gets the coordinates of the current patch
    let current_patch patch round mouse-xcor round mouse-ycor

    (if-else

      brush-type = "wall"   and (member? [pcolor] of current_patch clear-colors) [ ask current_patch [set pcolor wall-color]]
      brush-type = "fruit"  and (member? [pcolor] of current_patch clear-colors) [ ask current_patch [set pcolor green set claimed? false]]
      brush-type = "eraser" and (member? [pcolor] of current_patch [grey green]) and [pxcor] of current_patch != max-pxcor and [pycor] of current_patch != max-pycor [ ask current_patch [set pcolor black set age -1 ]]

      [])

    ; User might have created a way out for trapped snakes
    ask snakes [ set going-to-starve? false ]
    tick

  ]


end





;;=======================================================

;;;
; Our main game control method
to go ; observer

  let winner nobody ; No winner yet...

  ; Check number of fruit is correct
  check-fruit-amount


  ask snakes [


    ; 1. Set which direction the snake is facing and calculate
    (if-else
      mode = "random" [face-random-neighboring-patch] ; face random direction
      mode = "human-keyboard"  [] ; do nothing


      ; else alg is used
      [if (mode = "human-mouse") or (empty? planned_path) or ([pcolor] of goal_location != green) or not member? [pcolor] of item 0 planned_path clear-colors [

        set planned_path [] ; erase planned path so that

        if-else mode != "human-mouse"[
          define-goal-patch ; define goal location
                            ;show word "defining new path to " goal_location ; find new route to goal
        ]

        ;else mode = human-mouse
        [set goal_location patch round mouse-xcor round mouse-ycor]


        ; If the snake cannot reach any goal, move randomly until it can
        if-else not going-to-starve? [

          ; set planned_path
          (if-else

            mode = "human-mouse"          [if-else member? [pcolor] of goal_location clear-colors [set planned_path greedy-best-first-search patch-here goal_location] [set planned_path [] face-random-neighboring-patch]]
            mode = "depth-first-search"   [set planned_path depth-first-search patch-here goal_location]
            mode = "breadth-first-search" [set planned_path breadth-first-search patch-here goal_location]
            mode = "uniform-cost-search"  [set planned_path uniform-cost-search patch-here goal_location]
            mode = "greedy-search"        [set planned_path greedy-best-first-search patch-here goal_location]
            mode = "A*-search"            [set planned_path a-star-search patch-here goal_location]
            mode = "lightning-search"     [set planned_path lightning-search patch-here]

            []) ; no else




          ; else no goal can be reached
        ][face-random-neighboring-patch]


        ]

        face-next-patch ; face the next patch
        reset-patches   ; reset all patch data after algs are performed


    ])



    ; 2. move the head of the snake forward
    fd 1

    ; 3. check for a collision (and thus game lost)
    if not member? pcolor clear-colors [
      user-message (word "Ouch! The " team " snake has died!")

      ; Check to see if there is only one snake left
      if count snakes = 2 [ set winner one-of other snakes]

      ; Remove dead snake from board if required
      if not keep-dead-snakes [ ask patches with [pcolor = [snake-color] of myself] [ set pcolor black ] ]

      ; kill the turtle (snake)
      die
    ]

    ; 4. eat food
    if pcolor = green [
      make-food
      set snake-age snake-age + 1
    ]

    ; 5. check if max age reached (and thus game won)
    if snake-age >= max-snake-age [
      set winner self
      stop
    ]

    ; 6. move snake body parts forward
    ask patches with [pcolor = [snake-color] of myself] [
      set age age + 1
      if age > [snake-age] of myself [
        set age -1
        set pcolor black
      ]
    ]

    ; 7. set the patch colour and age of the snake's head.
    set pcolor snake-color
    set age 0
  ]

  ; Check if snake has won
  if winner != nobody [
    user-message (word "Game Over! Team " [team] of winner " has won!")
    stop
  ]

  tick
end


; --------------------------------------


to define-goal-patch ; called within snake

  ; Unclaim food if claimed
  if (can-claim-food and goal_location != nobody)[
    ask goal_location [set claimed? false]
  ]


  ; find closest reachable (and unclaimed) piece of food and set as goal_location
  let possible_goal_locations sort-on [distance myself] (patches with [pcolor = green and (((can-claim-food and not claimed?) or not can-claim-food) or amount-of-food < count snakes )    ] )

  ; Set the goal location to the closest piece of food
  set goal_location first possible_goal_locations

  ; This slows the code down a lot, but will check using DFS wether there is any food that can be reached by the snake
  if smart-snakes[

    ; Check that the food is reachable using a quick algorithm (greedy search) (This does not affect the pathing of the snake, it only reduces the time spent searching for a valid goal)
    while [not check-reachable patch-here goal_location][

      ; if no goal can be reached stop and return nobody
      if-else (length possible_goal_locations = 1) [ set going-to-starve? true stop] ; set goal_location nobody

      ; else
      [
        set possible_goal_locations but-first possible_goal_locations ; Remove the first result from the list
        set goal_location first possible_goal_locations
      ]

    ]
  ]


  if can-claim-food [ ; claim food if allowed
    ask goal_location [set claimed? true]
  ]

end


;----------------------------

to face-next-patch
  if not empty? planned_path [
    face item 0 planned_path
    set planned_path remove-item 0 planned_path
  ]
end



; Checks if the amount of food on the board is correct
to check-fruit-amount
  while [amount-of-food > count patches with [pcolor = green]] [ make-food ]

  while [amount-of-food < count patches with [pcolor = green]] [ ask one-of patches with [pcolor = green] [ set pcolor black] ]
end


;;--------------------------------------------

;;;
; Make the turtle face a random unoccupied neighboring patch
;  if all patches are occupied, then any patch will be selected (and the snake lose :( )
to face-random-neighboring-patch ; turtle
  let next-patch one-of neighbors4 with [member? pcolor clear-colors]

  if next-patch = nobody [ ; if none of the neighbours are clear:
    set next-patch one-of neighbors4
  ]
  ; make the snake face towards the patch we want the snake to go to:
  face next-patch
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; depth-first search
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to-report depth-first-search [start_location end_location]

  if start_location = end_location [ report recover-plan end_location ] ;; perform goal test
  let frontiers (list start_location)


  loop [

    ; No path was found
    if empty? frontiers [report (list )]


    let current_node last frontiers                              ; get the last node from frontiers
    set frontiers remove-item (length frontiers - 1) frontiers   ; remove the last node from frontiers
    ask current_node [set visited true]                          ; Node has been explored/visited.

    if show-algorithm-steps [ask current_node [if pcolor = 105 [set pcolor 108]]] ; Update patch colour if showing algorithm steps


    foreach [valid-next-patches] of current_node [ valid_next_patch ->

      ; if the patch as not been visited and is not in frontier
      if (not ([visited] of valid_next_patch)) and (not member? valid_next_patch frontiers) [
        ask valid_next_patch [set parent current_node]                           ; Set current node as the parent node (for retrieving path)
        if valid_next_patch = end_location [report recover-plan end_location ]   ; Perform goal test

        set frontiers lput valid_next_patch frontiers  ; insert valid_next_patch into frontiers

        if show-algorithm-steps [ask valid_next_patch [if pcolor = black [set pcolor 105]]] ; Update patch colour if showing algorithm steps

      ]
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; breadth-first search
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to-report breadth-first-search [start_location end_location]

  if start_location = end_location [ report recover-plan end_location  ]; Check start node is not goal
  let frontiers (list start_location)

  loop[

    ; Return empty list if search fails
    if empty? frontiers[report (list )]

    ; Explore next node on frontier and remove it from queue
    let current_node first frontiers
    set frontiers remove-item 0 frontiers
    ask current_node [
      set visited true                                            ; Node has been explored/visited.
      if show-algorithm-steps [if pcolor = 105 [set pcolor 108]]] ; Update patch colour if showing algorithm steps

    ; For every adjacent node that hasnt been explored
    foreach [valid-next-patches] of current_node [ valid_next_patch ->

      ; if patch has not been visited and not in current frontier
      if (not ([visited] of valid_next_patch)) and (not member? valid_next_patch frontiers) [

        ask valid_next_patch [set parent current_node]                                      ; Set current node as the parent node (for retrieving path)
        if valid_next_patch = end_location [report recover-plan end_location ]              ; Perform goal test
        set frontiers lput valid_next_patch frontiers                                       ; insert valid_next_patch into frontiers
        if show-algorithm-steps [ask valid_next_patch [if pcolor = black [set pcolor 105]]] ; Update patch colour if showing algorithm steps

      ]
    ]
  ]


  ; planned path
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; uniform-cost search
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to-report uniform-cost-search [start_location end_location]

  if start_location = end_location [ report recover-plan end_location  ] ; Check start node is not goal
  let frontiers (list start_location)

  loop[

    ; Return empty list if frontier is empty
    if empty? frontiers[report (list )]

    ; Explore next node (with shortest path weight) on frontier and remove it from queue
    let current_node first frontiers

    foreach but-first frontiers[next_node ->
      if [path-cost] of next_node < [path-cost] of current_node [ set current_node next_node]
    ]

    set frontiers remove current_node frontiers ; Remove the current node from the frontier before its visited

    ask current_node [
      set visited true                                                              ; Node has been explored/visited.
      set path-cost path-cost + 1                                                   ; Add 1 to the path cost
      if show-algorithm-steps [ask current_node [if pcolor = 105 [set pcolor 108]]] ; Update patch colour if showing algorithm steps
    ]

    if current_node = end_location [report recover-plan end_location ] ; check for goal


    ; For every adjacent node that hasnt been explored
    foreach [valid-next-patches] of current_node [ valid_next_patch ->

      if (not [visited] of valid_next_patch) [

        ; in frontier with higher path cost
        if ([path-cost] of valid_next_patch > [path-cost] of current_node + 1)[
          ask valid_next_patch[
            set path-cost [path-cost] of current_node + 1 ; Add 1 to the path cost of the current node
            set parent current_node                       ; Set current node as the parent node (for retrieving path)
          ]
        ]

        ; not in frontier
        if ([path-cost] of valid_next_patch = -1)[
          ask valid_next_patch [
            set path-cost [path-cost] of current_node + 1                 ; Sets the path cost to the current node + the cost to move 1 patch (1)
            set parent current_node                                       ; Set current node as the parent node (for retrieving path)
            if show-algorithm-steps and pcolor = black [ set pcolor 105 ] ; Update patch colour if showing algorithm steps
          ]

          set frontiers lput valid_next_patch frontiers ; Add patches to frontier

        ]

      ]
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; greedy best-first search
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to-report greedy-best-first-search [start_location end_location]

  if start_location = end_location [ report recover-plan end_location  ]; Check start node is not goal
  let frontiers (list start_location) ; Add starting patch to frontier

  loop[

    ; Return empty list if the frontier is empty
    if empty? frontiers[report (list )]


    ; Explore next node (closest to goal)on frontier and remove it from queue
    let current_node first frontiers
    foreach but-first frontiers[next_node ->
      if [distance end_location] of next_node < [distance end_location] of current_node [ set current_node next_node]
    ]
    set frontiers remove current_node frontiers                                   ; Removes the current node from the frontier before its visited
    ask current_node [set visited true]                                           ; Node has been explored/visited.
    if show-algorithm-steps [ask current_node [if pcolor = 105 [set pcolor 108]]] ; Update patch colour if showing algorithm steps

    if current_node = end_location [report recover-plan end_location ] ; check for goal


    foreach [valid-next-patches] of current_node [ valid_next_patch ->

      ; if the patch has not been visited and is not in the current frontier
      if (not [visited] of valid_next_patch) and (not member? valid_next_patch frontiers)[

        ask valid_next_patch [
          set parent current_node                                       ; Set current node as the parent node (for retrieving path)
          if show-algorithm-steps and pcolor = black [ set pcolor 105 ] ; Update patch colour if showing algorithm steps
        ]

        set frontiers lput valid_next_patch frontiers ; Add patches to frontier

      ]

    ]
  ]

end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; a-star search
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to-report a-star-search [start_location end_location]

  if start_location = end_location [ report recover-plan end_location  ]; Check start node is not goal
  let frontiers (list start_location) ; add starting patch to frontier

  loop[

    ; Return empty list if frontier is empty
    if empty? frontiers[report (list )]

    ; Explore next node (with shortest path weight) on frontier and remove it from queue
    let current_node first frontiers

    foreach but-first frontiers[next_node ->       ; a-star-greedy-weighting determines how greatly the distance from the goal effects the chosen node compared to the path cost
      if [path-cost] of next_node * (1 - a-star-greedy-weighting) + ([distance end_location] of next_node) * a-star-greedy-weighting  <  [path-cost] of current_node * (1 - a-star-greedy-weighting) + ([distance end_location] of current_node) * a-star-greedy-weighting [ set current_node next_node]
    ]

    set frontiers remove current_node frontiers
    ask current_node [
      set visited true                                            ; Node has been explored/visited.
      set path-cost path-cost + 1                                 ; Add 1 to the path cost
      if show-algorithm-steps [if pcolor = 105 [set pcolor 108]]  ; Update patch colour if showing algorithm steps
    ]

    if current_node = end_location [report recover-plan end_location ] ; check for goal


    ; For every adjacent node that hasnt been explored
    foreach [valid-next-patches] of current_node [ valid_next_patch ->


      if (not [visited] of valid_next_patch) [ ; if the node has not been visited already


        ; in frontier with higher path cost
        if ([path-cost] of valid_next_patch > [path-cost] of current_node + 1)[
          ask valid_next_patch[
            set path-cost [path-cost] of current_node + 1  ; Sets the path cost to the current node + the cost to move 1 patch (1)
            set parent current_node                        ; Set current node as the parent node (for retrieving path)
          ]
        ]

        ; not in frontier
        if ([path-cost] of valid_next_patch = -1)[

          ask valid_next_patch [
            set path-cost [path-cost] of current_node + 1                 ; Add 1 to path cost
            set parent current_node                                       ; Set current node as the parent node (for retrieving path)
            if show-algorithm-steps and pcolor = black [ set pcolor 105 ] ; Update patch colour if showing algorithm steps
          ]

          set frontiers lput valid_next_patch frontiers ; Add patches to frontier
        ]

      ]
    ]
  ]

end





;;--------------------------------------------


to-report check-reachable [start_location end_location]
  if start_location = end_location [ reset-patches report true  ]; Check start node is not goal
  let frontiers (list start_location) ; Add starting patch to frontier

  loop[

    ; Return empty list if the frontier is empty
    if empty? frontiers[
      reset-patches
      report false
    ]


    ; Explore next node (closest to goal)on frontier and remove it from queue
    let current_node first frontiers
    foreach but-first frontiers[next_node ->
      if [distance end_location] of next_node < [distance end_location] of current_node [ set current_node next_node]
    ]
    set frontiers remove current_node frontiers                                   ; Removes the current node from the frontier before its visited
    ask current_node [set visited true]                                           ; Node has been explored/visited.

    if current_node = end_location [reset-patches report true ] ; check for goal

    foreach [valid-next-patches] of current_node [ valid_next_patch ->

      ; if the patch has not been visited and is not in the current frontier
      if (not [visited] of valid_next_patch) and (not member? valid_next_patch frontiers)[

        ask valid_next_patch [
          set parent current_node ; Set current node as the parent node (for retrieving path)

        ]

        set frontiers lput valid_next_patch frontiers ; Add patches to frontier

      ]
    ]
  ]

end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; lightning Search
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;








to-report lightning-search [start_location]

  if [pcolor] of start_location = green [ set goal_location start_location report recover-plan start_location ] ;; perform goal test
  let frontiers (list start_location)


  loop [
    if empty? frontiers [ ;; frontiers is empty; no path has been found.
                          ;show "Failed to find a valid path."
      report (list )
    ]



    let current_node last frontiers

    if length frontiers > 2 [ set current_node one-of sublist frontiers (length frontiers - 2) (length frontiers)]  ; get the last node from frontiers

    set frontiers remove current_node frontiers   ; remove the last node from frontiers
    ask current_node [set visited true]           ; Node has been explored/visited.

    if show-algorithm-steps [ask current_node [if pcolor = 105 [set pcolor 108]]] ; Update patch colour if showing algorithm steps


    foreach [valid-next-patches] of current_node [ valid_next_patch ->

      if (not ([visited] of valid_next_patch)) and (not member? valid_next_patch frontiers) [
        ask valid_next_patch [set parent current_node]                                                                      ; Set current node as the parent node (for retrieving path)
        if [pcolor] of valid_next_patch = green [set goal_location valid_next_patch report recover-plan valid_next_patch ]  ; Perform goal test

        set frontiers lput valid_next_patch frontiers ; insert valid_next_patch into frontiers

        if show-algorithm-steps [ask valid_next_patch [if pcolor = black [set pcolor 105]]] ; Update patch colour if showing algorithm steps

      ]
    ]
  ]

end



;;----------------------------------------------

;; returns a list contain the root (i.e, the start location)... node's parent's parent, node's parent, node
to-report recover-plan [node ]
  let plan (list )
  if [parent] of node = nobody [report (list node)]
  report remove-item 0 recover-plan-recursive [parent] of node plan
end
;;;;;;
;; Don't call this (instead call recover-plan)
to-report recover-plan-recursive [node plan]
  set plan fput node plan
  if [parent] of node = nobody [set plan lput goal_location plan report plan]
  report recover-plan-recursive [parent] of node plan
end



to-report valid-next-patches ;; patch procedure
  let dirs []
  if member? [pcolor] of patch-at 0 1 clear-colors
  [ set dirs lput patch-at 0 1 dirs ]
  if member? [pcolor] of patch-at 1 0 clear-colors
  [ set dirs lput patch-at 1 0 dirs ]
  if member? [pcolor] of patch-at 0 -1 clear-colors
  [ set dirs lput patch-at 0 -1 dirs ]
  if member? [pcolor] of patch-at -1 0 clear-colors
  [ set dirs lput patch-at -1 0 dirs ]
  report dirs
end


;;---------------------
;; Human controlled snakes:
to head-up [selected-team]
  ask snakes with [team = selected-team] [ set heading 0 ]
end
;----
to head-right [selected-team]
  ask snakes with [team = selected-team] [ set heading 90 ]
end
;----
to head-down [selected-team]
  ask snakes with [team = selected-team] [ set heading 180 ]
end
;----
to head-left [selected-team]
  ask snakes with [team = selected-team] [ set heading 270 ]
end




;;=======================================================

;; for displaying the age within the GUI:
to-report report-snake-age [team-name]
  report [snake-age] of one-of snakes with [team = team-name]
end

;;---------------------
@#$#@#$#@
GRAPHICS-WINDOW
333
10
803
481
-1
-1
14.0
1
10
1
1
1
0
0
0
1
-16
16
-16
16
0
0
1
ticks
30.0

BUTTON
40
37
113
70
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
42
74
105
107
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
611
495
772
540
red-team-mode
red-team-mode
"human-keyboard" "human-mouse" "random" "depth-first-search" "breadth-first-search" "uniform-cost-search" "greedy-search" "A*-search" "lightning-search"
1

BUTTON
385
546
440
579
up
head-up \"blue\"
NIL
1
T
OBSERVER
NIL
W
NIL
NIL
1

BUTTON
384
610
439
643
down
head-down \"blue\"
NIL
1
T
OBSERVER
NIL
S
NIL
NIL
1

BUTTON
330
577
385
610
left
head-left \"blue\"
NIL
1
T
OBSERVER
NIL
A
NIL
NIL
1

BUTTON
439
579
494
612
right
head-right \"blue\"
NIL
1
T
OBSERVER
NIL
D
NIL
NIL
1

CHOOSER
328
494
489
539
blue-team-mode
blue-team-mode
"human-keyboard" "human-mouse" "random" "depth-first-search" "breadth-first-search" "uniform-cost-search" "greedy-search" "A*-search" "lightning-search"
8

BUTTON
671
544
726
577
up
head-up \"red\"
NIL
1
T
OBSERVER
NIL
T
NIL
NIL
1

BUTTON
726
576
781
609
right
head-right \"red\"
NIL
1
T
OBSERVER
NIL
H
NIL
NIL
1

BUTTON
670
607
725
640
down
head-down \"red\"
NIL
1
T
OBSERVER
NIL
G
NIL
NIL
1

BUTTON
616
576
671
609
left
head-left \"red\"
NIL
1
T
OBSERVER
NIL
F
NIL
NIL
1

CHOOSER
821
15
968
60
map-file
map-file
"empty" "snake-map-1" "snake-map-2" "snake-map-3" "map1" "map2"
5

TEXTBOX
116
38
316
76
You need to press setup after changing the map or modes.
12
0.0
1

SLIDER
43
169
192
202
max-snake-age
max-snake-age
3
30
25.0
1
1
NIL
HORIZONTAL

MONITOR
492
494
567
539
Blue age
report-snake-age \"blue\"
0
1
11

MONITOR
775
495
846
540
Red age
report-snake-age \"red\"
0
1
11

SWITCH
45
302
194
335
can-claim-food
can-claim-food
1
1
-1000

TEXTBOX
47
336
197
375
Allows the snakes to claim food so that the snakes don't go for the same piece
10
0.0
1

SLIDER
43
484
256
517
a-star-greedy-weighting
a-star-greedy-weighting
0
1
0.75
0.01
1
Multiplier
HORIZONTAL

TEXTBOX
46
520
244
572
Defines a multiplier for how greedy the A* alg is (e.g:  0 = BFS   1 = Greedy)\n\n~0.75 is recomended
10
0.0
1

SLIDER
45
257
217
290
amount-of-food
amount-of-food
1
10
5.0
1
1
Foods
HORIZONTAL

SWITCH
877
496
1051
529
show-algorithm-steps
show-algorithm-steps
0
1
-1000

TEXTBOX
881
531
1031
549
*Needs to update continuously
11
0.0
1

SLIDER
43
125
225
158
number-of-players
number-of-players
1
4
4.0
1
1
players
HORIZONTAL

CHOOSER
330
656
491
701
pink-team-mode
pink-team-mode
"human-keyboard" "human-mouse" "random" "depth-first-search" "breadth-first-search" "uniform-cost-search" "greedy-search" "A*-search" "lightning-search"
7

CHOOSER
613
654
774
699
yellow-team-mode
yellow-team-mode
"human-keyboard" "human-mouse" "random" "depth-first-search" "breadth-first-search" "uniform-cost-search" "greedy-search" "A*-search" "lightning-search"
5

BUTTON
379
706
442
739
up
head-up \"pink\"
NIL
1
T
OBSERVER
NIL
I
NIL
NIL
1

BUTTON
441
738
504
771
right
head-right \"pink\"
NIL
1
T
OBSERVER
NIL
L
NIL
NIL
1

BUTTON
379
770
442
803
down
head-down \"pink\"
NIL
1
T
OBSERVER
NIL
K
NIL
NIL
1

BUTTON
316
739
379
772
left
head-left \"pink\"
NIL
1
T
OBSERVER
NIL
J
NIL
NIL
1

MONITOR
494
656
554
701
Pink Age
report-snake-age \"pink\"
17
1
11

MONITOR
778
655
850
700
yellow age
report-snake-age \"yellow\"
17
1
11

BUTTON
666
704
728
737
up
head-up \"yellow\"
NIL
1
T
OBSERVER
NIL
8
NIL
NIL
1

BUTTON
727
737
790
770
right
head-right \"yellow\"
NIL
1
T
OBSERVER
NIL
6
NIL
NIL
1

BUTTON
665
769
728
802
down
head-down \"yellow\"
NIL
1
T
OBSERVER
NIL
2
NIL
NIL
1

BUTTON
603
736
666
769
left
head-left \"yellow\"
NIL
1
T
OBSERVER
NIL
4
NIL
NIL
1

SWITCH
44
212
201
245
keep-dead-snakes
keep-dead-snakes
0
1
-1000

BUTTON
967
249
1075
282
Start Drawing
start-drawing
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
822
244
960
289
brush-type
brush-type
"wall" "fruit" "eraser"
0

SWITCH
45
384
174
417
smart-snakes
smart-snakes
0
1
-1000

TEXTBOX
47
419
197
475
Snakes will more randomly when trapped with no food. Impacts performance when turned on
11
0.0
1

TEXTBOX
823
214
996
256
Select brush and press Start Drawing button to draw on board
11
0.0
1

INPUTBOX
821
66
947
126
file-name
map3
1
0
String

BUTTON
953
67
1054
109
Save Map
save-map
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
821
139
1110
182
Change the file name and press save map to save the map as a csv file. This map can be imported by editing the 'map-file' chooser above and typing in your map name
11
0.0
1

@#$#@#$#@
# CMP2020 -- Assessment Item 1

__If you find any bugs in the code or have any questions regarding the assessment, please contact the module delivery team.__

## Your details

Name: Oliver Smith

Student Number: 26357261

## Extensions made

* The **'number-of-players'** slider, lets the user choose the number of snakes on the board. These snakes can be altered individually and the **'keep-dead-snakes'** switch sets whether the snake's body is kept on the board after it dies.
* The **'can-claim-fruit'** switch decides wether snakes can go for the same piece. This feature is inactive if the amount of snakes is greater than the amount of fruit on the board.
* The **'amount-of-food'** slider allows the user to choose the amount of fruit on the board. This slider can be changed during execution.
* The **'A*-greedy-weighting-slider'**  allows the user to choose the amount the A* algorithm is affected by the distance of each patch from the snake's goal.
* The **'show-algorithm-steps'** switch toggles the algorithm's visited patches (light blue) and frontier (dark blue) from being displayed while the algorithm is executing
* **Human-mouse** approach lets the user guide the snake(s) through the board using their mouse cursor. If the cursor is not on a valid patch, the snake will instead move randomly until it is. This approach uses the greedy search algorithm to path to the cursor and will avoid any obstacles in its way
* When the** smart-snakes** switch is on, the snakes will try and prolong their death by moving randomly when there is no fruit able to be picked up. It does this by checking every tick if it is trapped, and if it is, it sets the snakes going-to-starve? value to true. This was made out of necessity for when the user is creating their own maps.
* The **Start Drawing** button allows the user to draw walls or fruit (depending on the value of **'brush-type'**) directly onto the map even after the go button is pressed. These maps can be saved into the 'maps' folder in a csv format under the name given in the file-name field. To load these maps into the game, you will need to add the file name to the **'map-file'** chooser manually, as there is no way to do this automatically in netlogo (and I didn't feel like redesigning the whole map select system). 
* When a map is loaded, it will be given a border of wall patches (that cannot be removed) before adding the walls and fruit from the imported file. 
* **lightning-search** is a search that will explore patches randomly until it comes across a fruit. It is called lightning search because the way the frontier is searched looks like lightning :)



## References

(add your references below the provided reference)

Brooks, P. (2020) Snake-simple. Stuyvesant High School. Avaliable from http://bert.stuy.edu/pbrooks/fall2020/materials/intro-year-1/Snake-simple.html [accessed 16 November 2023].

ccl.northwestern.edu. (n.d.). NetLogo 6.1.1 User Manual: Programming Guide. [online] Available at: https://ccl.northwestern.edu/netlogo/docs/programming.html. [accessed 29 January 2024]

ccl.northwestern.edu. (n.d.). NetLogo 6.4.0 User Manual. [online] Available at: https://ccl.northwestern.edu/netlogo/docs/index2.html [Accessed 29 January 2024].
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
