
ns respo.html-test
  :require
    [] clojure.test :refer :all
    [] respo.alias :refer $ [] html head title script style meta' div link body
    [] respo.component.todolist :refer $ [] todolist-component
    [] respo.render.static-html :refer $ [] make-string make-html

def todolist-store $ atom
  []
    {} :text |101 :id 101
    {} :text |102 :id 102

deftest html-test
  let
      todo-demo $ todolist-component ({} :tasks @todolist-store)
    testing "|test generated HTML"
      is $ = (slurp "|examples/demo.html") (make-string todo-demo)

defn use-text (x)
  {} :attrs
    {} :innerHTML x

deftest simple-html-test
  let
      tree-demo $ html ({})
        head ({})
          title (use-text |Demo)
          link $ {}
            :attrs $ {}
              :rel |icon
              :type |image/png
          script (use-text "|{}")
        body ({})
          div
            {} :attrs $ {} :id |app
            div ({})

    testing "|test generated HTML"
      is $ = (slurp "|examples/simple.html") (make-html tree-demo)