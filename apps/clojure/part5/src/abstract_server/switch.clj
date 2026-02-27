(ns abstract-server.switch
  "Abstract Server パターン - Switch

   スイッチコントローラの実装です。
   Switchable プロトコルに依存することで、
   具体的なデバイスから独立しています。"
  (:require [abstract-server.switchable :as switchable]))

;; =============================================================================
;; Switch の定義
;; =============================================================================

(defn engage
  "スイッチを入れる（デバイスをオンにする）"
  [device]
  (switchable/turn-on device))

(defn disengage
  "スイッチを切る（デバイスをオフにする）"
  [device]
  (switchable/turn-off device))

(defn toggle
  "スイッチを切り替える"
  [device]
  (if (switchable/is-on? device)
    (switchable/turn-off device)
    (switchable/turn-on device)))

(defn status
  "デバイスの状態を取得"
  [device]
  (if (switchable/is-on? device)
    :on
    :off))
