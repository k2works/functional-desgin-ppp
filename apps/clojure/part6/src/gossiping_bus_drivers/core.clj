(ns gossiping-bus-drivers.core
  "ゴシップ好きなバスの運転手

   バス運転手が停留所で噂を共有するシミュレーションです。
   無限シーケンス（cycle）を使って循環ルートを表現し、
   集合演算で噂の伝播をモデル化します。"
  (:require [clojure.set :as set]))

;; =============================================================================
;; ドライバーの作成と操作
;; =============================================================================

(defn make-driver
  "ドライバーを作成する
   name - ドライバーの名前
   route - 停留所のシーケンス
   rumors - 知っている噂の集合"
  [name route rumors]
  {:name name
   :route (cycle route)  ; 無限シーケンスで循環ルート
   :rumors rumors})

(defn current-stop
  "ドライバーの現在の停留所を取得"
  [driver]
  (first (:route driver)))

(defn move-driver
  "ドライバーを次の停留所に移動"
  [driver]
  (update driver :route rest))

(defn move-drivers
  "全ドライバーを次の停留所に移動"
  [world]
  (map move-driver world))

;; =============================================================================
;; 停留所の集計
;; =============================================================================

(defn get-stops
  "各停留所にいるドライバーをマップとして取得
   {停留所番号 => [ドライバー1, ドライバー2, ...]}"
  [world]
  (loop [world world
         stops {}]
    (if (empty? world)
      stops
      (let [driver (first world)
            stop (current-stop driver)
            stops (update stops stop conj driver)]
        (recur (rest world) stops)))))

;; =============================================================================
;; 噂の伝播
;; =============================================================================

(defn merge-rumors
  "同じ停留所にいるドライバー間で噂を共有
   全員の噂を統合し、各ドライバーに設定"
  [drivers]
  (let [rumors (map :rumors drivers)
        all-rumors (apply set/union rumors)]
    (map #(assoc % :rumors all-rumors) drivers)))

(defn spread-rumors
  "全停留所で噂を伝播"
  [world]
  (let [stops-with-drivers (get-stops world)
        drivers-by-stop (vals stops-with-drivers)]
    (flatten (map merge-rumors drivers-by-stop))))

;; =============================================================================
;; シミュレーション
;; =============================================================================

(defn drive
  "1ステップ分のシミュレーション
   1. 全ドライバーを移動
   2. 同じ停留所にいるドライバー間で噂を共有"
  [world]
  (-> world
      move-drivers
      spread-rumors))

(defn all-rumors-shared?
  "全ドライバーが同じ噂を持っているか確認"
  [world]
  (apply = (map :rumors world)))

(defn drive-till-all-rumors-spread
  "全ての噂が共有されるまでシミュレーション
   480分（8時間）以内に共有されなければ :never を返す"
  [world]
  (loop [world (drive world)
         time 1]
    (cond
      (> time 480) :never
      (all-rumors-shared? world) time
      :else (recur (drive world) (inc time)))))

;; =============================================================================
;; ユーティリティ関数
;; =============================================================================

(defn count-unique-rumors
  "ワールド内のユニークな噂の総数"
  [world]
  (count (apply set/union (map :rumors world))))

(defn driver-summary
  "ドライバーの状態をサマリーとして取得"
  [driver]
  {:name (:name driver)
   :current-stop (current-stop driver)
   :rumor-count (count (:rumors driver))})

(defn world-summary
  "ワールドの状態をサマリーとして取得"
  [world]
  {:drivers (map driver-summary world)
   :total-unique-rumors (count-unique-rumors world)
   :all-shared? (all-rumors-shared? world)})
