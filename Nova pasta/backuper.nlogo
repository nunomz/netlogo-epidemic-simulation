extensions [ sound ]

globals [ num_mortos show-contact_links?]

breed [ populacao pessoa]

populacao-own [ ; propriedades das pessoas
  ;idade
  infetado?
  ;imune? IMPLEMENTAR
  exposto?
  recuperado?
  virus?
  quarentena?
  dias-desde-recuperacao
  dias-de-quarentena
]

patches-own [ predio? dias ]

to iniciar
  clear-all
  preparar-terreno
  instalar-populacao
  set show-contact_links? true
  reset-ticks
end

to  preparar-terreno ;criar paredes com base na percentagem-terreno
  ask patches [set predio? false set pcolor 9.5]
  ask n-of (((100 - percentagem-terreno) / 100) * (count patches)) patches with [any? other populacao-here = false]  [
    set predio? true
    set pcolor 2.5
  ]
end

to instalar-populacao
;  ask n-of 1 patches with [pcolor = 9.5] [
;    sprout populacao-inicial [
;      ;set xcor random-pxcor
;      ;set ycor random-pycor
;      while [ ([pcolor] of patch xcor ycor = grey - 2.5 ) or (any? other populacao-here)] [ set xcor random-pxcor set ycor random-pycor]
;      set shape  "person"
;      set color green
;      set num_mortos 0
;      play-suscetivel
;      set xcor random max-pxcor * one-of [ 1 -1]
;      set ycor random max-pycor * one-of [ 1 -1]
;      set heading one-of [0 90 180 270]
;    ]
;  ]
  create-populacao populacao-inicial [
    set xcor random-pxcor
    set ycor random-pycor
    ;while [ ([pcolor] of patch xcor ycor = 2.5 ) or (any? other populacao-here)] [ set xcor random-pxcor set ycor random-pycor]
    ;while (patch-here with [predio? = true]) [ set xcor random-pxcor set ycor random-pycor]
    ;while [[pcolor] of patch-here = 2.5][ set xcor random-pxcor set ycor random-pycor]
    while [ ([predio?] of patch xcor ycor != false )] [ set xcor random-pxcor set ycor random-pycor]
    set shape  "person"
    set color green
    set num_mortos 0
    play-suscetivel
    set xcor random max-pxcor * one-of [ 1 -1]
    set ycor random max-pycor * one-of [ 1 -1]
    set heading one-of [0 90 180 270]
  ]
    ;set virus-recuperado-period random virus-check-frequency

end

to instalar-virus
  ask n-of ((percentagem-inicial-infetados / 100) * count populacao) populacao [
    play-exposto
  ]
end

to simular
;  ask populacao [
;    set virus-recuperado-period virus-recuperado-period + 1
;    if virus-recuperado-period >= virus-check-frequency
;       [ set virus-recuperado-period 0 ]
;  ]

  ;; IMUNIDADE
  ask populacao with [recuperado?]
  [
    if dias-desde-recuperacao >= periodo-imunidade [ play-suscetivel ]
    set dias-desde-recuperacao dias-desde-recuperacao + 1
  ]
  ask populacao with [infetado?]
  [
    if random 100 < prob-quarentena [ set quarentena? true]
  ]
  ask populacao with [quarentena? = true]
  [
    ifelse dias-de-quarentena >= periodo-quarentena
    [
      set quarentena? false
      play-suscetivel

    ][
      play-quarentena
    ]
    set dias-desde-recuperacao dias-desde-recuperacao + 1
  ]
  criar-links
  interagir-agentes
  virus-check
  movimentar-agentes
  tick
end


to movimentar-agentes
  ask populacao [
    if (any? neighbors with [pcolor = 9.5]) [
      move-to one-of neighbors
    ]
  ]
end

;to alterar-mundo
;  if (mouse-down?) [
;    ifelse (any? turtles with [ distancexy mouse-xcor mouse-ycor < 1]) [
;     let create-populacao one-of turtles with [ distancexy mouse-xcor mouse-ycor < 1]
;
;     output-write "Pessoa: "
;
;      while [mouse-down?] [
;        ask create-populacao [set xcor mouse-xcor set ycor mouse-ycor]
;      ]
;    ]
;    [
;      ask  patch mouse-xcor mouse-ycor [
;        ifelse (terreno?)[
;        set pcolor 9.5
;        ]
;        [
;        set pcolor gray - 2.5
;        ]
;      ]
;    ]
;  ]
;end

; links/interaccao entre agentes

to criar-links
  ask populacao with [ exposto? = true] [
    if (any? populacao with [exposto? = false and distance myself < raio_influencia]) [
      create-links-with other populacao with [exposto? = false and distance myself < raio_influencia] [
        set label "contacto"
        set color black
      ]
    ]
  ]
end

