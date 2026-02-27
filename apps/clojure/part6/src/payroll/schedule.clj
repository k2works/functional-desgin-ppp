(ns payroll.schedule
  "給与計算システム - 支払いスケジュール

   各支払いスケジュール（月次、週次、隔週）に応じた
   支払日判定ロジックを実装します。"
  (:require [payroll.employee :as emp]))

;; =============================================================================
;; 支払日判定マルチメソッド
;; =============================================================================

(defmulti is-pay-day?
  "指定日が支払日かどうかを判定"
  (fn [employee _date] (emp/get-schedule employee)))

;; 月次（月末）
(defmethod is-pay-day? :monthly
  [_employee date]
  (let [day (:day date)
        month (:month date)
        year (:year date)
        ;; 簡易的な月末判定
        last-days {1 31 2 28 3 31 4 30 5 31 6 30
                   7 31 8 31 9 30 10 31 11 30 12 31}
        last-day (get last-days month 30)]
    ;; うるう年の2月は考慮
    (if (and (= month 2)
             (or (zero? (mod year 400))
                 (and (zero? (mod year 4))
                      (not (zero? (mod year 100))))))
      (= day 29)
      (= day last-day))))

;; 週次（金曜日）
(defmethod is-pay-day? :weekly
  [_employee date]
  (= (:day-of-week date) :friday))

;; 隔週（隔週の金曜日）
(defmethod is-pay-day? :biweekly
  [_employee date]
  (and (= (:day-of-week date) :friday)
       (:is-pay-week date)))

;; =============================================================================
;; 日付ユーティリティ
;; =============================================================================

(defn make-date
  "日付を作成"
  ([year month day]
   {:year year :month month :day day})
  ([year month day day-of-week]
   {:year year :month month :day day :day-of-week day-of-week})
  ([year month day day-of-week is-pay-week]
   {:year year :month month :day day
    :day-of-week day-of-week
    :is-pay-week is-pay-week}))

(defn end-of-month
  "月末の日付を作成"
  [year month]
  (let [last-days {1 31 2 28 3 31 4 30 5 31 6 30
                   7 31 8 31 9 30 10 31 11 30 12 31}
        day (get last-days month 30)]
    (make-date year month day)))

(defn friday
  "金曜日の日付を作成"
  [year month day]
  (make-date year month day :friday))

(defn pay-friday
  "支払い週の金曜日を作成"
  [year month day]
  (make-date year month day :friday true))
