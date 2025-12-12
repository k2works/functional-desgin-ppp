(ns visitor-pattern.perimeter-visitor
  "Visitor パターン - Perimeter Visitor

   図形の周囲長を計算する Visitor です。"
  (:require [visitor-pattern.shape :as shape]
            [visitor-pattern.circle :as circle]
            [visitor-pattern.square :as square]
            [visitor-pattern.rectangle :as rectangle]))

;; =============================================================================
;; Perimeter Visitor インターフェース
;; =============================================================================

(defmulti calculate-perimeter
  "図形の周囲長を計算"
  ::shape/type)

;; =============================================================================
;; 各図形の周囲長計算
;; =============================================================================

(defmethod calculate-perimeter ::circle/circle [circle]
  (let [radius (::circle/radius circle)]
    (* 2 Math/PI radius)))

(defmethod calculate-perimeter ::square/square [square]
  (let [side (::square/side square)]
    (* 4 side)))

(defmethod calculate-perimeter ::rectangle/rectangle [rect]
  (let [width (::rectangle/width rect)
        height (::rectangle/height rect)]
    (* 2 (+ width height))))

;; =============================================================================
;; 複数図形の合計周囲長
;; =============================================================================

(defn total-perimeter
  "複数の図形の合計周囲長を計算"
  [shapes]
  (reduce + (map calculate-perimeter shapes)))
