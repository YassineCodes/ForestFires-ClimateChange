;; Modeling Climate Change and its Impact on Forest Fires Using an Agent-based Approach
;; Y. Baghoussi, P. J. R. M. Campos and R. J. F. Rossetti
globals [
  sky-top      ;; y coordinate of top row of sky
  earth-top    ;; y coordinate of top row of earth
  temperature  ;; overall temperature
  counter ;; count sun steps
  ;;-------------------------
  ;; Background variables
  environment
  image
  scaled
  ;;--------------------------
  peoples_num      ;; number of people in the model
  vehicles-go?     ;; boolean: turns off car/bus motion and CO2 production
  A-var ;; used to store x coordinate
  B-var ;; used to store y coordinate
  CO2-amount ;; integer amount of CO2 that a factory produce in its starting
  CO2-factor ;; integer: this is a factor that determines the impact of people on CO2
  cycles-per-year;; integer: this determines how slowly time passes
  factory-on?;; boolean: is factory emitting CO2 ?
  combien ;; integer: number of CO2 emitted by factories
  sun-run? ;; boolean: is the sun running ?
  how-much-water ;; stores quantity of vapor in the air to produce clouds
  x-cloud ;; stores cloud x coordinate
  y-cloud ;; stores cloud y coordinate
  rain-ok? ;; boolean: is the rain enabled ?
  total-nm-ch4 ;; total number of CH4 molecules
  tree_x ;; stores tree x coordinate
  tree_y ;; stores trees y coordinate
  counter_trees  ;; integer: number of trees
  people_unsupplied_percentage  ;; oxigen coverage
  counter-rhs  ;; integer counter to provoque a relative humidity
  counter-wind ;; integer counter to provoque a wind
  condition_heading ;; boolean (is the tree located in the wind direction)
  direction ;; degree: wind direction
  min_wind ;; percentage %: minimum wind velocity
  reset_wind ;; integer: counter to reset minimum wind velocity
]
extensions[ bitmap ] ;; read a picture for background
breed [CH4 C4] ;; methane
breed [ CO2 C2] ;; dioxide carbon
breed [raindrops raindrop] ;; raindrops
breed [rays ray]     ;; packets of sunlight
breed [IRs IR]       ;; packets of infrared radiation
breed [heats heat]   ;; packets of heat energy
breed [CO2s Carbon]     ;; packets of carbon dioxide
breed [trees my-tree]
breed [clouds cloud]
breed [suns sun]
breed [cars car ]
breed [buses bus ]
breed [ people pls]
breed [ factories factory ]
breed [ water agua]
breed [ burnts burnt] ;; burnt trees
breed [ RHs RH ] ;; relative humidity
breed [ winds windy ] ;; wind

raindrops-own [
  location          ;; either "falling", "in root", "in trunk", or "in leaves"
  amount-of-water
  rain-value
]
clouds-own [cloud-speed cloud-id how-much-rain]
rays-own [tree-Heading-number]
CO2s-own [co2-Heading-number]
CO2-own [visited]
CH4-own [CH4-Heading-number counter_ch4]
trees-own[howmuch]
cars-own[counter_car velocity go? cars-Heading-number-color cars-Heading-number-final]
buses-own[counter_car velocity go? buses-Heading-number-color buses-Heading-number-final]
people-own[counter_CH4 people-Heading-number-color people-Heading-number-final]
RHs-own [visited]
winds-own [visited]
burnts-own[visited rain_amount]

;;
;; Setup Procedures
;;

to setup
  clear-all
  set Wind 10
  set min_wind 20
  set counter 0
  set how-much-water 0
  set vehicles-go? true
  set factory-on? true
  set people_unsupplied_percentage 100
  set counter-wind 1
  set counter-rhs 1
  set reset_wind 1
  set-default-shape buses "bus"
  set-default-shape rays "ray"
  set-default-shape IRs "ray"
  set-default-shape clouds "cloud"
  set-default-shape heats "dot"
  set-default-shape CO2s "CO2-molecule"
  set-default-shape water "CO2-molecule"
  set rain-ok? false
  set-default-shape CH4 "CO2-molecule"
  set-default-shape suns "circle"
  setup-world
  set temperature 12
  ;; scale background image to patches color
  if (Environement = "Field")[set environment "warming.jpg"]
  if (Environement = "Desert")[set environment "desert.jpg"]
  set image bitmap:import environment
  set scaled bitmap:scaled image 540 142
  bitmap:copy-to-drawing scaled 0 100
  bitmap:copy-to-pcolors scaled true
  ;; END

  ;; set trees
  create-trees number-of-trees [
       createTree
      ]
  ;; END

  ;; Wind direction
  ifelse ((random 2) = 0)
        [set direction 90] ;; right
        [set direction -90] ;; left
  ;; END
  reset-ticks

end
;; setup atmosphere, earth ...
to setup-world
  set sky-top max-pycor - 5
  set earth-top 0
  set CO2-amount 40
  set combien 0
  set sun-run? true
  set cycles-per-year 200 ;; this determines how slowly time passes
  set CO2-factor .003 / cycles-per-year ;; this is a factor that determines the impact of people on CO2
  ask patches [  ;; set colors for the different sections of the world
    if pycor > sky-top [  ;; space
      set pcolor scale-color white pycor 22 15
    ]
    if pycor <= sky-top and pycor > earth-top [ ;; sky
      set pcolor scale-color blue pycor -20 20
    ]
    if pycor <= earth-top
      [ set pcolor red + 3 ] ;; earth
  ]


  ;; Create the sun
  create-suns 1 [
    setxy (min-pxcor + 2 + (sun-brightness * 20) / 10 / 3.14)
          max-pycor
    ;; change appearance based on intensity
    show-intensity
  ]
end
to go
  ;; Relative humidity is updated after each tick
  let tmp (precision (1 / (temperature) * 100 / (1 / 12) ) 2 )
  ;; Relative Humidity is related to temperature.

  ;; make sure the humidity does not exceed 100%.
  ;; Relatively the minimum temperature chosen is 12 Degrees.
  ;; 1/12 represents the invese of Temperature.
  ifelse tmp > 100 [
    set relative_humidity 100
  ][
    set relative_humidity tmp
  ]
  ;; END


  ;; Wind is updated after each 500 tick
  ;; Wind is related to trees. When a tree is burnt the minimum wind increases.
  if ticks = 500 * reset_wind [
   set reset_wind reset_wind + 1
   set wind random (100 - min_wind) + min_wind ;; Random value of Wind between 100% and minimum wind
  ]
  ;; END

  ;; If clouds exist
  ask clouds [ fd cloud-speed ]  ; move clouds along
  ;; END

  ;; Build sun shape (i.e based on the intensity)
  ask suns [ show-intensity ]
  ;; END

  ;; Run sun rays
  run-sunshine   ;; step sunshine
  ;; END


  run-heat  ;; step heat (when sun rays reach the earth, it will be absorbed conditionally to land type.
  ;; If absorbed, it is converted to heats)

  run-IR    ;; step IR (heat is sent back from earth to the air. It becomes IR i.e Infrared radiation or earth heat)

  ;; Run cars/buses if they exist
  if vehicles-go? [
    run-cars   ;; moves cars
    run-buses  ;; moves buses
  ]
  ;; END

  ;; Move people and their gases emissions
  run-people
  run-CH4
  ;; END

  run-CO2   ;; moves CO2 molecules
  if any? factories [
      run-CO2s ;; move CO2 from factory
  ]
  ;; move sun
  if sun-run? [
    run-SUN
  ]
  ;; END
  ;; if one day completed reset sun rays direction
  ask suns[
    if( xcor < min-pxcor + 2 )[set counter 0]
  ]
  ;; END

  ;; if user enable Natural Rain Fall during the simulation
  make-rain-fall
  move-water
  ;; END

  ;; factories, if they exist, emit gas.
  ask factories [set color 9.9 * (1 - (CO2-emission-factory   / 200 ))]
  ;; END
  ;; trees, if they exist, emit gas.
  run-trees
  ;;END

  tick
  ;; plot CO2
  If any? co2s [
    set-current-plot "CO2 Levels"
    plot count CO2s + count CO2
  ]
  ;;END
  ;; if user click on Natural Rain Fall rain-ok? is set True
  if rain-ok? [
    add-vapor ;; sea water evaporate
    run-vapor ;; vapor move to the air
  ]
  ;; END

  ;; Create and move winds arrows
  if ticks = 100 * counter-wind [
    set counter-wind counter-wind + 1
    ask winds[
    die
    ]
    add-wind(Wind * 100 / 100)
  ]
  run-winds
  ;; END

  ;; Create and move Relative humidity drops
  if ticks = 150 * counter-rhs [
    set counter-rhs counter-rhs + 1
    ask RHs[
    die
    ]
    add-humidity-trees ((floor(relative_humidity) * 20) / 100)
  ]
   run-RHs
  ;;END
  ;;After 220 ticks, we provokes a fire based on fire intensity
  if ticks = 220 [
    burn-tree
   ]
  ;; when ticks are more than 300 (i.e after the fire begin)
  if ticks > 300 [run-burn]
  ;; END

  ;; if rain is there, it cools off the fire.
  cool_burn
  ;; END