to ver-relacoes
  ;ask links with [label = "contacto"] [
  ifelse (ver-contactos) [
    ask links with [label = "contacto"] [set hidden? false]
    ]
  [
    ask links with [label = "contacto"] [set hidden? true]
  ]
  ;]
end

; transmissao entre agentes

to interagir-agentes
  ask populacao with [virus?]
    [
      if count my-links > 0
      [
      ask link-neighbors
        [
          ;; interaction
          if not recuperado? and random-float 100 < prob-exposicao
            [ play-exposto ]
         ]
      ]
      ;ask n-of ((taxa-mortalidade / 100) * count populacao with [infetado?]) populacao with [infetado?] [ play-morto ]
    ]
end


to virus-check
  ask populacao with [infetado?]
  [
    if random 100 < prob-recuperacao
    [
      play-recuperado
    ]
    if random 100 < taxa-mortalidade
    [
      play-morto
    ]
  ]
  ask populacao with [exposto?]
  [
    if random 100 < prob-infeccao
    [
      play-infetado
    ]
  ]
end

; Quarentena

to play-quarentena ;while not at gray patch, move to gray patch
  ask populacao with [quarentena? = true and pcolor = white] [
    let target-patch min-one-of (patches in-radius 25 with [pcolor = 2.5]) [distance myself]
    if target-patch != nobody  [
      move-to target-patch
    ]
  ]
end

; Roles

to play-morto
  set num_mortos num_mortos + 1
  die
end

to play-exposto      ;; agent plays the exposto role
  set infetado? false
  set exposto? true
  set recuperado? false
  set virus? true
  ;set virus-recovered-period random  virus-check-frequency
  set color blue
end


to play-infetado    ;; agent plays the infetado role
  set infetado? true
  set exposto? false
  set recuperado? false
  set virus? true
  set color red
end

to play-suscetivel ;; agent plays the suscetivel role
  set infetado? false
  set exposto? false
  set recuperado? false
  set virus? false
  set color green
end

to play-recuperado  ;; agent plays the recuperado role
  set infetado? false
  set exposto? false
  set recuperado? true
  set virus? false
  set color gray
  ask my-links [die]
end

; Botão de

to visible-links
  ask links with [label = "contacto"] [ set hidden? not show-contact_links? ]
end

; this is called by a button Show-hide-switch
to Show-hide-switch
  set show-contact_links? (not show-contact_links?)
  visible-links
  ; or call display if necessary
end


; Guardar

to Guardar
  if (file-exists? "Terreno.txt") [file-delete "Terreno.txt"]
  if (file-exists? "populacao.txt") [file-delete "populacao.txt"]
  file-open "Terreno.txt"
  ask patches [
    file-write pxcor
    file-write pycor
    file-write pcolor
  ]
  file-close

  file-open "populacao.txt"
  file-write populacao-inicial
  ask populacao [
    file-write who
    file-write xcor
    file-write ycor
    file-write heading
    file-write shape
    file-write color
  ]
  file-close
  sound:play-note "Applause" 60 64 2
  sound:play-note "Goblins" 30 20 1
  sound:play-note "Bird Tweet" 59 20 2
  sound:play-drum "Hand Clap" 64
  user-message "Guardado com sucesso"
end

to Repor
  ifelse (file-exists? "Terreno.txt" and file-exists? "populacao.txt")
  [
    clear-all
    file-open "Terreno.txt"
    while [not file-at-end?] [
      ask patch file-read file-read [set pcolor file-read]
    ]
    file-close

    file-open "populacao.txt"
    create-populacao file-read [
     while [not file-at-end?] [
        ask pessoa file-read[
          set xcor file-read
          set ycor file-read
          set heading file-read
          set shape file-read
          set color file-read
        ]
    ]
    ]
    file-close
  ]
  [
    user-message "Impossivel recuperar o mundo!!!"
  ]
  sound:play-note "Telephone Ring" 60 64 2
  sound:play-note "Sci-fi" 10 30 2
  sound:play-drum "Maracas" 64
  wait 2
  sound:play-note "Helicopter" 40 50 2.5
  sound:play-note "Sci-fi" 10 10 3
end
;
@#$#@#$#@
GRAPHICS-WINDOW
266
94
962
724
-1
-1
16.8
1
10
1
1
1
0
0
0
1
-20
20
-18
18
1
1
1
Dias
30.0

BUTTON
12
33
82
66
NIL
iniciar\n
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
85
33
163
66
NIL
simular\n
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
10
212
239
245
percentagem-inicial-infetados
percentagem-inicial-infetados
0
100
23.0
1
1
%
HORIZONTAL

SLIDER
10
174
239
207
populacao-inicial
populacao-inicial
0
1000
118.0
1
1
pessoas
HORIZONTAL

BUTTON
12
68
116
101
Instalar Vírus
if all? populacao [not virus?]\n[\ninstalar-virus\n]
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
287
44
423
89
Nº Suscetíveis (verde)
count populacao with [color = green]
17
1
11

