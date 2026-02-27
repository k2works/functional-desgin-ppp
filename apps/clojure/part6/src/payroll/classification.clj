(ns payroll.classification
  "給与計算システム - 給与分類

   各給与タイプ（月給、時給、歩合）に応じた
   給与計算ロジックを実装します。
   マルチメソッドによる多態性を活用します。"
  (:require [payroll.employee :as emp]))

;; =============================================================================
;; 給与計算マルチメソッド
;; =============================================================================

(defmulti calc-pay
  "給与を計算する
   給与タイプに応じて異なる計算ロジックを適用"
  (fn [employee _context] (emp/get-pay-type employee)))

;; 月給制
(defmethod calc-pay :salaried
  [employee _context]
  (let [[_ salary] (emp/get-pay-class employee)]
    salary))

;; 時給制
(defmethod calc-pay :hourly
  [employee context]
  (let [[_ hourly-rate] (emp/get-pay-class employee)
        time-cards (get-in context [:time-cards (emp/get-id employee)] [])
        hours (map second time-cards)
        total-hours (reduce + 0 hours)
        ;; 週40時間を超える分は1.5倍
        regular-hours (min total-hours 40)
        overtime-hours (max 0 (- total-hours 40))]
    (+ (* regular-hours hourly-rate)
       (* overtime-hours hourly-rate 1.5))))

;; 歩合制
(defmethod calc-pay :commissioned
  [employee context]
  (let [[_ base-pay commission-rate] (emp/get-pay-class employee)
        sales-receipts (get-in context [:sales-receipts (emp/get-id employee)] [])
        total-sales (reduce + 0 (map second sales-receipts))]
    (+ base-pay (* total-sales commission-rate))))

;; =============================================================================
;; ユーティリティ
;; =============================================================================

(defn add-time-card
  "タイムカードを追加"
  [context employee-id date hours]
  (update-in context [:time-cards employee-id] conj [date hours]))

(defn add-sales-receipt
  "売上レシートを追加"
  [context employee-id date amount]
  (update-in context [:sales-receipts employee-id] conj [date amount]))

(defn make-context
  "空のコンテキストを作成"
  []
  {:time-cards {}
   :sales-receipts {}})