end
;;-------------------------------------------
to change-environment
  ;; loads an image as a background from the current directory the model was launched from
   import-drawing environment
end
to update-albedo ;; patch procedure
  set pcolor scale-color green albedo 0 1
end
;;-------------------------------------------
;; Auto-Albedo reflects the sun rays based on land type (absorption: sea 100%, green land 50%, ice land 0%)
;;-------------------------------------------
to encounter-earth

  ;;ask rays with [ycor <= earth-top] [

    ask rays with [((pcolor >= 22  and pcolor <= 27 ) or pcolor = 36.9  or pcolor = 34.5 or pcolor = 84.5 or pcolor = 84.6 or pcolor = 42.8 or pcolor = 43.3 or pcolor = 43.2 or pcolor = 43.1 or pcolor = 42.7 or pcolor = 42.1 or pcolor = 43 or pcolor = 9.9 or pcolor = 59.4 or pcolor = 9.6 or pcolor = 97.2 or pcolor = 49.9 or pcolor = 8.8) and tree-Heading-number = 0 ] [
     if (pcolor = 84.5 or pcolor = pcolor = 84.6)[set albedo 0]
      if (pcolor = 42.8 or pcolor = 43.3 or pcolor = 43.2 or pcolor = 43.1 or pcolor = 42.7 or pcolor = 42.1  or pcolor = 43)[set albedo 0.5]
      if (pcolor = 9.9  or pcolor = 59.4 or pcolor = 9.6 or pcolor = 97.2 or pcolor = 49.9 or pcolor = 8.8) [set albedo 1]
      if ((pcolor >= 22  and pcolor <= 27 ) or pcolor = 36.9  or pcolor = 34.5) [set albedo 1]
    ;; depending on the albedo either
    ;; the earth absorbs the heat or reflects it
    ifelse 100 * albedo > random 100
      [
    set heading 180 - heading set tree-Heading-number 1
    ][

        rt random 45 - random 45 ;; absorb into the earth
        set color red - 2 + random 4
      set breed heats ]

  ]
end
;;--------------------------------------
;; Sun function
;;--------------------------------------
to run-SUN
  ask suns [
    set counter counter + 0.02
    fd 0.02
    set heading 90
  ]
end
to run-sunshine
  ask rays [
    if not can-move? 0.3 [ die ]  ;; kill them off at the edge
    fd 0.3                        ;; otherwise keep moving
    reflect-rays-from-trees
     ]

  create-sunshine  ;; start new sun rays from top
  reflect-rays-from-clouds  ;; check for reflection off clouds
  encounter-earth   ;; check for reflection off earth and absorption
end
to create-sunshine
  ;; don't necessarily create a ray each tick
  ;; as brightness gets higher make more

 let sunxcor 0
 ask suns[

   set sunxcor xcor

    ]
  if 10 * sun-brightness > random 50 [
    create-rays 1 [
      set tree-Heading-number 0
      set heading 140 + (counter * 220 / 140)
      set color yellow
      ;; rays only come from a small area
      ;; near the top of the world
      setxy random ((sun-brightness * 20) / 10) * 2 / 3.14 + (sunxcor - (sun-brightness * 20) / 10 / 3.14)  max-pycor
    ]
  ]
end
to show-intensity  ;; sun procedure
  set color scale-color yellow (sun-brightness * 20) 0 150
  set size (sun-brightness * 20) / 10
  set label word sun-brightness "/5"
  ifelse (sun-brightness * 20) < 50
    [ set label-color yellow ]
    [ set label-color black  ]
end
;;-------------------------------------
;; trees add humidity to the air
;;-------------------------------------
to add-humidity-trees [n] ;; randomly adds n Rhs molecules to atmosphere
  let i round n  ;; n is real and can be negative or zero, i is the nearest integer
  if any? trees[
  repeat i [
      create-RHs 1 [
        set visited 0
        set color cyan + 3
        set shape "drop"
        set heading (random 140) - 70
        ifelse (count trees > 0 ) [
          ask one-of trees [
          set A-var xcor set B-var ycor
          ]] [
          set A-var random (2 * max-pxcor) + min-pxcor ]
        setxy A-var (B-var + 1)
       ]
  ]
]
end
;; move relative humidity
to run-RHs
  ask RHs [
    set heading 0 ;; turn a bit
    fd .02 * (temperature) ;; move forward a bit

    if (ycor >= sky-top - 2) [die ]

    ] ;; Move the Relative Humidity from the tree to sky and die when it reaches position (sky-top - 2)
end
;;-------------------------------------
;; randomly add n arrows of wind to environement
;;-------------------------------------
to add-wind [n]
  let i round n  ;; n is real and can be negative or zero, i is the nearest integer

  repeat i [
      create-winds 1 [
        set color gray
        set shape "default"
        set heading direction
        set visited false
        ifelse (count trees > 0 ) [
          ask one-of trees [
          set A-var xcor set B-var ycor
          ]] [
          set A-var random (2 * max-pxcor) + min-pxcor set B-var random (max-pycor - 10) ]
        setxy A-var (B-var + 1)
       ]
  ]
end
;; move wind
to run-winds
  ask winds [
    ;; turn a bit
    fd .02 * (temperature) ;; move forward a bit
    if (pxcor >= max-pxcor) [die]
    ] ;; bounce off sky top
end
;;-------------------------------------
;; Run forest fire: burn trees based on the fire intensity (set by the user).
;; The fire start at a random location
to burn-tree
   if any? trees [
     ;; when fire intensity is 100%, a distance for a tree to catch the fire is 2 (netlogo distance unit)
     ;; tmp3 is the distance computed based on the fire intensity set by user from 0 to 100%
     let tmp3 fire_intensity * 2 / 100
     if tmp3 > 0 [ ;; fire intensity is higher than 0
        ask one-of trees[ ;; select random tree and burn it
         set breed burnts
         set shape "fire"
         set visited false
         set rain_amount 0
         ask other trees [ ;; spread fire
            let tmp (relative_humidity * 7 / 100)
            let tmp2 (Wind * 1.1 / 100)
            let total tmp2 + (1 / tmp) + tmp3
            let d DISTANCE myself
            if d > 0 and d <= total ;; burn trees around on a distance up to "total"
              [
                set breed burnts
                set shape "fire"
                set visited false
                set rain_amount 0
                ;; update minimum wind (i.e increase the wind velocity whenever a trees is burnt)
                if Wind <= 99.1[
                  set min_wind (precision (min_wind + 0.1) 2 )
                ]
                ;; update oxigen coverage estimation
                set people_unsupplied_percentage people_unsupplied_percentage - 1
              ]
          ]
         ]
      ]
    ]
end
;; speard the fire based on meteorogical conditions. Wind and RH
to run-burn
  if any? burnts[
  ask burnts[
        let y ycor
        let x xcor
        let tmp (relative_humidity * 7 / 100)
        let tmp2 (Wind * 1.1 / 100)
        let total tmp2 + (1 / tmp)
        ask trees [
          let distance_ distancexy x y
          set condition_heading false
          if x - xcor > 0  and direction = -90 [ ;; left
            set condition_heading true
          ]
          if x - xcor < 0  and direction = 90 [ ;; right
            set condition_heading true
          ]
          ;; burn trees around on a distance up to "total"
          ;; and present in the direction of the wind
          if distance_ > 0 and distance_ <= total and condition_heading [
            set breed burnts set shape "fire"
            set visited false
            ;; update minimum wind (i.e increase the wind velocity whenever a trees is burnt)
            if Wind <= 99.1[
              set min_wind (precision (min_wind + 0.1) 2 )
            ]
            ;; update oxigen coverage estimation
            set people_unsupplied_percentage people_unsupplied_percentage - 1
          ]
        ]
  ]
  ]
end

;; ---------------------------------------
;; make-rain-fall: rain is a separate breed
;; of small turtles that come from the top of the world.
;; ---------------------------------------
to add-vapor
  if (temperature > 30 )[
    create-water 1 [
          set color gray
          set size 0.5
          set heading 0
          fd  0.5 + random 3
          setxy random-pxcor earth-top
        ]

    ]
end
to run-vapor
  ask water [
    set heading 0 ;; turn a bit
    fd .02 * (temperature) ;; move forward a bit

    if (ycor >= sky-top) [set how-much-water how-much-water + 1 die ]

    ] ;; bounce off sky top
    if(how-much-water >= 50)[add-cloud set how-much-water 0] ;; create clouds after a quatity of vapor
end
;; after water evaporation and clouds composition we make rain fall
to make-rain-fall
  ;; Create new raindrops at the top of the world
  if ((count clouds) > 35 and temperature <= 30) [
  create-raindrops rain-intensity [
    ask one-of clouds [ifelse(how-much-rain > 100)[die][set how-much-rain how-much-rain + 1] set x-cloud xcor set y-cloud ycor]

    setxy ((x-cloud - 3) + random 5)  y-cloud
    set heading 180
    fd 0.5 - random-float 1.0
    set size .3
    set color blue
    set location "falling"
    set amount-of-water 10
  ]

  ;; Now move all the raindrops, including
  ;; the ones we just created.

  ]
end
to move-water ;; fall rain from the clouds to earth
  ;; We assume that the roots extend under the entire grassy area; rain flows through
  ;; the roots to the trunk
  ask raindrops [ if any? raindrops [fd random-float 2 ]]
  ask raindrops with [location = "falling" and pcolor = 84.5 or pycor = earth-top] [
    die
  ]
end
;; cooling the burnt tree whenever a number of raindrop reaches it
to cool_burn
  if any? raindrops [
    ask raindrops [
      ask burnts with [distance myself < 0.5 ] [ifelse (rain_amount = rain-intensity * 5) [die][set rain_amount rain_amount + 1]] ;; co2 coming from cars
     ]
   ]
end
to add-cloud            ;; erase clouds and then create new ones, plus one
  let sky-height sky-top - earth-top

  ;; find a random altitude for the clouds but
  ;; make sure to keep it in the sky area
  let y earth-top + (random-float (sky-height - 4)) + 4
  ;; no clouds should have speed 0
  let speed (random-float 0.1) + 0.01
  let x random-xcor
  let id 0
  ;; we don't care what the cloud-id is as long as
  ;; all the turtles in this cluster have the same
  ;; id and it is unique among cloud clusters
  if any? clouds
  [ set id max [cloud-id] of clouds + 1 ]

  create-clouds 3 + random 20
  [
    set cloud-speed speed
    set cloud-id id
    set how-much-rain 0
    ;; all the cloud turtles in each larger cloud should
    ;; be nearby but not directly on top of the others so
    ;; add a little wiggle room in the x and ycors
    setxy x + random 9 - 4
          ;; the clouds should generally be clustered around the
          ;; center with occasional larger variations
          y + 2.5 + random-float 2 - random-float 2
    set color white
    ;; varying size is also purely for visualization
    ;; since we're only doing patch-based collisions
    set size 2 + random 2
    set heading 90
  ]
end
to reflect-rays-from-clouds
 ask rays with [any? clouds-here and tree-Heading-number = 0] [   ;; if ray shares patch with a cloud
   set heading 180 - heading   ;; turn the ray around
   set tree-Heading-number 1
   set color red
 ]
end
to remove-cloud       ;; erase clouds and then create new ones, minus one
  if any? clouds [
    let doomed-id one-of remove-duplicates [cloud-id] of clouds
    ask clouds with [cloud-id = doomed-id]
      [ die ]
  ]
end

;;-------------------------------
;; Manage trees: Trees absorb CO2 and reflect the sun rays
;;-------------------------------

to add-trees ;; randomly add two trees
  create-trees 2 [
       createTree
  ]
end

to createTree
        ;; half the trees are trees and half are pines
        set howmuch 0
        ifelse ((random 2) = 0)
        [set shape "myTree"]
        [set shape "myPineTree"]
        set size ((random 2) + 1 )
        if any? trees [
         ask one-of trees [
           set tree_x xcor
           set tree_y ycor
         ]
        ]
        set counter_trees count trees
        ifelse (counter_trees > 30)[setxy random-xcor random-ycor][setxy tree_x + random 2 tree_y + random 2]
        ;;setxy random-xcor random-ycor

        ifelse (pcolor >= 30 and pcolor <= 60 and pycor >= (earth-top + 2))  [ if ( xcor <= max-pxcor - 22 ) [setxy xcor + 0.5 ycor + 0.5 ] ][createTree]
        if any? other turtles-here [createTree]
end
to run-trees
  if any? trees [
    ask trees [
      ifelse (howmuch = 15) [ask CO2s with [distance myself < 2 ] [die] ;; co2 coming from cars/buses
        ask CO2 with [distance myself < 2 ] [if (visited = 1 ) [die set howmuch 0 set combien combien + 1]];; co2 coming from factory
      ][set howmuch howmuch + 1]
    ]
  ]
end
to deforest ;; randomly remove 2 trees
  repeat 2 [
    if any? trees [
      ask one-of trees [ die ]
    ]
  ]
end
to reflect-rays-from-trees
 ask rays with [any? trees-here] [
   if ( tree-Heading-number = 0 )[
    ;; if ray shares patch with a trees
   set heading 180 - heading   ;; turn the ray around
   set color blue
   set tree-Heading-number 1
   ]
 ]

end

;;-------------------------------
;; CH4 is related to people presence in the world (mainly from agriculture)
;;-------------------------------
to add-people [n]  ;; adds n people
  let i round n  ;; n is real and can be negative or zero, i is the nearest integer
  ;; if i is zero, this procedure does nothing
  if (i > 0) [   ;; if i is positive, add some people

      create-people i [
        set counter_CH4 counter_CH4 + 1
        hatch-CH4 1 [
          set total-nm-ch4 total-nm-ch4 + 1
          set counter_ch4 counter_ch4 + 1
          set CH4-Heading-number 0
          set color blue
          set size 1
          set heading 0
          fd  0.5 + random 3
        ]

        createPeople
        ]
      ]

end
;; People take different shape farmers, graduate, student etc.
to createPeople
        set people-Heading-number-final  2
        set people-Heading-number-color  1

        set heading 90
        set color 31 + random 9 ;; all shades of brown
        set size 2
        set shape one-of [ "person farmer" "person graduate" "person student"
          "person business" "person construction" "person doctor" "person police" ]
        setxy random-xcor 0
        setxy random-xcor random-ycor
        ifelse (pcolor >= 30 and pcolor <= 60 and pycor >= (earth-top + 2)) [  ] [createPeople]
        if any? other turtles-here [createPeople]
        set counter_CH4 0
end
;; run walks
to run-people
  go-people-back

  if any? people [
    ask people [
      set counter_CH4 counter_CH4 + 1
     fd .03 ;; move people slowly

      if counter_CH4 >= 300 [
        ;; here ch4
        set counter_CH4 0
        ]
    ]
  ]
end
;; if a person reached the limits of the surface, it goes back.
to go-people-back
 ask people [
   if ((pcolor = 84.5 or pcolor = 96.8 or pcolor = 84.6) and people-Heading-number-color = 0)[ ;; if the person is near the sea
     set people-Heading-number-color 1
     set heading 90
     set people-Heading-number-final 2
   ]
   if (pxcor = max-pxcor and people-Heading-number-final = 2)[ ;; if the person is in the right border
     set people-Heading-number-final 3
     set heading 90 - heading * 2
     set people-Heading-number-color 0
   ] ;; turn the person back
 ]
end
to run-CH4 ;; updates the number of CH4 molecules and moves them
  CH4-back
  ask CH4 [
    set heading heading + (random 51) - 25 ;; turn a bit
    fd .02 * (5 + random 10) ;; move forward a bit
    if (ycor <= earth-top + 1) [
      if(random 4 = 1 ) [   ;; 25% the time
        set heading 60 - random 120 ]
    ]
    if (ycor >= sky-top) [set heading 135 + random 90] ] ;; bounce off sky top

end
to CH4-back
  ask CH4 [
  ifelse(pxcor = max-pxcor and CH4-Heading-number = 1)[

   ][set CH4-Heading-number 0] ;; turn on the CH4 around
  if (pxcor = max-pxcor and CH4-Heading-number = 0)[ ;; if CH4 is at the border

     set CH4-Heading-number 1
     setxy (max-pxcor - random 1 ) pycor
     set heading heading - 180
   ]
   ]
end
to remove-people
  if any? people [
  ask one-of people [die]
  ]
end
;;-------------------------------
;; factories emit CO2
;;-------------------------------
to add-factories
    create-factories 1 [
        createFactory
        set A-var xcor set B-var ycor
        ]
    repeat 40 [
        create-CO2 1 [

        set color green
        set shape "CO2-molecule"
        set heading (random 140) - 70
         setxy A-var (B-var + 2)
          ]

        ]
end
to createFactory
        set color 9.9 * (1 - (CO2-emission-factory   / 200 ))
        set shape "factory"
        set size 4
        setxy random-xcor 0
        setxy random-xcor random-ycor
        ifelse (pcolor >= 30 and pcolor <= 60 and pycor >= (earth-top + 6)) [  ] [createFactory]
        if any? other turtles-here [createFactory]
end
to add-CO2-factory [n] ;; randomly adds n CO2 molecules to atmosphere
  let i round n  ;; n is real and can be negative or zero, i is the nearest integer
  repeat i [
      create-CO2 1 [
        set visited 0
        set color green
        set shape "CO2-molecule"
        set heading (random 140) - 70
        ifelse (count factories > 0 ) [
          ask one-of factories [
            set A-var xcor set B-var ycor
            ]] [
          set A-var random (2 * max-pxcor) + min-pxcor ]
        setxy A-var (B-var + 4) ]]
end
to run-CO2s ;; updates the number of CO2 molecules and moves them (Factory)

  ask CO2 [
    set heading heading + (random 51) - 25 ;; turn a bit
    fd .02 * (5 + random 10) ;; move forward a bit
    if (visited = 0) [ set visited 1]

    if (ycor <= earth-top + 1) [
        ;; 25% the time
        set heading 60 - random 120 ]
    if (ycor >= sky-top) [set heading 135 + random 90] ] ;; bounce off sky top
  set CO2-amount CO2-amount  + (CO2-emission-factory  + 10) * CO2-factor * (count people + 10) ;; add some CO2
    ;; The amount added is proportional to the CO2-emission slider and to the number of people
  if factory-on? [add-CO2-factory ( CO2-amount  - ( count CO2 + combien ) ) ];; add a number of molecules equal to the difference between

end
to remove-factory
  if any? factories [
    ask factories
      [ die ]
  ]
end
;;-------------------------------
;; cars move and emit CO2
;;-------------------------------
to add-cars [#how-many]
  create-cars #how-many [
    set peoples_num peoples_num + 2
    createCars
   ]
end
to createCars
        set cars-Heading-number-final  2
        set cars-Heading-number-color  1
        set shape one-of ["car_new" "pickup" "van"]
        set color one-of [violet blue orange pink]
        set size 1
        setxy random-xcor 0
        setxy random-xcor random-ycor
        ifelse (pcolor >= 30 and pcolor <= 60 and pycor >= (earth-top + 2)) [  ] [createCars]
        if any? other turtles-here [createCars]
        set heading 90
        set counter_car 0
        set velocity .02 + random-float .1
end
to run-cars
  go-cars-back
  if any? cars [
    ask cars [
      set counter_car counter_car + 1
      forward velocity
      if counter_car >= 50 [
        hatch-CO2s 1 [
          set co2-Heading-number 0
          set color green
          set size 1
          set heading 0
          fd  0.5 + random 3
        ]
        set counter_car 0
        ]
    ]
  ]
end
to go-cars-back
 ask cars [
   if ((pcolor = 84.5 or pcolor = 96.8 or pcolor = 84.6) and cars-Heading-number-color = 0)[ ;; if the car is near the sea
     set cars-Heading-number-color 1
     set heading 90

     set cars-Heading-number-final 2

   ]
   if (pxcor = max-pxcor and cars-Heading-number-final = 2)[ ;; if the car is in the right border
     set cars-Heading-number-final 3
     set heading 90 - heading * 2
     set cars-Heading-number-color 0

   ] ;; turn the car back
 ]
end
to remove-cars
  if any? cars [
  set peoples_num peoples_num - 2
  ask one-of cars [die]
  ]
end
;;-------------------------------
;; buses move and emit CO2
;;-------------------------------
to add-buses
  ifelse count cars < 5
  [ user-message "Please add AT LEAST five cars before adding a bus."]
  [
    create-buses  1 [
       ask n-of 5 cars [die ]
       show "One bus replaces 5 cars."
      createBuses
    ]
   ]
end
to createBuses
        set buses-Heading-number-final 2
        set buses-Heading-number-color 0
        set heading 90
        set size 1.5
        setxy random-xcor 0
        set counter_car 0
        set velocity .02 + random-float .2
        setxy random-xcor random-ycor
        ifelse (pcolor >= 30 and pcolor <= 60 and pycor >= (earth-top + 2)) [  ] [createBuses]
        if any? other turtles-here [createBuses]
end
to run-buses
  go-buses-back
  if any? buses [

      ask buses [

      set counter_car counter_car + 1
      fd velocity
      if counter_car >= 15 [
        hatch-CO2s 1 [
          set co2-Heading-number 0
          set color green
          set size 1
          set heading 0
          fd 1 + random 4
        ]
        set counter_car 0
        ]
    ]
  ]

end
to go-buses-back
 ask buses [
   if ((pcolor = 84.5 or pcolor = 96.8 or pcolor = 84.6) and buses-Heading-number-color = 0)[ ;; if the bus is near the sea turn back
     set buses-Heading-number-color 1
     set heading 90

     set buses-Heading-number-final 2
   ]
   if (pxcor = max-pxcor and buses-Heading-number-final = 2)[ ;; if the bus is near the right border turn back
     set buses-Heading-number-final 3
     set heading 90 - heading * 2
     set buses-Heading-number-color 0
   ] ;; turn the bus back
 ]
end
to remove-buses
   if any? buses [
     ask one-of buses [die]
     set peoples_num peoples_num - 1
     add-cars 10

    ]
end
;;-------------------------------------------
;; cars and buses CO2 function
;;-------------------------------------------
to run-CO2

  co2-back
  ask CO2s [
    rt random 51 - 25 ;; turn a bit
    let dist 0.05 + random-float 0.1
    ;; keep the CO2 in the sky area
    if (can-move? dist)[
    if [not shade-of? blue pcolor] of patch-ahead dist
      [ set heading 180 - heading ]
    ]
     fd dist ;; move forward a bit

  ]
end
to co2-back
  ask CO2s [

  ifelse(pxcor = max-pxcor and co2-Heading-number = 1)[

   ][set co2-Heading-number 0] ;; turn on the CO2 around
  if (pxcor = max-pxcor and co2-Heading-number = 0)[ ;; if CO2 is at the border

     set co2-Heading-number 1
     setxy (max-pxcor - random 1 ) pycor
     set heading heading - 180

   ]
   ]
end
;;-------------------------------------------
;; Temperature function
;;-------------------------------------------
to run-heat    ;; advances the heat energy turtles
  ;; the temperature is related to the number of heat turtles
  set temperature 0.99 * temperature + 0.01 * (12 + 0.1 * count heats)
  ask heats
  [
    let dist 0.5 * random-float 1
    ifelse can-move? dist

      [ fd dist ]
      [
        if patch-at dx 0 = nobody [
          set heading (- heading)
        ]
        if patch-at 0 dy = nobody [
          set heading (180 - heading)
        ]
      ] ;; if we're hitting the edge of the world, turn around
    if ycor >= earth-top [  ;; if heading back into sky
      ifelse temperature > 20 + random 40
              ;; heats only seep out of the earth from a small area
              ;; this makes the model look nice but it also contributes
              ;; to the rate at which heat can be lost
              and xcor > 0 and xcor < max-pxcor - 8
        [ set breed IRs                    ;; let some escape as IR
          set heading 20
          set color magenta ]
        [ set heading 100 + random 160 ] ;; return them to earth
    ]
  ]
end
to run-IR
  ask IRs [
    if not can-move? 0.3 [ die ]
    fd 0.3
    if ycor <= earth-top [   ;; convert to heat if we hit the earth's surface again
      set breed heats
      rt random 45
      lt random 45
      set color red - 2 + random 4
    ]
    if any? CO2s-here    ;; check for collision with CO2
      [ set heading 180 - heading ]
    if any? CO2-here    ;; check for collision with CO2 of factory
      [ set heading 180 - heading ]
     if any? CH4-here    ;; check for collision with CH4
      [ set heading 180 - heading ]
  ]
end
;;-------------------------------------
;; user add/remove CO2 buttons
;;-------------------------------------
to add-CO2  ;; randomly adds 25 CO2 molecules to atmosphere
  let sky-height sky-top - earth-top
  create-CO2s 25 [
    set color green
    set co2-Heading-number 0
    ;; pick a random position in the sky area
    setxy random-xcor
          earth-top + random-float sky-height
  ]
end
to remove-CO2 ;; randomly remove 25 CO2 molecules
  repeat 25 [
    if any? CO2s [
      ask one-of CO2s [ die ]
    ]
    if any? CO2 [
      ask one-of CO2 [ die ]
    ]
  ]
end

;; Modeling Climate Change and its Impact on Forest Fires Using an Agent-based Approach
;; Y. Baghoussi, P. J. R. M. Campos and R. J. F. Rossetti
@#$#@#$#@
GRAPHICS-WINDOW
319
11
866
361
-1
-1
11.0
1
10
1
1
1
0
1
0
1
-24
24
-8
22
1
1
1
ticks
30.0

BUTTON
17
12
108
45
setup
Setup
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
111
12
206
45
go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SLIDER
17
49
190
82
sun-brightness
sun-brightness
0
5
1.0
0.2
1
NIL
HORIZONTAL

SLIDER
17
92
190
125
albedo
albedo
0
1
0.5
0.05
1
NIL
HORIZONTAL

PLOT
871
75
1105
258
Global Temperature
NIL
NIL
0.0
10.0
10.0
20.0
true
false
"" ""
PENS
"default" 1.0 0 -2674135 true "" "plot temperature"

BUTTON
14
574
109
607
add CO2
add-CO2
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
111
574
206
607
remove CO2
remove-CO2
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

MONITOR
200
49
306
94
NIL
temperature
1
1
11

BUTTON
14
540
109
573
add cloud
add-cloud
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
111
540
206
573
remove cloud
remove-cloud
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

MONITOR
201
98
306
143
CO2 amount
count CO2s + count CO2
2
1
11

SLIDER
18
134
190
167
number-of-trees
number-of-trees
0
100
0.0
1
1
NIL
HORIZONTAL

SLIDER
18
178
190
211
rain-intensity
rain-intensity
0
30
16.0
1
1
NIL
HORIZONTAL

BUTTON
210
538
313
571
Remove tree
deforest
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
210
574
313
607
Add tree
add-trees
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
203
193
307
238
Oxigen Coverage
floor(people_unsupplied_percentage)
17
1
11

PLOT
318
367
598
578
CO2 Levels
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "if any? co2s or any? CO2 [ plot count CO2s + count CO2 ] show count co2s + count CO2"

BUTTON
14
428
107
466
add cars
add-cars ((random 4) + 1)\nset peoples_num peoples_num + 2
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
111
428
206
466
remove cars
remove-cars
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
13
646
169
679
START vehicles
set vehicles-go? true
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
171
646
314
679
STOP vehicles
set vehicles-go? false
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
14
468
108
501
add bus
add-cars 10\nshow count cars\nadd-buses\nask cars [die]
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
111
468
206
501
remove bus
if any? buses [\nask one-of buses [die]\nset peoples_num peoples_num - 21\n]
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
14
504
108
537
Add people
add-people 2\nlet number (count people )\n;;if (number mod 10 ) = 0\n;;[ add-factories ]\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
203
240
307
285
Population ( Million )
count people
0
1
11

SLIDER
18
221
190
254
CO2-emission-factory
CO2-emission-factory
0
200
0.0
1
1
%
HORIZONTAL

BUTTON
110
504
206
537
Remove people
remove-people
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
202
145
307
190
CH4 amount
count CH4
17
1
11

BUTTON
208
465
312
498
STOP Factories
set factory-on? false
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
209
500
312
536
START Factories
set factory-on? true
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
603
368
866
579
Methane level
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "if any? CH4 [plot count CH4] show count CH4"

BUTTON
208
429
312
462
STOP sun
set sun-run? false
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
209
393
312
426
START sun
set sun-run? true
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
203
288
308
333
Relative Humidity
floor(relative_humidity)
17
1
11

BUTTON
14
393
207
426
Natural rain fall
set rain-ok? true
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
14
609
169
642
Add factory
add-factories
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
1076
20
1252
53
Export as CSV
export-all-plots \"C:/Users/asus/Documents/climat/plots.csv\"
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
171
609
314
642
Remove factory
remove-factory
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
878
18
1016
63
Environement
Environement
"Field" "Desert"
0

SLIDER
19
303
191
336
relative_humidity
relative_humidity
20
100
51.74
1
1
NIL
HORIZONTAL

SLIDER
19
343
191
376
fire_intensity
fire_intensity
1
100
100.0
1
1
NIL
HORIZONTAL

SLIDER
19
262
191
295
Wind
Wind
0
100
30.0
1
1
NIL
HORIZONTAL

MONITOR
203
335
308
380
Wind
Wind
17
1
11

PLOT
1108
74
1337
258
Wind Velocity %
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot Wind"

PLOT
870
260
1105
445
Number of Trees
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count trees"

PLOT
1107
260
1337
446
Relative Humidity
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot relative_humidity"

PLOT
871
447
1105
639
Burnt Trees
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count burnts"

@#$#@#$#@
## WHAT IS IT 

This model is a new version of the climate change model (Tinker, R. and Wilensky, U. (2007). NetLogo Climate Change model) and (Baghoussi, Y. Campos, P. and Rossetti, R., "An agent-based model of the Earth system & climate change").

The goal behind this project is to provide a test-bed that can be used by educators and also policy makers, so they can evaluate theories related to the Earth system so as to test and evaluate metrics such as greenhouse gases, forest fires and climate change in general. 


## HOW IT WORKS

The structure of the model is based on many climate theories which allow the user to run multiple scenarios. The scenarios are defined by multiple inputs set by the user after the environment modeling is concluded. While modeling an environment scenario, the user is able to set up the following parameters:

Landscape : Two types of landscapes are now available: field and desert. The field landscape is set by default and contains three types of landscapes: sea, field and icy grounds. The second landscape is desert. Selected to illustrate the effect of climate change at a regional scale. The Earth behaves as a system in which oceans, atmosphere and land, and the living and non-living parts therein, are all connected.

Sun Brightness: A value of "1" corresponds to the current position of the sun. Higher values would allow us to see what would happen if the Earth was closer to the sun in its orbit, or if the sun got brighter. Climate is influenced by natural changes that affect the amount of the solar energy that reaches the Earth.

Dynamic Albedo: Each landscape absorbs the sun energy in a different and specific way. The sea absorbs 100% of incoming energy; the ground absorbs from 50% to 60%; however, ice reflects all the incoming energy. That is to say it avoids warming.
The model is developed to automatically detect the type of the land (ground, icy, or sea) for the reflectiveness process.
The blue rays are the reflected incoming energy from the green land according to the rule of 50% to 60% of absorption.

Earth System: The equilibrium between the entering energy (yellow rays) and the leaving energy (purple rays) from the planet system relies on the Earth's temperature.
The Earth becomes warmer if its system absorbs the external incoming energy from sunlight. However, when solar energy is reflected due to clouds, the planet is no more warmer and the sunlight is reflected back to space (red rays). In addition, the Earth becomes colder when the absorbed energy is released into space (purple rays).

Trees Density: In the implemented simulation, the user is able to set a number of trees directly using the slider or simply by clicking a button to add trees. The correlation between the presence of trees and global temperature is significant.

Greenhouse Gases: The CO2, is the most abundant gas emitted by human activities alone provides 1/3 of the greenhouse effect. In this model, the amount  of CO2 added is proportional to the factories CO2 emission (75%) as well as the number of vehicles (25%).

Population: The CH4 is emitted after 300 walking steps of each person.
Natural rain fall: during the simulation the user can enable rain fall

Fire intensity: manual

wind velocity: both auto and manual

relative humidity: both auto and manual

The rain intensity: manual


## HOW TO USE IT

We propose some scenarios for demonstration:

Note: the user can use either buttons or sliders to tune the scenarios.

Global warming:

Scenario 1 - We propose a scenario which represents the desired world, a world without any CO2 emitter, with no climate change effect. The model contains simply an amount of people and trees.

Scenario 2 - The second scenario is a balance between carbon emitters and the number of trees. A moderate number of factories and cars/buses. (This scenario is tested after a new setup of the model)

The user can stop the sun, from the scenario 2, using the appropriate button and pursue with the following scenarios: 

Scenario 3 - Here, trees are removed (from the second scenario) and the factories, cars and buses are kept. This demonstrate the impact of removing the trees in the global temperature.

Scenario 4 - Trees are added back to the model. This will decrease the global temperature.

Results discussion of scenario 1:4 can be found in:
"An agent-based model of the Earth system & climate change" in ISC Smart Cities Conference IEEE International 2016.

Forest fires:

Scenario 1 - We run the model with 75% of fire intensity on a world without CO2 emitters
Scenario 2 - We run the model with 75% of fire intensity on a world with CO2 emitters.
Scenario 3 - We enable the natural rain fall during one of the above scenarios.

The results of Scenario 1:2 will demonstrate how the global warming affects the behavior of forest fire.
In scenario 3, the rain will cools off the burnt trees.

## THINGS TO NOTICE

Watch the reflected sun rays. In the sea, the sun energy is absorbed by 100%, in green land by around 50-60% and finally, in the icy land, it is reflected by 100%. 

The fire propagation is happening based on wind direction.
The fire propagates faster when Relative humidity is low and Wind velocity is high.

## THINGS TO TRY

1. Run the model with a desired parameters and stop the sun somewhere in the world than start adding, removing trees, factories, vehicles, people. Observe the temperature evolution, fire propagation and Wind / Relative humidity corelation.
2. Save the results in CSV file for further analysis and plots.
3. You can do more with your creativity =)

