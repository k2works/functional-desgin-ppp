(ns composite-pattern.variable-light
  "Composite パターン - VariableLight (Leaf)

   調光可能なライトの実装です。"
  (:require [composite-pattern.switchable :as s]))

(defn make-variable-light
  "調光可能なライトを作成する"
  []
  {:type :variable-light
   :intensity 0})

(defn set-light-intensity
  "ライトの強度を設定する（副作用）"
  [intensity]
  (println (str "Light intensity set to " intensity)))

(defmethod s/turn-on :variable-light [switchable]
  (set-light-intensity 100)
  (assoc switchable :intensity 100))

(defmethod s/turn-off :variable-light [switchable]
  (set-light-intensity 0)
  (assoc switchable :intensity 0))
