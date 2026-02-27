(ns oo-to-fp.oo-to-fp-spec
  (:require [speclj.core :refer :all]
            [oo-to-fp.oo-style :as oo]
            [oo-to-fp.fp-style :as fp]
            [oo-to-fp.migration-strategies :as ms]))

(describe "OOスタイルからFPスタイルへの移行"

  (describe "OOスタイル（移行前）"
    (it "OOスタイルの口座を作成できる"
      (let [acc (oo/make-account-oo "A001" 1000)]
        (should= "A001" ((:get-id acc)))
        (should= 1000 ((:get-balance acc)))))

    (it "OOスタイルの口座に入金できる"
      (let [acc (oo/make-account-oo "A001" 1000)]
        ((:deposit acc) 500)
        (should= 1500 ((:get-balance acc)))))

    (it "OOスタイルの口座から出金できる"
      (let [acc (oo/make-account-oo "A001" 1000)]
        ((:withdraw acc) 300)
        (should= 700 ((:get-balance acc)))))

    (it "OOスタイルの円を作成できる"
      (let [circle (oo/make-circle-oo 0 0 10)]
        (should= 10 ((:get-radius circle)))
        (should (> ((:area circle)) 314)))))

  (describe "FPスタイル（移行後）"
    (it "FPスタイルの口座を作成できる"
      (let [acc (fp/make-account "A001" 1000)]
        (should= "A001" (:id acc))
        (should= 1000 (fp/get-balance acc))))

    (it "FPスタイルの入金はイミュータブル"
      (let [acc (fp/make-account "A001" 1000)
            new-acc (fp/deposit acc 500)]
        (should= 1000 (fp/get-balance acc))
        (should= 1500 (fp/get-balance new-acc))))

    (it "FPスタイルの出金はイミュータブル"
      (let [acc (fp/make-account "A001" 1000)
            new-acc (fp/withdraw acc 300)]
        (should= 1000 (fp/get-balance acc))
        (should= 700 (fp/get-balance new-acc))))

    (it "残高不足の場合は出金できない"
      (let [acc (fp/make-account "A001" 100)
            new-acc (fp/withdraw acc 500)]
        (should= 100 (fp/get-balance new-acc))))

    (it "送金が正しく動作する"
      (let [from (fp/make-account "A001" 1000)
            to (fp/make-account "A002" 500)
            result (fp/transfer from to 300)]
        (should (:success result))
        (should= 700 (fp/get-balance (:from result)))
        (should= 800 (fp/get-balance (:to result))))))

  (describe "FPスタイルの図形"
    (it "円の面積を計算できる"
      (let [circle (fp/make-circle 0 0 10)]
        (should (< (Math/abs (- (* Math/PI 100) (fp/area circle))) 0.001))))

    (it "矩形の面積を計算できる"
      (let [rect (fp/make-rectangle 0 0 10 20)]
        (should= 200 (fp/area rect))))

    (it "図形を移動できる"
      (let [circle (fp/make-circle 0 0 10)
            moved (fp/move circle 5 3)]
        (should= 5 (:x moved))
        (should= 3 (:y moved))
        (should= 0 (:x circle))))

    (it "図形を拡大できる"
      (let [circle (fp/make-circle 0 0 10)
            scaled (fp/scale circle 2)]
        (should= 20 (:radius scaled))
        (should= 10 (:radius circle)))))

  (describe "FPスタイルのイベントシステム"
    (it "イベントシステムを作成できる"
      (let [system (fp/make-event-system)]
        (should= {} (:handlers system))
        (should= [] (:event-log system))))

    (it "イベントを購読できる"
      (let [handler (fn [_] :handled)
            system (-> (fp/make-event-system)
                       (fp/subscribe :test-event handler))]
        (should= 1 (count (get-in system [:handlers :test-event])))))

    (it "イベントを発行できる"
      (let [results (atom [])
            handler (fn [event] (swap! results conj (:data event)))
            system (fp/subscribe (fp/make-event-system) :test handler)
            {:keys [system results]} (fp/publish system :test {:value 42})]
        (should= 1 (count (fp/get-event-log system)))))))

(describe "移行戦略"

  (describe "Strangler Fig パターン"
    (it "FPスタイルで口座を作成できる"
      (let [account (ms/create-account-strangler "A001" 1000 true)]
        (should= :fp (:style account))
        (should= 1000 (:balance (:data account)))))

    (it "統一インターフェースで入金できる"
      (let [account (ms/create-account-strangler "A001" 1000 true)
            updated (ms/account-deposit account 500)]
        (should= 1500 (:balance (:data updated))))))

  (describe "アダプターパターン"
    (it "FPアダプターで残高を取得できる"
      (let [adapter (ms/make-fp-account-adapter "A001" 1000)]
        (should= 1000 (ms/get-account-balance adapter))))

    (it "FPアダプターで入金できる"
      (let [adapter (ms/make-fp-account-adapter "A001" 1000)]
        (ms/deposit-to-account adapter 500)
        (should= 1500 (ms/get-account-balance adapter))))

    (it "FPアダプターで出金できる"
      (let [adapter (ms/make-fp-account-adapter "A001" 1000)]
        (ms/withdraw-from-account adapter 300)
        (should= 700 (ms/get-account-balance adapter)))))

  (describe "イベントソーシング移行"
    (it "イベントを適用できる"
      (let [account {}
            created (ms/apply-event account
                                    (ms/account-event :created
                                                      {:id "A001"
                                                       :balance 0
                                                       :transactions []}))]
        (should= "A001" (:id created))))

    (it "イベントをリプレイできる"
      (let [events [(ms/account-event :created {:id "A001" :balance 0 :transactions []})
                    (ms/account-event :deposited {:amount 1000})
                    (ms/account-event :withdrawn {:amount 300})]
            account (ms/replay-events events)]
        (should= 700 (:balance account))))

    (it "既存データをイベントに変換できる"
      (let [account {:id "A001"
                     :balance 700
                     :transactions [{:type :deposit :amount 1000}
                                    {:type :withdrawal :amount 300}]}
            events (ms/migrate-to-event-sourcing account)]
        (should= 3 (count events))
        (should= :created (:event-type (first events))))))

  (describe "純粋関数の抽出"
    (it "利息を計算できる"
      (should= 10.0 (ms/calculate-interest 1000 0.1 36.5)))

    (it "手数料を計算できる"
      (let [fee-structure {:minimum-balance 1000
                           :premium-threshold 10000
                           :low-balance-fee 500
                           :standard-fee 100}]
        (should= 500 (ms/calculate-fee 500 fee-structure))
        (should= 100 (ms/calculate-fee 5000 fee-structure))
        (should= 0 (ms/calculate-fee 15000 fee-structure))))

    (it "出金可能かどうかを判定できる"
      (let [account {:balance 1000}]
        (should (ms/can-withdraw? account 500 0))
        (should-not (ms/can-withdraw? account 1500 0))
        (should (ms/can-withdraw? account 1500 1000))))

    (it "取引を処理できる"
      (let [account (fp/make-account "A001" 1000)
            rules {:overdraft-limit 0}
            result (ms/process-transaction account :withdraw 500 rules)]
        (should (:success result))
        (should= 500 (:balance (:account result)))))

    (it "残高不足で取引が失敗する"
      (let [account (fp/make-account "A001" 100)
            rules {:overdraft-limit 0}
            result (ms/process-transaction account :withdraw 500 rules)]
        (should-not (:success result))
        (should= "Insufficient funds" (:error result))))))

(run-specs)