## NETLOGO FEATURES
Note that the background is a picture that is converted to patch colors.
Note that the land type is detected by checking the patch color of the background figure.
The C02 and CH4 do not leave the earth box. This is made using xcor and ycor.
Note that clouds are actually made up of lots of small circular turtles.

## RELATED MODELS
Tinker, R. and Wilensky, U. (2007). NetLogo Climate Change model

Baghoussi, Y. Campos, P. and Rossetti, R., "An agent-based model of the Earth system & climate change"

## CREDITS AND REFERENCES

This new model builds on an earlier version created in 2016 by Yassine Baghoussi for the Smart Cities Conference (ISC2), 2016 IEEE International.

## HOW TO CITE

If you mention this model in a publication, we ask that you include these citations for the model itself and for the NetLogo software:

* Y. Baghoussi, P. J. R. M. Campos and R. J. F. Rossetti, "An agent-based model of the Earth system & climate change," 2016 IEEE International Smart Cities Conference (ISC2), Trento, 2016, pp. 1-6.

## COPYRIGHT AND LICENSE

Copyright 2018 University of Porto.
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

bus
false
0
Polygon -1184463 true false 289 166 288 131 271 121 286 128 285 115 282 76 270 67 257 63 245 59 116 63 -11 64 -11 136 -11 151 -10 193 288 199 289 166
Circle -16777216 true false 37 169 78
Circle -7500403 true true 54 187 44
Rectangle -16777216 true false 8 86 33 132
Circle -16777216 true false 209 171 78
Circle -7500403 true true 230 188 44
Rectangle -16777216 true false 43 85 68 131
Rectangle -16777216 true false 77 85 102 131
Rectangle -16777216 true false 110 85 135 131
Rectangle -16777216 true false 263 89 284 128
Rectangle -16777216 true false 176 85 201 131
Rectangle -16777216 true false 143 85 168 131
Line -16777216 false 6 132 205 131
Polygon -16777216 true false 210 90 210 165 255 150 255 75 210 75 210 105
Rectangle -1184463 true false 229 72 236 167
Circle -2064490 true false 268 103 14
Circle -6459832 true false 269 104 13
Circle -7500403 true true 180 107 14
Circle -2064490 true false 146 104 14
Circle -6459832 true false 115 104 14
Circle -2064490 true false 81 104 14
Circle -6459832 true false 47 104 14

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

