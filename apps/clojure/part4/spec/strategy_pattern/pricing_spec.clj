(ns strategy-pattern.pricing-spec
  (:require [speclj.core :refer :all]
            [strategy-pattern.pricing :as pricing]))

(describe "Strategy パターン - 料金計算"

  (context "通常料金戦略"
    (it "金額をそのまま返す"
      (let [strategy (pricing/make-regular-pricing)]
        (should= 1000 (pricing/calculate-price strategy 1000))
        (should= 500 (pricing/calculate-price strategy 500)))))

  (context "割引料金戦略"
    (it "10%割引を適用できる"
      (let [strategy (pricing/make-discount-pricing 0.10)]
        (should= 900.0 (pricing/calculate-price strategy 1000))))

    (it "20%割引を適用できる"
      (let [strategy (pricing/make-discount-pricing 0.20)]
        (should= 800.0 (pricing/calculate-price strategy 1000))))

    (it "0%割引は金額が変わらない"
      (let [strategy (pricing/make-discount-pricing 0.0)]
        (should= 1000.0 (pricing/calculate-price strategy 1000)))))

  (context "会員料金戦略"
    (it "ゴールド会員は20%割引"
      (let [strategy (pricing/make-member-pricing :gold)]
        (should= 800.0 (pricing/calculate-price strategy 1000))))

    (it "シルバー会員は15%割引"
      (let [strategy (pricing/make-member-pricing :silver)]
        (should= 850.0 (pricing/calculate-price strategy 1000))))

    (it "ブロンズ会員は10%割引"
      (let [strategy (pricing/make-member-pricing :bronze)]
        (should= 900.0 (pricing/calculate-price strategy 1000))))

    (it "不明な会員レベルは割引なし"
      (let [strategy (pricing/make-member-pricing :unknown)]
        (should= 1000.0 (pricing/calculate-price strategy 1000)))))

  (context "数量割引戦略"
    (it "閾値以上の数量で割引適用"
      (let [strategy (pricing/make-bulk-pricing 10 0.15)
            order {:unit-price 100 :quantity 15}]
        (should= 1275.0 (pricing/calculate-price strategy order))))

    (it "閾値未満の数量は割引なし"
      (let [strategy (pricing/make-bulk-pricing 10 0.15)
            order {:unit-price 100 :quantity 5}]
        (should= 500 (pricing/calculate-price strategy order))))

    (it "閾値ちょうどの数量で割引適用"
      (let [strategy (pricing/make-bulk-pricing 10 0.15)
            order {:unit-price 100 :quantity 10}]
        (should= 850.0 (pricing/calculate-price strategy order))))))

(run-specs)