MONITOR
690
44
838
89
Nº Infetados (vermelho)
count populacao with [infetado?]
17
1
11

SLIDER
9
252
242
285
percentagem-terreno
percentagem-terreno
0
100
77.0
1
1
%
HORIZONTAL

SLIDER
8
293
240
326
tempo-de-vida
tempo-de-vida
5
20
10.0
1
1
dias
HORIZONTAL

BUTTON
12
103
89
136
NIL
Guardar
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
92
103
157
136
NIL
Repor
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
6
615
187
648
probabilidade-transmissao
probabilidade-transmissao
1
100
54.0
1
1
%
HORIZONTAL

SLIDER
8
505
187
538
periodo-quarentena
periodo-quarentena
0
20
11.0
1
1
dias
HORIZONTAL

SLIDER
7
671
179
704
prob-recuperacao
prob-recuperacao
0
100
49.0
1
1
%
HORIZONTAL

SLIDER
8
729
180
762
prob-infeccao
prob-infeccao
0
100
51.0
1
1
%
HORIZONTAL

TEXTBOX
12
766
162
794
Probabilidade de Reinfecção (%)
10
0.0
1

SLIDER
8
786
180
819
prob-exposicao
prob-exposicao
0
100
50.0
1
1
%
HORIZONTAL

TEXTBOX
11
822
248
850
Probabilidade de exposição ao virus (%)
11
0.0
1

SLIDER
8
376
180
409
taxa-mortalidade
taxa-mortalidade
0
100
50.0
1
1
%
HORIZONTAL

MONITOR
839
44
934
89
Nº Mortos (rip)
num_mortos
17
1
11

MONITOR
425
43
541
88
Nº Expostos (azul)
count populacao with [exposto?]
17
1
11

MONITOR
544
44
687
89
Nº Imunes (cinza)
count populacao with [recuperado?]
17
1
11

SLIDER
8
334
185
367
periodo-imunidade
periodo-imunidade
0
60
5.0
1
1
dias
HORIZONTAL

SWITCH
469
727
602
760
ver-contactos
ver-contactos
0
1
-1000

SLIDER
10
449
182
482
prob-quarentena
prob-quarentena
0
100
100.0
1
1
%
HORIZONTAL

SLIDER
7
560
179
593
raio_influencia
raio_influencia
0
4
4.0
1
1
NIL
HORIZONTAL

BUTTON
637
727
826
760
Mostrar/Esconder Contactos
Show-hide-switch
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
13
10
163
29
Comandos
15
0.0
1

TEXTBOX
12
147
263
167
Configurações Basicas
15
0.0
1

TEXTBOX
11
426
196
464
Configurações avançadas
15
0.0
1

TEXTBOX
13
484
198
502
Probabilidade de Quarentena (%)
10
0.0
1

TEXTBOX
11
540
200
558
Periodo de Quarentena (1-20 dias)
10
0.0
1

TEXTBOX
12
594
162
612
Raio de transmissão(0-4 metro)
10
0.0
1

TEXTBOX
11
649
208
667
Probabilidade de Transmissão (%)
10
0.0
1

TEXTBOX
12
707
186
725
Probabilidade de Recuperação (%)
10
0.0
0

TEXTBOX
547
769
863
807
Definições de Visualização
15
0.0
1

TEXTBOX
542
16
785
54
Informação Pandemica
15
0.0
1

TEXTBOX
1173
56
1323
75
Evolução Gráfica
15
0.0
1

PLOT
1017
99
1426
298
Evolucao_SEIR
Tempo
%
0.0
100.0
0.0
100.0
true
true
"" ""
PENS
"Suscetivel" 1.0 0 -11085214 true "" "plot (count populacao with [not infetado? and not recuperado? and not exposto?]) / (count populacao) * 100"
"Infetados" 1.0 0 -2674135 true "" "plot (count populacao with [infetado?]) / (count populacao) * 100"
"Recuperados" 1.0 0 -7500403 true "" "plot (count populacao with [recuperado?]) / (count populacao) * 100"
"Expostos" 1.0 0 -13345367 true "" "plot (count populacao with [exposto?])/(count populacao) * 100"

TEXTBOX
1017
528
1167
546
Reinfetados\n
12
0.0
1

PLOT
1016
326
1425
521
Evolucao_mortes
Tempo
Numero
0.0
100.0
0.0
100.0
false
false
"" ""
PENS
"Mortes" 1.0 0 -955883 true "" "plot num_mortos"

PLOT
1016
544
1427
737
Media de retransmissão
Tempo
Media
0.0
100.0
0.0
100.0
false
false
"" ""
PENS
"Average degree" 1.0 0 -2674135 true "" "set-current-plot-pen \"Average degree\"\n  let degree_sum 0\n  ask turtles\n  [\n    set degree_sum degree_sum + count my-links\n   ]\n  plot ( degree_sum / count turtles)"

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
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
NetLogo 6.3.0
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
