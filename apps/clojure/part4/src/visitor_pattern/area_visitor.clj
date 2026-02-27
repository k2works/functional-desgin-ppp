(ns visitor-pattern.area-visitor
  "Visitor パターン - Area Visitor

   図形の面積を計算する Visitor です。"
  (:require [visitor-pattern.shape :as shape]
            [visitor-pattern.circle :as circle]
            [visitor-pattern.square :as square]
            [visitor-pattern.rectangle :as rectangle]))

;; =============================================================================
;; Area Visitor インターフェース
;; =============================================================================

(defmulti calculate-area
  "図形の面積を計算"
  ::shape/type)

;; =============================================================================
;; 各図形の面積計算
;; =============================================================================

(defmethod calculate-area ::circle/circle [circle]
  (let [radius (::circle/radius circle)]
    (* Math/PI radius radius)))

(defmethod calculate-area ::square/square [square]
  (let [side (::square/side square)]
    (* side side)))

(defmethod calculate-area ::rectangle/rectangle [rect]
  (let [width (::rectangle/width rect)
        height (::rectangle/height rect)]
    (* width height)))

;; =============================================================================
;; 複数図形の合計面積
;; =============================================================================

(defn total-area
  "複数の図形の合計面積を計算"
  [shapes]
  (reduce + (map calculate-area shapes)))
