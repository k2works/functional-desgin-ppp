(ns composite-pattern.composite-switchable
  "Composite パターン - CompositeSwitchable (Composite)

   複数のスイッチ可能オブジェクトをまとめて操作できる
   複合スイッチの実装です。"
  (:require [composite-pattern.switchable :as s]))

(defn make-composite-switchable
  "空の複合スイッチを作成する"
  []
  {:type :composite-switchable
   :switchables []})

(defn add
  "複合スイッチにスイッチ可能オブジェクトを追加する"
  [composite-switchable switchable]
  (update composite-switchable :switchables conj switchable))

(defmethod s/turn-on :composite-switchable [c-switchable]
  (let [turned-on (mapv s/turn-on (:switchables c-switchable))]
    (assoc c-switchable :switchables turned-on)))

(defmethod s/turn-off :composite-switchable [c-switchable]
  (let [turned-off (mapv s/turn-off (:switchables c-switchable))]
    (assoc c-switchable :switchables turned-off)))
