(ns abstract-factory.circle
  "Abstract Factory パターン - Circle

   円形の図形を定義します。"
  (:require [abstract-factory.shape :as shape]))

;; =============================================================================
;; Circle の定義
;; =============================================================================

(defn make
  "円を作成"
  [center radius]
  {::shape/type ::circle
   ::center center
   ::radius radius})

(defmethod shape/translate ::circle [circle dx dy]
  (let [[x y] (::center circle)]
    (assoc circle ::center [(+ x dx) (+ y dy)])))

(defmethod shape/scale ::circle [circle factor]
  (let [radius (::radius circle)]
    (assoc circle ::radius (* radius factor))))

(defmethod shape/to-string ::circle [circle]
  (let [[x y] (::center circle)
        radius (::radius circle)]
    (str "Circle center: [" x ", " y "] radius: " radius)))
