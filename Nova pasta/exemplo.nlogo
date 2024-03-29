
;;; Extended model of AVI model for social propagation issues
;;; Concepts: Agent, virus, interaction, role, environment, social network
;;; 

turtles-own           ;; properties of agents;; 
[
  infected?           ;; if true, the agent is infectious, role feature
  resistant?          ;; if true, the agent can't be infected, role feature
  exposed?            ;; if true, the agent is exposed, role feature
  recovered?          ;; if true, the agent is recovered, role feature
  virus-recovered-period   ;; number of ticks since this agent's last virus check, i.e., the minimum recovered period of agents
  virus?              ;; whether the agent carry the H1N1 virus
]


to setup
  __clear-all-and-reset-ticks
  setup-agents        ;; setup of agents
  JGN-network         ;; setup of social network
  setup-environment   ;; setup of environment
  average-degree-plot ;; chart plot setup
  degree-distribution-plot  ;; chart plot setup
  virus-status-plot   ;; chart plot setup
end

to virus-initialization
    ask n-of initial-outbreak-size turtles
    [ play-infected ]
end

to  setup-environment ;; environment setup, comprised of grids.
  ask patches 
    [ set pcolor white ]
end

to setup-agents       ;; agents setup;;
  set-default-shape turtles "person"
  crt number-of-agents
    [
    ;; Make agents not too close to each others.
    setxy (random-xcor * 0.95) (random-ycor * 0.95)
    set color green
    play-susceptible
    set virus-recovered-period random virus-check-frequency
    ]

end

;how  does the JGN social network danymically grow? 
;construct the network


to go
 if ( ticks > simulation-num )
   [stop]
  ask turtles
  [
     set virus-recovered-period virus-recovered-period + 1
     if virus-recovered-period >= virus-check-frequency
       [ set virus-recovered-period 0 ]
  ]
  interaction-between-agents
  tick
  do-virus-checks
  JGN-network
  average-degree-plot
  degree-distribution-plot
  virus-status-plot
end



to interaction-between-agents   ;; Interaction;interactions between agents, especially between the infected agents and the susceptiple agents
 
  ask turtles with [infected?]
    [ 
      if count my-links > 0
      [
      ask one-of link-neighbors 
        [ 
          ;; interaction 
          if not recovered? and random-float 100 < exposed-chance 
            [ play-exposed ]
         ]     
      ]
    ]
end


to do-virus-checks
  ask turtles with [infected? and virus-recovered-period = 0]
  [
    if random 100 < recovery-chance
    [
         play-recovered 
    ]
  ]
  ask turtles with [exposed?]
    [
    if random-float 100 < virus-spread-chance
    [play-infected]
  ]
end

to play-exposed      ;; agent plays the exposed role
  set infected? false
  set exposed? true
  set recovered? false
  set virus? true
  set virus-recovered-period random  virus-check-frequency
  set color blue
end


to play-infected    ;; agent plays the infected role
  set infected? true
  set exposed? false
  set recovered? false
  set virus? true
  set color red
end

to play-susceptible ;; agent plays the susceptible role
  set infected? false
  set exposed? false
  set recovered? false
   set virus? false
  set color green
end

to play-recovered  ;; agent plays the recovered role
  set infected? false
  set exposed? false
  set recovered? true
   set virus? false
  set color gray
end


to JGN-network    ;; social network dynamically grows
  ;;; The details of this network references the work of the article "Emily M. Jin, Michelle Girvan and M. E. J. Newman, 
  ;;;  Structure of growing social networks, Physical review E. Volume 64, 046132, 2001."
  ;;; 
  
   let add_num_links_1  0
   let num-links  number-of-agents * (number-of-agents - 1) / 2  ;np=1/2 * N(N-1)
    while [add_num_links_1 < num-links * r0 ]
    [
    ask one-of turtles
    [
      if count my-links < z*
      [
      let choice (one-of (other turtles with [not link-neighbor? myself]))
 
         
      if (choice != nobody)  [ create-link-with choice [ set color gray]]
      ]
       set add_num_links_1 add_num_links_1 + 1
    ]
   ]
  ;; some new links
  let nm 0
  ask turtles
  [
    set nm nm + (count my-links) * (count my-links - 1)  
  ]
  set nm nm / 2          ;;; nm= 1/2 * links (links - 1)
  let add_num_links_2 0
  while [ add_num_links_2 < nm * r1 ]
    [
  ask one-of turtles
    [
      let agent_a self
      if count my-links > 0
    [
      ask one-of link-neighbors
      [
        let agent_b self
      if count my-links < z*
      [
        ask agent_a
        [
          ask one-of link-neighbors
          [
            if count my-links < z* and (not link-neighbor? agent_b) and agent_b != self
            [ 
              create-link-with agent_b [ set color gray]
             ]
          ]
        ]
      ]
      ]
    ]
      ]
       set  add_num_links_2  add_num_links_2 + 1
    ]
  
    ;; cancel some links  
      
    let num_cancel_links (count links ) / 2 * R
    let count_cancel_links 0
    while [ count_cancel_links < num_cancel_links]
    [
     ask one-of turtles
     [
       if (count my-links > 0)
       [
       ask one-of my-links [ die ]
       ]
     ]
      set count_cancel_links count_cancel_links + 1
    ]
    ;; make the network more prettier
    layout-spring turtles links 0.3 (world-width / (sqrt number-of-agents)) 1
