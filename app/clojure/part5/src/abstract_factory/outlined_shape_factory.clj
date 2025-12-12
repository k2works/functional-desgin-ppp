(ns abstract-factory.outlined-shape-factory
  "Abstract Factory パターン - OutlinedShapeFactory

   輪郭線付きの図形を生成するファクトリの実装です。"
  (:require [abstract-factory.shape-factory :as factory]
            [abstract-factory.circle :as circle]
            [abstract-factory.square :as square]
            [abstract-factory.rectangle :as rectangle]))

;; =============================================================================
;; OutlinedShapeFactory の定義
;; =============================================================================

(defn make
  "輪郭線付き図形ファクトリを作成"
  [outline-color outline-width]
  {::factory/type ::outlined-factory
   ::outline-color outline-color
   ::outline-width outline-width})

(defn- add-outline
  "図形に輪郭線情報を追加"
  [shape outline-color outline-width]
  (assoc shape
         ::outline-color outline-color
         ::outline-width outline-width))

(defmethod factory/make-shape ::outlined-factory
  [factory type & args]
  (let [outline-color (::outline-color factory)
        outline-width (::outline-width factory)
        base-shape (case type
                     :circle (apply circle/make args)
                     :square (apply square/make args)
                     :rectangle (apply rectangle/make args)
                     (throw (ex-info (str "Unknown shape type: " type) {:type type})))]
    (add-outline base-shape outline-color outline-width)))
