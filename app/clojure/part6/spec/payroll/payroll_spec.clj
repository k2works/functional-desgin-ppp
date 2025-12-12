(ns payroll.payroll-spec
  (:require [speclj.core :refer :all]
            [payroll.employee :as emp]
            [payroll.classification :as class]
            [payroll.schedule :as sched]
            [payroll.payroll :as payroll]))

(describe "給与計算システム"

  (context "従業員の作成"
    (it "月給制従業員を作成できる"
      (let [e (emp/make-salaried-employee "E001" "田中太郎" 500000)]
        (should= "E001" (emp/get-id e))
        (should= "田中太郎" (emp/get-name e))
        (should= :salaried (emp/get-pay-type e))
        (should= :monthly (emp/get-schedule e))))

    (it "時給制従業員を作成できる"
      (let [e (emp/make-hourly-employee "E002" "佐藤花子" 1500)]
        (should= "E002" (emp/get-id e))
        (should= :hourly (emp/get-pay-type e))
        (should= :weekly (emp/get-schedule e))))

    (it "歩合制従業員を作成できる"
      (let [e (emp/make-commissioned-employee "E003" "鈴木一郎" 200000 0.1)]
        (should= "E003" (emp/get-id e))
        (should= :commissioned (emp/get-pay-type e))
        (should= :biweekly (emp/get-schedule e)))))

  (context "給与計算 - 月給制"
    (it "月給をそのまま返す"
      (let [e (emp/make-salaried-employee "E001" "田中" 500000)
            ctx (class/make-context)]
        (should= 500000 (class/calc-pay e ctx)))))

  (context "給与計算 - 時給制"
    (it "タイムカードがない場合は0"
      (let [e (emp/make-hourly-employee "E002" "佐藤" 1500)
            ctx (class/make-context)]
        (should= 0.0 (class/calc-pay e ctx))))

    (it "通常時間の給与を計算"
      (let [e (emp/make-hourly-employee "E002" "佐藤" 1500)
            ctx (-> (class/make-context)
                    (class/add-time-card "E002" "2024-01-15" 8)
                    (class/add-time-card "E002" "2024-01-16" 8))]
        (should= 24000.0 (class/calc-pay e ctx)))) ; 16時間 * 1500円

    (it "残業時間は1.5倍で計算"
      (let [e (emp/make-hourly-employee "E002" "佐藤" 1000)
            ctx (-> (class/make-context)
                    (class/add-time-card "E002" "2024-01-15" 45))] ; 40通常 + 5残業
        ;; 40 * 1000 + 5 * 1000 * 1.5 = 40000 + 7500 = 47500
        (should= 47500.0 (class/calc-pay e ctx)))))

  (context "給与計算 - 歩合制"
    (it "売上がない場合は基本給のみ"
      (let [e (emp/make-commissioned-employee "E003" "鈴木" 200000 0.1)
            ctx (class/make-context)]
        (should= 200000.0 (class/calc-pay e ctx))))

    (it "売上に応じたコミッションを加算"
      (let [e (emp/make-commissioned-employee "E003" "鈴木" 200000 0.1)
            ctx (-> (class/make-context)
                    (class/add-sales-receipt "E003" "2024-01-15" 100000)
                    (class/add-sales-receipt "E003" "2024-01-16" 50000))]
        ;; 200000 + (100000 + 50000) * 0.1 = 200000 + 15000 = 215000
        (should= 215000.0 (class/calc-pay e ctx)))))

  (context "支払いスケジュール"
    (it "月給制は月末が支払日"
      (let [e (emp/make-salaried-employee "E001" "田中" 500000)]
        (should (sched/is-pay-day? e (sched/end-of-month 2024 1)))
        (should-not (sched/is-pay-day? e (sched/make-date 2024 1 15)))))

    (it "時給制は毎週金曜日が支払日"
      (let [e (emp/make-hourly-employee "E002" "佐藤" 1500)]
        (should (sched/is-pay-day? e (sched/friday 2024 1 19)))
        (should-not (sched/is-pay-day? e (sched/make-date 2024 1 18 :thursday)))))

    (it "歩合制は隔週金曜日が支払日"
      (let [e (emp/make-commissioned-employee "E003" "鈴木" 200000 0.1)]
        (should (sched/is-pay-day? e (sched/pay-friday 2024 1 19)))
        (should-not (sched/is-pay-day? e (sched/friday 2024 1 12))))))

  (context "支払い処理"
    (it "保留の場合は支払いを保留"
      (let [e (emp/make-salaried-employee "E001" "田中" 500000)
            result (payroll/process-payment e 500000)]
        (should= :hold (:type result))
        (should= "E001" (:employee-id result))))

    (it "口座振込の場合は振り込み"
      (let [e (-> (emp/make-salaried-employee "E001" "田中" 500000)
                  (emp/set-payment-method :direct-deposit))
            result (payroll/process-payment e 500000)]
        (should= :direct-deposit (:type result))))

    (it "郵送の場合は小切手を郵送"
      (let [e (-> (emp/make-salaried-employee "E001" "田中" 500000)
                  (emp/set-payment-method :mail))
            result (payroll/process-payment e 500000)]
        (should= :mail (:type result)))))

  (context "給与レポート"
    (it "全従業員の給与レポートを生成"
      (let [employees [(emp/make-salaried-employee "E001" "田中" 500000)
                       (emp/make-hourly-employee "E002" "佐藤" 1500)]
            ctx (-> (class/make-context)
                    (class/add-time-card "E002" "2024-01-15" 40))
            report (payroll/payroll-report employees ctx)]
        (should= 2 (:count report))
        (should= 560000.0 (:total report))))))

(run-specs)
