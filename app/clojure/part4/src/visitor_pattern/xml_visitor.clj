(ns visitor-pattern.xml-visitor
  "Visitor パターン - XML Visitor

   図形を XML 形式に変換する Visitor です。"
  (:require [visitor-pattern.shape :as shape]
            [visitor-pattern.circle :as circle]
            [visitor-pattern.square :as square]
            [visitor-pattern.rectangle :as rectangle]))

;; =============================================================================
;; XML Visitor インターフェース
;; =============================================================================

(defmulti to-xml
  "図形を XML 文字列に変換"
  ::shape/type)

;; =============================================================================
;; 各図形の XML 変換
;; =============================================================================

(defmethod to-xml ::circle/circle [circle]
  (let [{:keys [::circle/center ::circle/radius]} circle
        [x y] center]
    (format "<circle><center x=\"%s\" y=\"%s\"/><radius>%s</radius></circle>"
            x y radius)))

(defmethod to-xml ::square/square [square]
  (let [{:keys [::square/top-left ::square/side]} square
        [x y] top-left]
    (format "<square><topLeft x=\"%s\" y=\"%s\"/><side>%s</side></square>"
            x y side)))

(defmethod to-xml ::rectangle/rectangle [rect]
  (let [{:keys [::rectangle/top-left ::rectangle/width ::rectangle/height]} rect
        [x y] top-left]
    (format "<rectangle><topLeft x=\"%s\" y=\"%s\"/><width>%s</width><height>%s</height></rectangle>"
            x y width height)))

;; =============================================================================
;; 複数図形の XML 変換
;; =============================================================================

(defn shapes-to-xml
  "複数の図形を XML ドキュメントに変換"
  [shapes]
  (str "<shapes>" (apply str (map to-xml shapes)) "</shapes>"))
