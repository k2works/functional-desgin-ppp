(ns payroll.payroll
  "給与計算システム - 給与処理

   従業員の給与計算と支払い処理を
   統合的に管理します。"
  (:require [payroll.employee :as emp]
            [payroll.classification :as class]
            [payroll.schedule :as sched]))

;; =============================================================================
;; 給与計算
;; =============================================================================

(defn calculate-pay
  "従業員の給与を計算"
  [employee context]
  (class/calc-pay employee context))

(defn calculate-payroll
  "全従業員の給与を計算"
  [employees context]
  (map (fn [emp]
         {:employee emp
          :pay (calculate-pay emp context)})
       employees))

;; =============================================================================
;; 支払い処理
;; =============================================================================

(defmulti process-payment
  "支払いを処理"
  (fn [employee _amount] (emp/get-payment-method employee)))

(defmethod process-payment :hold
  [employee amount]
  {:type :hold
   :employee-id (emp/get-id employee)
   :amount amount
   :message "支払いを保留"})

(defmethod process-payment :direct-deposit
  [employee amount]
  {:type :direct-deposit
   :employee-id (emp/get-id employee)
   :amount amount
   :message "口座に振り込み"})

(defmethod process-payment :mail
  [employee amount]
  {:type :mail
   :employee-id (emp/get-id employee)
   :amount amount
   :message "小切手を郵送"})

;; =============================================================================
;; 給与支払い
;; =============================================================================

(defn run-payroll
  "給与支払いを実行
   支払日に該当する従業員にのみ支払いを行う"
  [employees context date]
  (let [payable-employees (filter #(sched/is-pay-day? % date) employees)]
    (for [emp payable-employees
          :let [pay (calculate-pay emp context)]]
      (process-payment emp pay))))

;; =============================================================================
;; レポート
;; =============================================================================

(defn payroll-report
  "給与レポートを生成"
  [employees context]
  (let [payroll (calculate-payroll employees context)
        total (reduce + 0 (map :pay payroll))]
    {:employees (map (fn [{:keys [employee pay]}]
                       {:id (emp/get-id employee)
                        :name (emp/get-name employee)
                        :type (emp/get-pay-type employee)
                        :pay pay})
                     payroll)
     :total total
     :count (count employees)}))
