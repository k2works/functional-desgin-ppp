(ns abstract-factory.square
  "Abstract Factory パターン - Square

   正方形の図形を定義します。"
  (:require [abstract-factory.shape :as shape]))

;; =============================================================================
;; Square の定義
;; =============================================================================

(defn make
  "正方形を作成"
  [top-left side]
  {::shape/type ::square
   ::top-left top-left
   ::side side})

(defmethod shape/translate ::square [square dx dy]
  (let [[x y] (::top-left square)]
    (assoc square ::top-left [(+ x dx) (+ y dy)])))

(defmethod shape/scale ::square [square factor]
  (let [side (::side square)]
    (assoc square ::side (* side factor))))

(defmethod shape/to-string ::square [square]
  (let [[x y] (::top-left square)
        side (::side square)]
    (str "Square top-left: [" x ", " y "] side: " side)))
