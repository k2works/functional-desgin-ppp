(ns abstract-factory.shape-factory
  "Abstract Factory パターン - ShapeFactory インターフェース

   図形を生成するファクトリの抽象インターフェースを定義します。")

;; =============================================================================
;; Abstract Factory インターフェース（マルチメソッド）
;; =============================================================================

(defmulti make-shape
  "図形を生成する"
  (fn [factory _type & _args] (::type factory)))
