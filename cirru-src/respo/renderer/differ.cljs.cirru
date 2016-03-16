
ns respo.renderer.differ $ :require $ [] clojure.string :as string

declare find-element-diffs

defn sorted-rest (map-x)
  into (sorted-map)
    rest map-x

defn find-children-diffs
  acc n-coord index old-children new-children
  -- .log js/console "|diff children:" acc n-coord index old-children new-children
  cond
    (and (= 0 $ count old-children) (= 0 $ count new-children)) acc

    (and (= 0 $ count old-children) (> (count new-children) (, 0)))
      recur
        conj acc $ let
          (entry $ first new-children)
            item $ val entry
          [] :append n-coord item

        , n-coord
        inc index
        , old-children
        sorted-rest new-children

    (and (> (count old-children) (, 0)) (= 0 $ count new-children))
      recur
        conj acc $ let
          (entry $ first old-children)
            item $ val entry
          [] :rm $ conj n-coord index

        , n-coord index
        sorted-rest old-children
        , new-children

    :else $ let
      (first-old-entry $ first old-children)
        first-new-entry $ first new-children
        old-follows $ sorted-rest old-children
        new-follows $ sorted-rest new-children
      case
        compare (key first-old-entry)
          key first-new-entry
        -1 $ let
          (acc-after-cursor $ conj acc $ [] :rm $ conj n-coord index)
          recur acc-after-cursor n-coord index old-follows new-children

        1 $ let
          (acc-after-cursor $ conj acc $ [] :add (conj n-coord index) (val first-new-entry))

          recur acc-after-cursor n-coord (inc index)
            , old-children new-follows

        let
          (acc-after-cursor $ find-element-diffs acc (conj n-coord index) (val first-old-entry) (val first-new-entry))

          recur acc-after-cursor n-coord (inc index)
            , old-follows new-follows

defn find-style-diffs
  acc coord old-style new-style
  cond
    (and (= 0 $ count old-style) (= 0 $ count new-style)) acc

    (and (= 0 $ count old-style) (> (count new-style) (, 0)))
      let
        (entry $ first new-style)
          follows $ sorted-rest new-style
        recur
          conj acc $ [] :add-style coord entry
          , coord old-style follows

    (and (> (count old-style) (, 0)) (= 0 $ count new-style))
      let
        (entry $ first old-style)
          follows $ sorted-rest old-style
        recur
          conj acc $ [] :rm-style coord $ key old-style
          , coord follows new-style

    :else $ let
      (old-entry $ first old-style)
        new-entry $ first new-style
        old-follows $ sorted-rest old-style
        new-follows $ sorted-rest new-style
      case
        compare (key old-entry)
          key new-entry
        -1 $ recur
          conj acc $ [] :rm-style coord $ key old-entry
          , coord old-follows new-style
        1 $ recur
          conj acc $ [] :add-style coord new-entry
          , coord old-style new-follows
        recur
          if
            = (val old-entry)
              val new-entry
            , acc
            conj acc $ [] :replace-style coord new-entry

          , coord old-follows new-follows

defn find-props-diffs
  acc coord old-props new-props
  -- .log js/console "|find props:" acc coord old-props new-props (count old-props)
    count new-props
  cond
    (and (= 0 $ count old-props) (= 0 $ count new-props)) acc

    (and (= 0 $ count old-props) (> (count new-props) (, 0)))
      recur
        conj acc $ [] :add-prop coord $ first new-props
        , coord old-props
        sorted-rest new-props

    (and (> (count old-props) (, 0)) (= 0 $ count new-props))
      recur
        conj acc $ [] :rm-prop coord $ key $ first old-props
        , coord
        sorted-rest old-props
        , new-props

    :else $ let
      (old-entry $ first old-props)
        new-entry $ first new-props
        ([] old-k old-v) (first old-props)
        ([] new-k new-v) (first new-props)
        old-follows $ sorted-rest old-props
        new-follows $ sorted-rest new-props

      -- .log js/console old-k new-k old-v new-v
      case (compare old-k new-k)
        -1 $ recur
          conj acc $ [] :rm-prop coord old-k
          , coord old-follows new-props
        1 $ recur
          conj acc $ [] :add-prop coord new-entry
          , coord old-props new-follows
        recur
          if (= old-v new-v)
            , acc
            if (= new-k :style)
              find-style-diffs acc coord old-v new-v
              conj acc $ [] :replace-prop coord new-entry

          , coord old-follows new-follows

defn find-events-diffs
  acc coord old-events new-events
  -- .log js/console "|compare events:" (pr-str old-events)
    pr-str new-events
  cond
    (and (= (count old-events) (, 0)) (= (count new-events) (, 0))) acc

    (and (= (count old-events) (, 0)) (> (count new-events) (, 0)))
      recur
        conj acc $ [] :add-event coord $ first new-events
        , coord old-events
        rest new-events

    (and (> (count old-events) (, 0)) (= (count new-events) (, 0)))
      recur
        conj acc $ [] :rm-event coord $ first old-events
        , coord
        rest old-events
        , new-events

    :else $ case
      compare (first old-events)
        first new-events
      -1 $ recur
        conj acc $ [] :rm-event coord $ first old-events
        , coord
        rest old-events
        , new-events
      1 $ recur
        conj acc $ [] :add-event coord $ first new-events
        , coord old-events
        rest new-events
      recur acc coord (rest old-events)
        rest new-events

defn purify-children (children-map)
  ->> children-map
    filter $ fn (entry)
      some? $ val entry
    into $ sorted-map

defn find-element-diffs
  acc n-coord old-tree new-tree
  -- .log js/console "|element diffing:" acc n-coord old-tree new-tree
  let
    (old-coord $ :coord old-tree)
      new-coord $ :coord new-tree
      old-children $ :children old-tree
      new-children $ :children new-tree
    if (not= old-coord new-coord)
      throw $ js/Error. $ str "|coord dismatched:" old-coord new-coord
      if
        not= (:name old-tree)
          :name new-tree
        conj acc $ [] :replace n-coord new-tree
        let
          (acc-after-props $ find-props-diffs acc n-coord (:props old-tree) (:props new-tree))
            acc-after-events $ find-events-diffs acc-after-props n-coord
              sort $ keys $ :events old-tree
              sort $ keys $ :events new-tree

          -- .log js/console "|after props:" acc-after-props
          find-children-diffs acc-after-events n-coord 0 (purify-children old-children)
            purify-children new-children
