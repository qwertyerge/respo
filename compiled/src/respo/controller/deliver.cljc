
(ns respo.controller.deliver
  (:require [respo.controller.resolver :refer [find-event-target
                                               get-markup-at]]
            [respo.util.detect :refer [component? element?]]))

(defn all-component-coords [markup]
  (if (component? markup)
    (cons (:coord markup) (all-component-coords (:tree markup)))
    (->>
      (:children markup)
      (map (fn [child-entry] (all-component-coords (val child-entry))))
      (apply concat))))

(defn purify-states [new-states old-states all-coords]
  (if (= (count old-states) 0)
    new-states
    (let [first-entry (first old-states)]
      (recur
        (if (some
              (fn [component-coord]
                (= component-coord (key first-entry)))
              all-coords)
          (assoc new-states (key first-entry) (val first-entry))
          new-states)
        (rest old-states)
        all-coords))))

(defn gc-states [states element]
  (comment println "states GC:" (pr-str states))
  (let [all-coords (distinct (all-component-coords element))
        new-states (purify-states {} states all-coords)]
    (comment println (pr-str all-coords))
    new-states))

(defn build-deliver-event [element-ref dispatch]
  (fn [coord event-name simple-event]
    (let [target-element (find-event-target
                           @element-ref
                           coord
                           event-name)
          target-listener (get (:event target-element) event-name)]
      (if (some? target-listener)
        (do
          (comment println "listener found:" coord event-name)
          (target-listener simple-event dispatch))
        (comment println "found no listener:" coord event-name)))))

(defonce global-mutate-methods (atom {}))

(defn mutate-factory [global-element global-states]
  (fn [coord]
    (if (contains? @global-mutate-methods coord)
      (get @global-mutate-methods coord)
      (let [method (fn [& state-args]
                     (let [component (get-markup-at
                                       @global-element
                                       (subvec
                                         coord
                                         0
                                         (- (count coord) 1)))
                           init-state (:init-state component)
                           update-state (:update-state component)
                           old-state (if
                                       (contains? @global-states coord)
                                       (get @global-states coord)
                                       (apply
                                         init-state
                                         (:args component)))
                           new-state (apply
                                       update-state
                                       (cons old-state state-args))
                           clean-states (gc-states
                                          @global-states
                                          @global-element)]
                       (comment
                         println
                         "compare states:"
                         (pr-str @global-states)
                         (pr-str old-state)
                         (pr-str new-state))
                       (swap!
                         global-states
                         assoc-in
                         (conj coord 'data)
                         new-state)))]
        (swap! global-mutate-methods assoc coord method)
        method))))