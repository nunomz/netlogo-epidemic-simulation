;;; Extended model of AVI model for social propagation issues
;;; Concepts: Agent, virus, interaction, role, environment, social network
;;;

turtles-own           ;; properties of agents;;
[
  infetado?           ;; if true, the agent is infectious, role feature
  resistente?          ;; if true, the agent can't be infected, role feature
  exposto?            ;; if true, the agent is exposed, role feature
  recuperado?          ;; if true, the agent is recovered, role feature
  período-recuperação-vírus   ;; number of ticks since this agent's last virus check, i.e., the minimum recovered period of agents
  virus?              ;; whether the agent carry the H1N1 virus
]


to configurar
  __limpar-tudo-e-reiniciar-ticks
  configurar-agentes        ;; setup of agents
  rede-JGN         ;; setup of social network
  configurar-terreno   ;; setup of environment
  gráfico-grau-médio ;; chart plot setup
  gráfico-distribuição-grau  ;; chart plot setup
  gráfico-status-vírus   ;; chart plot setup
end

to iniciar-virus
    ask n-of initial-outbreak-size turtles
    [ play-infected ]
end

to  configurar-terreno ;; environment setup, comprised of grids.
  ask patches
    [ set pcolor white ]
end

to configurar-agentes       ;; agents setup;;
  set-default-shape turtles "pessoa"
  crt number-of-agents
    [
    ;; Make agents not too close to each others.
    setxy (random-xcor * 0.95) (random-ycor * 0.95)
    set color green
    play-susceptible
    set período-recuperação-vírus random virus-check-frequency
    ]

end

;how  does the JGN social network danymically grow?
;construct the network


to go
 if ( ticks > simulation-num )
   [stop]
  ask turtles
  [
     set período-recuperação-vírus período-recuperação-vírus + 1
     if período-recuperação-vírus >= virus-check-frequency
       [ set período-recuperação-vírus 0 ]
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
      if count meus-links > 0
      [
      ask one-of vizinhos-com-link
        [
          ;; interaction
          if not recuperado? and random-float 100 < exposed-chance
            [ play-exposed ]
         ]
      ]
    ]
end


to do-virus-checks
  ask turtles with [infected? and período-recuperação-vírus = 0]
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
  set infetado? false
  set exposto? true
  set recuperado? false
  set virus? true
  set período-recuperação-vírus random  virus-check-frequency
  set color blue
end


to play-infected    ;; agent plays the infected role
  set infetado? true
  set exposto? false
  set recuperado? false
  set virus? true
  set color red
end

to play-susceptible ;; agent plays the susceptible role
  set infetado? false
  set exposto? false
  set recuperado? false
   set virus? false
  set color green
end

to play-recovered  ;; agent plays the recovered role
  set infetado? false
  set exposto? false
  set recuperado? true
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
      if count meus-links < z*
      [
      let choice (one-of (other turtles with [not link-neighbor? myself]))


      if (choice != nimguem)  [ create-link-with choice [ set color gray]]
      ]
       set add_num_links_1 add_num_links_1 + 1
    ]
   ]
  ;; some new links
  let nm 0
  ask turtles
  [
    set nm nm + (count meus-links) * (count meus-links - 1)
  ]
  set nm nm / 2          ;;; nm= 1/2 * links (links - 1)
  let add_num_links_2 0
  while [ add_num_links_2 < nm * r1 ]
    [
  ask one-of turtles
    [
      let agent_a self
      if count meus-links > 0
    [
      ask one-of vizinhos-com-link
      [
        let agent_b self
      if count meus-links < z*
      [
        ask agent_a
        [
          ask one-of vizinhos-com-link
          [
            if count meus-links < z* and (not link-neighbor? agent_b) and agent_b != self
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
       if (count meus-links > 0)
       [
       ask one-of meus-links [ die ]
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
    set degree_sum degree_sum + count meus-links
   ]
  plot ( degree_sum / count turtles)
end


to degree-distribution-plot            ;;; degree distribution of the JGN social network
   set-current-plot "Degree-distribution"
  set-current-plot-pen "agent-percentage"
  clear-plot
  let max-degree 1
  ask max-one-of turtles [count meus-links]
  [
    set max-degree count meus-links
  ]
   let current_plot_degree 0
  repeat max-degree + 1
  [
    plotxy current_plot_degree    ( count turtles with [ (count meus-links) = current_plot_degree ]/ (count turtles) ) * 100
    set current_plot_degree  current_plot_degree + 1
  ]
end


to virus-status-plot                    ;;; the chart for the status of H1N1 virus spread in the artificial society
  set-current-plot "H1N1-spread Status"
  set-current-plot-pen "susceptible"
  plot (count turtles with [not infetado? and not recuperado? and not exposto?]) / (count turtles) * 100
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