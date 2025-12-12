(ns pattern-interactions.observer
  "Observer パターン - イベント通知システム")

(defn make-subject
  "サブジェクト（観察対象）を作成"
  []
  (atom {:observers []
         :state nil}))

(defn add-observer
  "オブザーバーを登録"
  [subject observer-fn]
  (swap! subject update :observers conj observer-fn))

(defn remove-observer
  "オブザーバーを解除"
  [subject observer-fn]
  (swap! subject update :observers
         (fn [observers]
           (remove #(= % observer-fn) observers))))

(defn notify-observers
  "すべてのオブザーバーに通知"
  [subject event]
  (doseq [observer (:observers @subject)]
    (observer event)))

(defn get-state
  "現在の状態を取得"
  [subject]
  (:state @subject))

(defn set-state!
  "状態を設定し、オブザーバーに通知"
  [subject new-state]
  (swap! subject assoc :state new-state)
  (notify-observers subject {:type :state-changed
                             :new-state new-state}))
