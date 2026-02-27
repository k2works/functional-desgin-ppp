(ns composite-pattern.circle
  "Composite パターン - Circle (Leaf)

   円形状の実装です。Composite パターンにおける Leaf に相当します。"
  (:require [clojure.spec.alpha :as s]
            [composite-pattern.shape :as shape]))

(s/def ::center (s/tuple number? number?))
(s/def ::radius number?)
(s/def ::circle (s/keys :req [::shape/type ::radius ::center]))

(defn make-circle
  "円を作成する"
  [center radius]
  {:post [(s/valid? ::circle %)]}
  {::shape/type ::circle
   ::center center
   ::radius radius})

(defmethod shape/translate ::circle [circle dx dy]
  {:pre [(s/valid? ::circle circle)
         (number? dx) (number? dy)]
   :post [(s/valid? ::circle %)]}
  (let [[x y] (::center circle)]
    (assoc circle ::center [(+ x dx) (+ y dy)])))

(defmethod shape/scale ::circle [circle factor]
  {:pre [(s/valid? ::circle circle)
         (number? factor)]
   :post [(s/valid? ::circle %)]}
  (let [radius (::radius circle)]
    (assoc circle ::radius (* radius factor))))
