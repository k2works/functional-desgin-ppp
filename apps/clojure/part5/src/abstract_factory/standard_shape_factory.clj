(ns abstract-factory.standard-shape-factory
  "Abstract Factory パターン - StandardShapeFactory

   標準的な図形を生成するファクトリの実装です。"
  (:require [abstract-factory.shape-factory :as factory]
            [abstract-factory.circle :as circle]
            [abstract-factory.square :as square]
            [abstract-factory.rectangle :as rectangle]))

;; =============================================================================
;; StandardShapeFactory の定義
;; =============================================================================

(defn make
  "標準図形ファクトリを作成"
  []
  {::factory/type ::standard-factory})

(defmethod factory/make-shape ::standard-factory
  [_factory type & args]
  (case type
    :circle (apply circle/make args)
    :square (apply square/make args)
    :rectangle (apply rectangle/make args)
    (throw (ex-info (str "Unknown shape type: " type) {:type type}))))
