(ns concurrency.event-system
  "並行処理システム - イベント駆動システム

   Clojure のエージェントを使ったイベント駆動
   アーキテクチャを実装します。")

;; =============================================================================
;; イベントバス
;; =============================================================================

(defn make-event-bus
  "イベントバスを作成"
  []
  (agent {:subscribers {}
          :event-log []}))

;; =============================================================================
;; 購読管理
;; =============================================================================

(defn subscribe
  "イベントを購読"
  [bus event-type handler]
  (send bus
        (fn [state]
          (update-in state [:subscribers event-type]
                     (fnil conj []) handler))))

(defn unsubscribe
  "購読を解除"
  [bus event-type handler]
  (send bus
        (fn [state]
          (update-in state [:subscribers event-type]
                     (fn [handlers]
                       (vec (remove #(= % handler) handlers)))))))

;; =============================================================================
;; イベント発行
;; =============================================================================

(defn publish
  "イベントを発行"
  [bus event-type data]
  (send bus
        (fn [state]
          (let [handlers (get-in state [:subscribers event-type] [])
                event {:type event-type
                       :data data
                       :timestamp (System/currentTimeMillis)}]
            ;; ハンドラを実行
            (doseq [handler handlers]
              (try
                (handler event)
                (catch Exception e
                  (println "Handler error:" (.getMessage e)))))
            ;; イベントログに追加
            (update state :event-log conj event)))))

;; =============================================================================
;; イベントログ
;; =============================================================================

(defn get-event-log
  "イベントログを取得"
  [bus]
  (:event-log @bus))

(defn clear-event-log
  "イベントログをクリア"
  [bus]
  (send bus assoc :event-log []))

;; =============================================================================
;; ユーティリティ
;; =============================================================================

(defn await-bus
  "イベントバスの処理完了を待つ"
  [bus]
  (await bus))

(defn get-subscribers
  "購読者を取得"
  [bus event-type]
  (get-in @bus [:subscribers event-type] []))
