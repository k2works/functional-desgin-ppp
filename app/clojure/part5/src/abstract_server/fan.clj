(ns abstract-server.fan
  "Abstract Server パターン - Fan

   扇風機デバイスの実装です。Switchable プロトコルを実装します。"
  (:require [abstract-server.switchable :as switchable]))

;; =============================================================================
;; Fan の定義
;; =============================================================================

(defrecord Fan [state speed]
  switchable/Switchable
  (turn-on [this]
    (assoc this :state :on :speed (or speed :low)))
  (turn-off [this]
    (assoc this :state :off :speed nil))
  (is-on? [this]
    (= (:state this) :on)))

(defn make
  "扇風機を作成（初期状態: オフ）"
  []
  (->Fan :off nil))

(defn set-speed
  "扇風機の速度を設定"
  [fan speed]
  (if (switchable/is-on? fan)
    (assoc fan :speed speed)
    fan))
