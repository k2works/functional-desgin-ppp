(ns composite-pattern.composite-shape
  "Composite パターン - CompositeShape (Composite)

   複合形状の実装です。複数の形状を含み、
   操作を含まれるすべての形状に委譲します。"
  (:require [clojure.spec.alpha :as s]
            [composite-pattern.shape :as shape]))

(s/def ::shapes (s/coll-of ::shape/shape-type))
(s/def ::composite-shape (s/keys :req [::shape/type ::shapes]))

(defn make
  "空の複合形状を作成する"
  []
  {:post [(s/valid? ::composite-shape %)]}
  {::shape/type ::composite-shape
   ::shapes []})

(defn add
  "複合形状に形状を追加する"
  [cs shape]
  {:pre [(s/valid? ::composite-shape cs)
         (s/valid? ::shape/shape-type shape)]
   :post [(s/valid? ::composite-shape %)]}
  (update cs ::shapes conj shape))

(defmethod shape/translate ::composite-shape [cs dx dy]
  {:pre [(s/valid? ::composite-shape cs)
         (number? dx) (number? dy)]
   :post [(s/valid? ::composite-shape %)]}
  (let [translated-shapes (mapv #(shape/translate % dx dy)
                                (::shapes cs))]
    (assoc cs ::shapes translated-shapes)))

(defmethod shape/scale ::composite-shape [cs factor]
  {:pre [(s/valid? ::composite-shape cs)
         (number? factor)]
   :post [(s/valid? ::composite-shape %)]}
  (let [scaled-shapes (mapv #(shape/scale % factor)
                            (::shapes cs))]
    (assoc cs ::shapes scaled-shapes)))
