
(ns respo.app.comp.svg-example
  (:require [respo.macros
             :refer
             [defcomp
              div
              input
              span
              button
              <>
              action->
              mutation->
              svg
              path
              line
              g
              rect
              svg-list->
              text]]
            [hsl.core :refer [hsl]]
            [respo.comp.space :refer [=<]]
            [respo.comp.inspect :refer [comp-inspect]]
            [respo.util.format :refer [path-data]]
            [respo.app.style.widget :as widget]))

(defcomp
 comp-svg-example
 ()
 (div
  {:style {:padding 16}}
  (div {} (<> "SVG Demo" {}))
  (svg
   {:width 200, :height 200}
   (g
    {:fill "red"}
    (rect
     {:width 40,
      :height 40,
      :fill (hsl 200 80 70),
      :on-click (fn [e d! m!] (println "blue"))})
    (line {:x1 40, :y1 40, :x2 80, :y2 80, :stroke (hsl 180 80 70), :stroke-width 6})
    (rect
     {:x 80,
      :y 80,
      :width 40,
      :height 40,
      :fill (hsl 40 80 70),
      :on-click (fn [e d! m!] (println "orange"))}))
   (svg-list->
    {}
    [[1 (text {:x 100, :y 40, :fill "blue", :innerHTML "Content 1"})]
     [2 (text {:x 100, :y 60, :innerHTML "Content 2"})]])
   (path
    {:d (path-data :M 20 120 :L 40 200 :c 0 -80 40 -40 40 0),
     :stroke "red",
     :strokeWidth 1,
     :fill (hsl 200 80 80)}))))
