(ns abstract-factory.shape
  "Abstract Factory パターン - Shape インターフェース

   図形の共通インターフェースを定義します。")

;; =============================================================================
;; Shape インターフェース（マルチメソッド）
;; =============================================================================

(defmulti translate
  "図形を移動する"
  (fn [shape _dx _dy] (::type shape)))

(defmulti scale
  "図形を拡大/縮小する"
  (fn [shape _factor] (::type shape)))

(defmulti to-string
  "図形を文字列に変換する"
  (fn [shape] (::type shape)))
