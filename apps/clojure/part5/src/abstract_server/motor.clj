(ns abstract-server.motor
  "Abstract Server パターン - Motor

   モーターデバイスの実装です。Switchable プロトコルを実装します。"
  (:require [abstract-server.switchable :as switchable]))

;; =============================================================================
;; Motor の定義
;; =============================================================================

(defrecord Motor [state direction]
  switchable/Switchable
  (turn-on [this]
    (assoc this :state :on :direction (or direction :forward)))
  (turn-off [this]
    (assoc this :state :off))
  (is-on? [this]
    (= (:state this) :on)))

(defn make
  "モーターを作成（初期状態: オフ）"
  []
  (->Motor :off nil))

(defn set-direction
  "モーターの回転方向を設定"
  [motor direction]
  (if (switchable/is-on? motor)
    (assoc motor :direction direction)
    motor))

(defn reverse-direction
  "モーターの回転方向を反転"
  [motor]
  (if (switchable/is-on? motor)
    (let [current (:direction motor)]
      (assoc motor :direction (if (= current :forward) :reverse :forward)))
    motor))
