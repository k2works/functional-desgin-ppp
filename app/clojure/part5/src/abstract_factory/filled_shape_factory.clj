(ns abstract-factory.filled-shape-factory
  "Abstract Factory パターン - FilledShapeFactory

   塗りつぶし付きの図形を生成するファクトリの実装です。"
  (:require [abstract-factory.shape-factory :as factory]
            [abstract-factory.circle :as circle]
            [abstract-factory.square :as square]
            [abstract-factory.rectangle :as rectangle]))

;; =============================================================================
;; FilledShapeFactory の定義
;; =============================================================================

(defn make
  "塗りつぶし付き図形ファクトリを作成"
  [fill-color]
  {::factory/type ::filled-factory
   ::fill-color fill-color})

(defn- add-fill
  "図形に塗りつぶし情報を追加"
  [shape fill-color]
  (assoc shape ::fill-color fill-color))

(defmethod factory/make-shape ::filled-factory
  [factory type & args]
  (let [fill-color (::fill-color factory)
        base-shape (case type
                     :circle (apply circle/make args)
                     :square (apply square/make args)
                     :rectangle (apply rectangle/make args)
                     (throw (ex-info (str "Unknown shape type: " type) {:type type})))]
    (add-fill base-shape fill-color)))