car_new
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58
Circle -6459832 true false 144 84 42
Circle -2064490 true false 155 96 30

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cloud
false
0
Circle -7500403 true true 13 118 94
Circle -7500403 true true 86 101 127
Circle -7500403 true true 51 51 108
Circle -7500403 true true 118 43 95
Circle -7500403 true true 158 68 134

co2-molecule
true
0
Circle -1 true false 183 63 84
Circle -16777216 false false 183 63 84
Circle -7500403 true true 75 75 150
Circle -16777216 false false 75 75 150
Circle -1 true false 33 63 84
Circle -16777216 false false 33 63 84

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

drop
false
0
Circle -7500403 true true 73 133 152
Polygon -7500403 true true 219 181 205 152 185 120 174 95 163 64 156 37 149 7 147 166
Polygon -7500403 true true 79 182 95 152 115 120 126 95 137 64 144 37 150 6 154 165

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

factory
false
0
Rectangle -7500403 true true 76 194 285 270
Rectangle -7500403 true true 36 95 59 231
Rectangle -16777216 true false 90 210 270 240
Line -7500403 true 90 195 90 255
Line -7500403 true 120 195 120 255
Line -7500403 true 150 195 150 240
Line -7500403 true 180 195 180 255
Line -7500403 true 210 210 210 240
Line -7500403 true 240 210 240 240
Line -7500403 true 90 225 270 225
Circle -1 true false 37 73 32
Circle -1 true false 55 38 54
Circle -1 true false 96 21 42
Circle -1 true false 105 40 32
Circle -1 true false 129 19 42
Rectangle -7500403 true true 14 228 78 270

