(ns abstract-server.memory-repository
  "Abstract Server パターン - MemoryRepository

   インメモリでデータを保持するリポジトリの実装です。"
  (:require [abstract-server.repository :as repo]))

;; =============================================================================
;; MemoryRepository の定義
;; =============================================================================

(defrecord MemoryRepository [data]
  repo/Repository
  (find-by-id [this id]
    (get @(:data this) id))
  (find-all [this]
    (vals @(:data this)))
  (save [this entity]
    (let [id (or (:id entity) (str (java.util.UUID/randomUUID)))
          entity-with-id (assoc entity :id id)]
      (swap! (:data this) assoc id entity-with-id)
      entity-with-id))
  (delete [this id]
    (let [entity (get @(:data this) id)]
      (swap! (:data this) dissoc id)
      entity)))

(defn make
  "インメモリリポジトリを作成"
  []
  (->MemoryRepository (atom {})))

(defn make-with-data
  "初期データ付きインメモリリポジトリを作成"
  [initial-data]
  (let [data-map (reduce (fn [m entity]
                           (assoc m (:id entity) entity))
                         {}
                         initial-data)]
    (->MemoryRepository (atom data-map))))
