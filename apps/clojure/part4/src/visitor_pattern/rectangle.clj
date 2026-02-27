(ns visitor-pattern.rectangle
  "Visitor パターン - Rectangle

   長方形の図形を定義します。"
  (:require [visitor-pattern.shape :as shape]))

;; =============================================================================
;; Rectangle の定義
;; =============================================================================

(defn make
  "長方形を作成"
  [top-left width height]
  {::shape/type ::rectangle
   ::top-left top-left
   ::width width
   ::height height})

(defmethod shape/translate ::rectangle [rect dx dy]
  (let [[x y] (::top-left rect)]
    (assoc rect ::top-left [(+ x dx) (+ y dy)])))

(defmethod shape/scale ::rectangle [rect factor]
  (-> rect
      (update ::width * factor)
      (update ::height * factor)))
