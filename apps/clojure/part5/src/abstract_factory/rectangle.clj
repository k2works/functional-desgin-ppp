(ns abstract-factory.rectangle
  "Abstract Factory パターン - Rectangle

   長方形の図形を定義します。"
  (:require [abstract-factory.shape :as shape]))

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

(defmethod shape/to-string ::rectangle [rect]
  (let [[x y] (::top-left rect)
        width (::width rect)
        height (::height rect)]
    (str "Rectangle top-left: [" x ", " y "] width: " width " height: " height)))