end

to average-degree-plot             ;;;; the chart shows the average degree of the JGN network
    set-current-plot "Average_degree"
  set-current-plot-pen "Average degree"
  let degree_sum 0
  ask turtles
  [
    set degree_sum degree_sum + count my-links
   ]
  plot ( degree_sum / count turtles)
end


to degree-distribution-plot            ;;; degree distribution of the JGN social network
   set-current-plot "Degree-distribution" 
  set-current-plot-pen "agent-percentage"
  clear-plot
  let max-degree 1
  ask max-one-of turtles [count my-links]
  [
    set max-degree count my-links
  ]
   let current_plot_degree 0
  repeat max-degree + 1
  [
    plotxy current_plot_degree    ( count turtles with [ (count my-links) = current_plot_degree ]/ (count turtles) ) * 100
    set current_plot_degree  current_plot_degree + 1
  ]
end


to virus-status-plot                    ;;; the chart for the status of H1N1 virus spread in the artificial society
  set-current-plot "H1N1-spread Status"
  set-current-plot-pen "susceptible"
  plot (count turtles with [not infected? and not recovered? and not exposed?]) / (count turtles) * 100
  set-current-plot-pen "infected"
  plot (count turtles with [infected?]) / (count turtles) * 100
  set-current-plot-pen "recovered"
  plot (count turtles with [recovered?]) / (count turtles) * 100
  set-current-plot-pen "exposed"
  plot (count turtles with [exposed?])/(count turtles) * 100
  set-current-plot-pen "H1N1 virus"        ;;; This shows how many agents carry H1N1 virus
  plot (count turtles with [virus?]) / (count turtles) * 100
end

;;; @ author Mingsheng TANG
;;; @ College of Computer, National University of Defense Technology (NUDT)
;;; © copyright 2014.
@#$#@#$#@
GRAPHICS-WINDOW
741
11
1147
438
16
16
12.0
1
10
1
1
1
0
1
1
1
-16
16
-16
16
1
1
1
simulation ticks
30.0

SLIDER
173
241
375
274
virus-check-frequency
virus-check-frequency
1
100
50
1
1
ticks
HORIZONTAL

SLIDER
4
97
167
130
number-of-agents
number-of-agents
0
1000
250
1
1
NIL
HORIZONTAL

BUTTON
7
24
67
57
setup
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
86
23
154
56
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
1

SLIDER
3
135
167
168
r0
r0
0
0.005
5.0E-4
0.0001
1
NIL
HORIZONTAL

SLIDER
4
170
167
203
r1
r1
0
100
2
1
1
NIL
HORIZONTAL

SLIDER
3
205
168
238
R
R
0
0.1
0.0050
0.001
1
NIL
HORIZONTAL

SLIDER
1
241
169
274
Z*
Z*
0
50
5
1
1
NIL
HORIZONTAL

PLOT
18
282
375
488
Degree-distribution
degree
agent-percentage(%)
0.0
1.0
0.0
1.0
true
false
"" ""
PENS
"agent-percentage" 1.0 1 -5298144 true "" ""

SLIDER
175
168
375
201
exposed-chance
exposed-chance
0
100
50
1
1
%
HORIZONTAL

SLIDER
175
133
373
166
virus-spread-chance
virus-spread-chance
0
100
25
1
1
%
HORIZONTAL

SLIDER
174
205
374
238
recovery-chance
recovery-chance
0
100
30
1
1
%
HORIZONTAL

PLOT
395
201
722
452
H1N1-spread Status
time
%
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"susceptible" 1.0 0 -15040220 true "" ""
"infected" 1.0 0 -5298144 true "" ""
"recovered" 1.0 0 -11053225 true "" ""
"exposed" 1.0 0 -14730904 true "" ""
"H1N1 virus" 1.0 0 -1184463 true "" ""

INPUTBOX
173
62
373
126
initial-outbreak-size
2
1
0
Number

PLOT
395
13
722
192
Average_degree
Time
Degree
0.0
1.0
0.0
1.0
true
false
"" ""
PENS
"Average degree" 1.0 2 -16777216 true "" ""

BUTTON
174
24
318
57
virus-initialization
if all? turtles [not virus?]\n[\nvirus-initialization\n]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
5
61
166
94
simulation-num
simulation-num
0
5000
2000
1
1
NIL
HORIZONTAL

