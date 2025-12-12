(ns composite-pattern.light
  "Composite パターン - Light (Leaf)

   通常のライトの実装です。"
  (:require [composite-pattern.switchable :as s]))

(defn make-light
  "ライトを作成する"
  []
  {:type :light
   :on false})

(defn turn-on-light
  "ライトを点灯する（副作用）"
  []
  (println "Light turned ON"))

(defn turn-off-light
  "ライトを消灯する（副作用）"
  []
  (println "Light turned OFF"))

(defmethod s/turn-on :light [switchable]
  (turn-on-light)
  (assoc switchable :on true))

(defmethod s/turn-off :light [switchable]
  (turn-off-light)
  (assoc switchable :on false))