fire
false
0
Polygon -7500403 true true 151 286 134 282 103 282 59 248 40 210 32 157 37 108 68 146 71 109 83 72 111 27 127 55 148 11 167 41 180 112 195 57 217 91 226 126 227 203 256 156 256 201 238 263 213 278 183 281
Polygon -955883 true false 126 284 91 251 85 212 91 168 103 132 118 153 125 181 135 141 151 96 185 161 195 203 193 253 164 286
Polygon -2674135 true false 155 284 172 268 172 243 162 224 148 201 130 233 131 260 135 282

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

molecule water
true
0
Circle -1 true false 183 63 84
Circle -16777216 false false 183 63 84
Circle -7500403 true true 75 75 150
Circle -16777216 false false 75 75 150
Circle -1 true false 33 63 84
Circle -16777216 false false 33 63 84

myburnttree
false
1
Circle -7500403 true false 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true false 65 21 108
Circle -7500403 true false 116 41 127
Circle -7500403 true false 45 90 120
Circle -7500403 true false 104 74 152

mypinetree
false
0
Rectangle -6459832 true false 120 225 180 300
Polygon -14835848 true false 150 240 240 270 150 135 60 270
Polygon -14835848 true false 150 75 75 210 150 195 225 210
Polygon -14835848 true false 150 7 90 157 150 142 210 157 150 7

