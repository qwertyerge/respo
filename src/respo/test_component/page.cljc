
(ns respo.test-component.page
  (:require [respo.alias :refer [create-comp
                                 div
                                 html
                                 head body meta' link script style]]))

(defn render [store] (fn [state mutate] (div {})))

(def comp-page (create-comp :page render))