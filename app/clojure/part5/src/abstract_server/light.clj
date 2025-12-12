(ns abstract-server.light
  "Abstract Server パターン - Light

   照明デバイスの実装です。Switchable プロトコルを実装します。"
  (:require [abstract-server.switchable :as switchable]))

;; =============================================================================
;; Light の定義
;; =============================================================================

(defrecord Light [state]
  switchable/Switchable
  (turn-on [this]
    (assoc this :state :on))
  (turn-off [this]
    (assoc this :state :off))
  (is-on? [this]
    (= (:state this) :on)))

(defn make
  "照明を作成（初期状態: オフ）"
  []
  (->Light :off))

(defn make-on
  "オン状態の照明を作成"
  []
  (->Light :on))
