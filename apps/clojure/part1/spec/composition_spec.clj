(ns composition-spec
  (:require [speclj.core :refer :all]
            [composition :refer :all]))

(describe "関数合成と高階関数"

  (context "関数合成の基本 (comp)"
    (it "calculate-final-price は割引、税金、丸めを適用する"
      ;; 1000円 -> 20%割引で800円 -> 10%税込で880円
      (should= 880 (calculate-final-price 1000)))

    (it "add-tax は税金を追加する"
      (should= 1100.0 (add-tax 0.1 1000)))

    (it "apply-discount-rate は割引を適用する"
      (should= 800.0 (apply-discount-rate 0.2 1000)))

    (it "round-to-yen は円単位に丸める"
      (should= 100 (round-to-yen 99.5))
      (should= 99 (round-to-yen 99.4))))

  (context "部分適用 (partial)"
    (it "say-hello は Hello で挨拶する"
      (should= "Hello, 田中!" (say-hello "田中")))

    (it "say-goodbye は Goodbye で挨拶する"
      (should= "Goodbye, 鈴木!" (say-goodbye "鈴木")))

    (it "send-notification は部分適用されたメールを送信する"
      (let [email (send-notification "メッセージ本文")]
        (should= "system@example.com" (:from email))
        (should= "user@example.com" (:to email))
        (should= "通知" (:subject email))
        (should= "メッセージ本文" (:body email)))))

  (context "juxt - 複数の関数を並列適用"
    (it "get-stats は数値リストの統計情報を返す"
      (let [[first-val last-val cnt min-val max-val] (get-stats [3 1 4 1 5 9 2 6])]
        (should= 3 first-val)
        (should= 6 last-val)
        (should= 8 cnt)
        (should= 1 min-val)
        (should= 9 max-val)))

    (it "analyze-person は人物情報を分析する"
      (should= ["田中" 25 :adult] (analyze-person {:name "田中" :age 25}))
      (should= ["鈴木" 15 :minor] (analyze-person {:name "鈴木" :age 15}))))

  (context "高階関数によるデータ処理"
    (it "process-with-logging はログを出力しながら処理を実行する"
      (let [add-with-log (process-with-logging +)]
        (should= 5 (add-with-log 2 3))))

    (it "retry は失敗時にリトライする"
      (let [counter (atom 0)
            flaky-fn (fn []
                       (swap! counter inc)
                       (if (< @counter 3)
                         (throw (Exception. "一時的なエラー"))
                         "成功"))
            retry-fn (retry flaky-fn 5)]
        (should= "成功" (retry-fn))
        (should= 3 @counter))))

  (context "パイプライン処理"
    (it "pipeline は関数を順次適用する"
      (let [double-then-add10 (pipeline #(* % 2) #(+ % 10))]
        (should= 30 (double-then-add10 10))))

    (it "process-order-pipeline は注文を処理する"
      (let [order {:items [{:price 1000 :quantity 2}
                           {:price 500 :quantity 3}]
                   :customer {:membership :gold}}
            result (process-order-pipeline order)]
        ;; 合計: 2000 + 1500 = 3500
        ;; 割引: 3500 * 0.9 = 3150
        ;; 送料: 3150 >= 5000 ? 0 : 500 => 500
        ;; 最終: 3150 + 500 = 3650
        (should= 3650.0 (:total result))
        (should= 500 (:shipping result))))

    (it "validate-order は空の注文でエラーを投げる"
      (should-throw clojure.lang.ExceptionInfo
                    (validate-order {:items []}))))

  (context "関数合成によるバリデーション"
    (it "validate-quantity は有効な数量を検証する"
      (should (:valid (validate-quantity 50)))
      (should-not (:valid (validate-quantity -1)))
      (should-not (:valid (validate-quantity 100)))
      (should-not (:valid (validate-quantity 1.5))))

    (it "validator は述語に基づいてバリデーションする"
      (let [v (validator even? "偶数である必要があります")]
        (should (:valid (v 2)))
        (should-not (:valid (v 3)))
        (should= "偶数である必要があります" (:error (v 3))))))

  (context "関数の変換"
    (it "flip は引数の順序を反転する"
      (should= 2 ((flip -) 3 5)))

    (it "complement-fn は述語の結果を反転する"
      (let [not-even? (complement-fn even?)]
        (should (not-even? 3))
        (should-not (not-even? 2))))

    (it "constantly-fn は常に同じ値を返す"
      (let [always-42 (constantly-fn 42)]
        (should= 42 (always-42))
        (should= 42 (always-42 1 2 3))))

    (it "curry は2引数関数をカリー化する"
      (let [curried-add (curry +)
            add5 (curried-add 5)]
        (should= 8 (add5 3))))

    (it "uncurry はカリー化された関数を元に戻す"
      (let [curried (fn [a] (fn [b] (+ a b)))
            uncurried (uncurry curried)]
        (should= 8 (uncurried 5 3)))))

  (context "関数合成のパターン"
    (it "valid-age? は有効な年齢をチェックする"
      (should (valid-age? 25))
      (should (valid-age? 1))
      (should (valid-age? 150))
      (should-not (valid-age? -1))
      (should-not (valid-age? 151))
      (should-not (valid-age? 25.5)))

    (it "premium-customer? はプレミアム顧客をチェックする"
      (should (premium-customer? {:membership :gold :purchase-count 0 :total-spent 0}))
      (should (premium-customer? {:membership :bronze :purchase-count 100 :total-spent 0}))
      (should (premium-customer? {:membership :bronze :purchase-count 0 :total-spent 100000}))
      (should-not (premium-customer? {:membership :bronze
                                       :purchase-count 10
                                       :total-spent 1000})))))

(run-specs)
