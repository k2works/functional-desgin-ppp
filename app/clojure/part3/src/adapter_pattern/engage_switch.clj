(ns adapter-pattern.engage-switch
  "Adapter パターン - Client

   Switchable インターフェースを使用するクライアントです。
   具体的な実装の詳細を知る必要がありません。"
  (:require [adapter-pattern.switchable :as s]))

(defn engage-switch
  "スイッチを操作する"
  [switchable]
  (println "Engaging switch...")
  (let [on-result (s/turn-on switchable)
        off-result (s/turn-off switchable)]
    {:on-result on-result
     :off-result off-result}))
