(ns wator.fish
  "Wa-Tor シミュレーション - 魚

   魚（被食者）を表します。
   移動と繁殖の機能を持ちます。"
  (:require [wator.cell :as cell]
            [wator.animal :as animal]
            [wator.config :as config]))

;; =============================================================================
;; 判定関数
;; =============================================================================

(defn is?
  "魚かどうか判定"
  [cell]
  (= ::fish (::cell/type cell)))

;; =============================================================================
;; コンストラクタ
;; =============================================================================

(defn make
  "魚を作成"
  []
  (merge {::cell/type ::fish}
         (animal/make)))

;; =============================================================================
;; マルチメソッド実装
;; =============================================================================

(defmethod animal/make-child ::fish
  [_fish]
  (make))

(defmethod animal/get-reproduction-age ::fish
  [_fish]
  config/fish-reproduction-age)

(defmethod animal/move ::fish
  [fish loc world]
  (animal/do-move fish loc world))

(defmethod animal/reproduce ::fish
  [fish loc world]
  (animal/do-reproduce fish loc world))

(defmethod cell/tick ::fish
  [fish loc world]
  (animal/tick fish loc world))

(defmethod cell/display ::fish
  [_fish]
  "f")