@#$#@#$#@
![NetLogo](http://ccl.northwestern.edu/netlogo/images/netlogo-title-new.jpg)

## WHAT IS IT?
AVI+ MODEL
The AVI+ model is an extended model of the AVI model, which is a general artifical soceity model for studying social propagation issues, e.g.,the spread of an infectious disease or information diffusion in the society.The core concepts of AVI model include Agent, Virus and Interaction. Besides three core concepts of AVI model, this extended AVI+ model includes other  concepts: Role, Rule and Environment (Social environment and Physical environment). Due to introducing more concepts, this AVI+ model can be widely applied. 

In the case, we will study the infectious H1N1 virus propagation with the AVI+ model. Meanwhile, the social network conforms to the JGN network, which is a growing and dynamic social network. This social network is based on some rules or assumptions: (1) each agent has a same limit number of social relationships, i.e., every node has the limited degree in the social network. (2) If two agents have connected with a same agent, these two agents possibly connect with each other. Meanwhile, the SEIR epidemiologic differential model is used to describe the spread of the infectious H1N1 virus. Considering the SEIR model, we could use the concept of role and the mechanism of dynamically playing roles to describe the states of the models. We have defined four roles: susceptible, exposed, infected and recovered, and agents can dynamically play these roles according to different situations. If an agent is not infected by the virus, this agent will play susceptible role. When a susceptible agent interacts with an infected agent to be infected to carry the H1N1 virus but cannot infect other agents, this agent will quit the susceptible role to play the exposed role. If an exposed agent can infect other agents, then this agent will quit the exposed role to play the infected role. If an infected agent is recovered to be health and does not carry the infectious H1N1 virus, then this agent will access to immunization and play the recovered role. We have defined several parameters for the social network and the spread of the H1N1 virus.


## HOW IT WORKS


Each tick, agents can interact with another agent who has social relationship with it. The infected agents also may interact with others, and they can infect the susceptible agents to carry the H1N1 virus.

If an infected agent interacts with an susceptible agent, the susceptible agent will play exposed role with the probability of "exposed-chance", which can be ajusted by users with the slider "exposed-chance". Each tick, an exposed agent may quit the exposed role to play infected role with the probability of "virus-spread-chance", which can also be adjusted by the slider "virus-spread-chance". If an infected is carried the H1N1 virus for "virus-check-frequency" ticks, it will participate the virus check and it may recover to play the recovered role with the probability of "recovery-chance". Meanwhile, this value of the probability can be adjusted by users with the slider "recovery-chance".

Let N is the nodes number of JGN social network, the upper limit links number (np) of this social network is N(N-1)/2, and existed links number is n_e=1/2∑zi (zi is the degree of node i ). The neighboured links number is n_m=1/2∑(zi-1)zi, and r = r0+r1m (m is the pair number of nodes which links with one another) is the speed of nodes link with others. And z* is the upper limit links number of each node. Rules of JGN social network is as follows.
In each tick, randomly choose np r0 pairs of nodes to link with one another. If the chose nodes have not connected with each other and both current links number of two nodes is less than z*, then connect these two nodes.

In each step, proportionate to zi(zi-1) randomly choose nmr1 nodes. For each node, randomly choose a pair of nodes from its neighbour nodes. If the pair of nodes have not connected with each other and links upper number of each node is less than z*, then connect this pair of nodes.

In each step, proportionate to zi randomly choose n_e* R nodes (R is a constant), and randomly choose one neighbour nodes of each these nodes to cancel the link between these two nodes. 

The values of parameters N, z*, r0, r1 and R can be adjusted by users with the sliders "number-of-agents", "Z*", "r0", "r1" and "R", respectively.

## HOW TO USE IT

This section could explain how to use the model, including a description of each of the items in the interface tab.
Press the button "setup" to setup agents, social network and environment.
Press the button "Go" to run the procedure.
The slider "simulation-num" controls the simulation time. When the ticks reached the simulation time, the procedure will stop. 
Users can press button "virus-initialization" to initialize the infected agents in the society.
Before press the button "virus-initialization", users should input a number in the box "initial-outbreak-size", and the number should be bigger than 0 and smaller than "number-of-agents". 
THe sliders "r0", "r1", "z*", "number-of-agents", "R", "virus-spread-chance", "exposed-chance", "recovery-chance", and "virus-check-frequency" are discussed in “How it Works” above. All these values can be adjusted before press the button "Go".

## THINGS TO NOTICE

Before press the button "setup", users should set values for all the sliders and the input box. Usually, users should press button "virus-initialization" after the average degree of the social network is bigger than z*.


## RELATED MODELS

Thie model is an extended model of the AVI model. The AVI model can be referenced by the URL:
http://ccl.northwestern.edu/netlogo/models/community/AVI


## CREDITS AND REFERENCES
The references about JGN social network:
1. M. J. Emily, G. Michelle, and M. E. J. Newman, Structure of growing social networks. Physical review E. 64, 046132, 2001.
2. M. E. J. Newman. Properties of highly clustered networks. Physical review E. 68, 026121, 2003.

## Copyright
&copy; College of Computer, National University of Defense Technology.
@ Author: Mingsheng TANG, tms110145@gamil.com
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
0
Rectangle -7500403 true true 151 225 180 285
Rectangle -7500403 true true 47 225 75 285
Rectangle -7500403 true true 15 75 210 225
Circle -7500403 true true 135 75 150
Circle -16777216 true false 165 76 116

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

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.1.0
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