mytree
false
1
Circle -13840069 true false 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -13840069 true false 65 21 108
Circle -13840069 true false 116 41 127
Circle -13840069 true false 45 90 120
Circle -13840069 true false 104 74 152

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

person business
false
0
Rectangle -1 true false 120 90 180 180
Polygon -13345367 true false 135 90 150 105 135 180 150 195 165 180 150 105 165 90
Polygon -7500403 true true 120 90 105 90 60 195 90 210 116 154 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 183 153 210 210 240 195 195 90 180 90 150 165
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 76 172 91
Line -16777216 false 172 90 161 94
Line -16777216 false 128 90 139 94
Polygon -13345367 true false 195 225 195 300 270 270 270 195
Rectangle -13791810 true false 180 225 195 300
Polygon -14835848 true false 180 226 195 226 270 196 255 196
Polygon -13345367 true false 209 202 209 216 244 202 243 188
Line -16777216 false 180 90 150 165
Line -16777216 false 120 90 150 165

person construction
false
0
Rectangle -7500403 true true 123 76 176 95
Polygon -1 true false 105 90 60 195 90 210 115 162 184 163 210 210 240 195 195 90
Polygon -13345367 true false 180 195 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285
Circle -7500403 true true 110 5 80
Line -16777216 false 148 143 150 196
Rectangle -16777216 true false 116 186 182 198
Circle -1 true false 152 143 9
Circle -1 true false 152 166 9
Rectangle -16777216 true false 179 164 183 186
Polygon -955883 true false 180 90 195 90 195 165 195 195 150 195 150 120 180 90
Polygon -955883 true false 120 90 105 90 105 165 105 195 150 195 150 120 120 90
Rectangle -16777216 true false 135 114 150 120
Rectangle -16777216 true false 135 144 150 150
Rectangle -16777216 true false 135 174 150 180
Polygon -955883 true false 105 42 111 16 128 2 149 0 178 6 190 18 192 28 220 29 216 34 201 39 167 35
Polygon -6459832 true false 54 253 54 238 219 73 227 78
Polygon -16777216 true false 15 285 15 255 30 225 45 225 75 255 75 270 45 285

