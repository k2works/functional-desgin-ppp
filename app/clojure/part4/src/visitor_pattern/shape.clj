(ns visitor-pattern.shape
  "Visitor パターン - Shape インターフェース

   図形の基本インターフェースを定義します。
   translate と scale 操作をサポートします。")

;; =============================================================================
;; Shape インターフェース（マルチメソッド）
;; =============================================================================

(defmulti translate
  "図形を移動する"
  (fn [shape _dx _dy] (::type shape)))

(defmulti scale
  "図形を拡大/縮小する"
  (fn [shape _factor] (::type shape)))
