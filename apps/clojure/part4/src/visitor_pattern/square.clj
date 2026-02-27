(ns visitor-pattern.square
  "Visitor パターン - Square

   正方形の図形を定義します。"
  (:require [visitor-pattern.shape :as shape]))

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