person doctor
false
0
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -13345367 true false 135 90 150 105 135 135 150 150 165 135 150 105 165 90
Polygon -7500403 true true 105 90 60 195 90 210 135 105
Polygon -7500403 true true 195 90 240 195 210 210 165 105
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 79 172 94
Polygon -1 true false 105 90 60 195 90 210 114 156 120 195 90 270 210 270 180 195 186 155 210 210 240 195 195 90 165 90 150 150 135 90
Line -16777216 false 150 148 150 270
Line -16777216 false 196 90 151 149
Line -16777216 false 104 90 149 149
Circle -1 true false 180 0 30
Line -16777216 false 180 15 120 15
Line -16777216 false 150 195 165 195
Line -16777216 false 150 240 165 240
Line -16777216 false 150 150 165 150

person farmer
false
0
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -1 true false 60 195 90 210 114 154 120 195 180 195 187 157 210 210 240 195 195 90 165 90 150 105 150 150 135 90 105 90
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 79 172 94
Polygon -13345367 true false 120 90 120 180 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 180 90 172 89 165 135 135 135 127 90
Polygon -6459832 true false 116 4 113 21 71 33 71 40 109 48 117 34 144 27 180 26 188 36 224 23 222 14 178 16 167 0
Line -16777216 false 225 90 270 90
Line -16777216 false 225 15 225 90
Line -16777216 false 270 15 270 90
Line -16777216 false 247 15 247 90
Rectangle -6459832 true false 240 90 255 300

person graduate
false
0
Circle -16777216 false false 39 183 20
Polygon -1 true false 50 203 85 213 118 227 119 207 89 204 52 185
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 79 172 94
Polygon -8630108 true false 90 19 150 37 210 19 195 4 105 4
Polygon -8630108 true false 120 90 105 90 60 195 90 210 120 165 90 285 105 300 195 300 210 285 180 165 210 210 240 195 195 90
Polygon -1184463 true false 135 90 120 90 150 135 180 90 165 90 150 105
Line -2674135 false 195 90 150 135
Line -2674135 false 105 90 150 135
Polygon -1 true false 135 90 150 105 165 90
Circle -1 true false 104 205 20
Circle -1 true false 41 184 20
Circle -16777216 false false 106 206 18
Line -2674135 false 208 22 208 57

