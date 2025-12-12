(ns visitor-pattern.json-visitor
  "Visitor パターン - JSON Visitor

   図形を JSON 形式に変換する Visitor です。"
  (:require [visitor-pattern.shape :as shape]
            [visitor-pattern.circle :as circle]
            [visitor-pattern.square :as square]
            [visitor-pattern.rectangle :as rectangle]))

;; =============================================================================
;; JSON Visitor インターフェース
;; =============================================================================

(defmulti to-json
  "図形を JSON 文字列に変換"
  ::shape/type)

;; =============================================================================
;; 各図形の JSON 変換
;; =============================================================================

(defmethod to-json ::circle/circle [circle]
  (let [{:keys [::circle/center ::circle/radius]} circle
        [x y] center]
    (format "{\"type\":\"circle\",\"center\":[%s,%s],\"radius\":%s}" x y radius)))

(defmethod to-json ::square/square [square]
  (let [{:keys [::square/top-left ::square/side]} square
        [x y] top-left]
    (format "{\"type\":\"square\",\"topLeft\":[%s,%s],\"side\":%s}" x y side)))

(defmethod to-json ::rectangle/rectangle [rect]
  (let [{:keys [::rectangle/top-left ::rectangle/width ::rectangle/height]} rect
        [x y] top-left]
    (format "{\"type\":\"rectangle\",\"topLeft\":[%s,%s],\"width\":%s,\"height\":%s}"
            x y width height)))

;; =============================================================================
;; 複数図形の JSON 変換
;; =============================================================================

(defn shapes-to-json
  "複数の図形を JSON 配列に変換"
  [shapes]
  (str "[" (clojure.string/join "," (map to-json shapes)) "]"))
