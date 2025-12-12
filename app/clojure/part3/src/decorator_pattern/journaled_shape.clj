(ns decorator-pattern.journaled-shape
  "Decorator パターン - JournaledShape

   形状オブジェクトに操作の履歴を記録する機能を追加する
   デコレータです。元の形状をラップし、全ての操作を
   ジャーナルに記録しながら元の形状に委譲します。"
  (:require [clojure.spec.alpha :as s]
            [composite-pattern.shape :as shape]))

(s/def ::journal-entry
  (s/or :translate (s/tuple #{:translate} number? number?)
        :scale (s/tuple #{:scale} number?)))
(s/def ::journal (s/coll-of ::journal-entry))
(s/def ::shape ::shape/shape-type)
(s/def ::journaled-shape (s/and
                          (s/keys :req [::shape/type
                                        ::journal
                                        ::shape])
                          #(= ::journal-shape
                              (::shape/type %))))

(defn make
  "形状をデコレートしてジャーナル機能を追加する"
  [shape]
  {:post [(s/valid? ::journaled-shape %)]}
  {::shape/type ::journal-shape
   ::journal []
   ::shape shape})

(defn get-journal
  "ジャーナル（操作履歴）を取得する"
  [journaled-shape]
  (::journal journaled-shape))

(defn get-shape
  "ラップされた形状を取得する"
  [journaled-shape]
  (::shape journaled-shape))

(defmethod shape/translate ::journal-shape [js dx dy]
  {:pre [(s/valid? ::journaled-shape js)
         (number? dx) (number? dy)]
   :post [(s/valid? ::journaled-shape %)]}
  (-> js
      (update ::journal conj [:translate dx dy])
      (assoc ::shape (shape/translate (::shape js) dx dy))))

(defmethod shape/scale ::journal-shape [js factor]
  {:pre [(s/valid? ::journaled-shape js)
         (number? factor)]
   :post [(s/valid? ::journaled-shape %)]}
  (-> js
      (update ::journal conj [:scale factor])
      (assoc ::shape (shape/scale (::shape js) factor))))