person lumberjack
false
0
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -2674135 true false 60 196 90 211 114 155 120 196 180 196 187 158 210 211 240 196 195 91 165 91 150 106 150 135 135 91 105 91
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 79 172 94
Polygon -6459832 true false 174 90 181 90 180 195 165 195
Polygon -13345367 true false 180 195 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285
Polygon -6459832 true false 126 90 119 90 120 195 135 195
Rectangle -6459832 true false 45 180 255 195
Polygon -16777216 true false 255 165 255 195 240 225 255 240 285 240 300 225 285 195 285 165
Line -16777216 false 135 165 165 165
Line -16777216 false 135 135 165 135
Line -16777216 false 90 135 120 135
Line -16777216 false 105 120 120 120
Line -16777216 false 180 120 195 120
Line -16777216 false 180 135 210 135
Line -16777216 false 90 150 105 165
Line -16777216 false 225 165 210 180
Line -16777216 false 75 165 90 180
Line -16777216 false 210 150 195 165
Line -16777216 false 180 105 210 180
Line -16777216 false 120 105 90 180
Line -16777216 false 150 135 150 165
Polygon -2674135 true false 100 30 104 44 189 24 185 10 173 10 166 1 138 -1 111 3 109 28

person police
false
0
Polygon -1 true false 124 91 150 165 178 91
Polygon -13345367 true false 134 91 149 106 134 181 149 196 164 181 149 106 164 91
Polygon -13345367 true false 180 195 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285
Polygon -13345367 true false 120 90 105 90 60 195 90 210 116 158 120 195 180 195 184 158 210 210 240 195 195 90 180 90 165 105 150 165 135 105 120 90
Rectangle -7500403 true true 123 76 176 92
Circle -7500403 true true 110 5 80
Polygon -13345367 true false 150 26 110 41 97 29 137 -1 158 6 185 0 201 6 196 23 204 34 180 33
Line -13345367 false 121 90 194 90
Line -16777216 false 148 143 150 196
Rectangle -16777216 true false 116 186 182 198
Rectangle -16777216 true false 109 183 124 227
Rectangle -16777216 true false 176 183 195 205
Circle -1 true false 152 143 9
Circle -1 true false 152 166 9
Polygon -1184463 true false 172 112 191 112 185 133 179 133
Polygon -1184463 true false 175 6 194 6 189 21 180 21
Line -1184463 false 149 24 197 24
Rectangle -16777216 true false 101 177 122 187
Rectangle -16777216 true false 179 164 183 186

person service
false
0
Polygon -7500403 true true 180 195 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285
Polygon -1 true false 120 90 105 90 60 195 90 210 120 150 120 195 180 195 180 150 210 210 240 195 195 90 180 90 165 105 150 165 135 105 120 90
Polygon -1 true false 123 90 149 141 177 90
Rectangle -7500403 true true 123 76 176 92
Circle -7500403 true true 110 5 80
Line -13345367 false 121 90 194 90
Line -16777216 false 148 143 150 196
Rectangle -16777216 true false 116 186 182 198
Circle -1 true false 152 143 9
Circle -1 true false 152 166 9
Rectangle -16777216 true false 179 164 183 186
Polygon -2674135 true false 180 90 195 90 183 160 180 195 150 195 150 135 180 90
Polygon -2674135 true false 120 90 105 90 114 161 120 195 150 195 150 135 120 90
Polygon -2674135 true false 155 91 128 77 128 101
Rectangle -16777216 true false 118 129 141 140
Polygon -2674135 true false 145 91 172 77 172 101

person soldier
false
0
Rectangle -7500403 true true 127 79 172 94
Polygon -10899396 true false 105 90 60 195 90 210 135 105
Polygon -10899396 true false 195 90 240 195 210 210 165 105
Circle -7500403 true true 110 5 80
Polygon -10899396 true false 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -6459832 true false 120 90 105 90 180 195 180 165
Line -6459832 false 109 105 139 105
Line -6459832 false 122 125 151 117
Line -6459832 false 137 143 159 134
Line -6459832 false 158 179 181 158
Line -6459832 false 146 160 169 146
Rectangle -6459832 true false 120 193 180 201
Polygon -6459832 true false 122 4 107 16 102 39 105 53 148 34 192 27 189 17 172 2 145 0
Polygon -16777216 true false 183 90 240 15 247 22 193 90
Rectangle -6459832 true false 114 187 128 208
Rectangle -6459832 true false 177 187 191 208

person student
false
0
Polygon -13791810 true false 135 90 150 105 135 165 150 180 165 165 150 105 165 90
Polygon -7500403 true true 195 90 240 195 210 210 165 105
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -1 true false 100 210 130 225 145 165 85 135 63 189
Polygon -13791810 true false 90 210 120 225 135 165 67 130 53 189
Polygon -1 true false 120 224 131 225 124 210
Line -16777216 false 139 168 126 225
Line -16777216 false 140 167 76 136
Polygon -7500403 true true 105 90 60 195 90 210 135 105

pickup
false
0
Polygon -7500403 true true 298 183 277 167 259 147 238 138 224 135 211 109 201 87 171 74 118 63 118 153 28 153 -2 153 -2 168 -2 228 298 228 298 183
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -1 true false 47 195 58
Circle -1 true false 195 195 58
Circle -16777216 true false 60 210 30
Circle -16777216 true false 210 210 30
Circle -6459832 true false 142 100 32
Circle -6459832 true false 85 115 32

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

ray
true
0
Line -7500403 true 150 0 150 315
Line -7500403 true 120 255 150 225
Line -7500403 true 150 225 180 255
Line -7500403 true 120 165 150 135
Line -7500403 true 120 75 150 45
Line -7500403 true 150 135 180 165
Line -7500403 true 150 45 180 75

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

van
false
0
Polygon -7500403 true true 317 195 281 242 270 195 257 150 277 206 230 121 199 95 186 78 137 75 137 165 47 165 17 165 17 180 17 240 317 240 317 195
Circle -16777216 true false 187 185 74
Circle -16777216 true false 38 186 76
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -1 true false 46 197 58
Circle -1 true false 199 198 50
Circle -16777216 true false 206 204 38
Circle -6459832 true false 142 100 32
Circle -6459832 true false 85 115 32
Rectangle -7500403 true true 16 81 134 161
Rectangle -16777216 true false 27 90 117 141
Circle -16777216 true false 53 203 44
Line -16777216 false 143 230 142 143
Rectangle -1 true false 6 205 23 229
Rectangle -1 true false 14 152 202 160

van side
false
0
Polygon -7500403 true true 26 147 18 125 36 61 161 61 177 67 195 90 242 97 262 110 273 129 260 149
Circle -16777216 true false 43 123 42
Circle -16777216 true false 194 124 42
Polygon -16777216 true false 45 68 37 95 183 96 169 69
Line -7500403 true 62 65 62 103
Line -7500403 true 115 68 120 100
Polygon -1 true false 271 127 258 126 257 114 261 109
Rectangle -16777216 true false 19 131 27 142

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

wind
true
0
Rectangle -7500403 true true 120 150 195 150
Rectangle -7500403 true true 105 135 195 150

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.3
@#$#@#$#@
setup add-cloud add-cloud add-cloud repeat 800 [ go ]
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
