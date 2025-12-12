(ns strategy-pattern.functional-strategy-spec
  (:require [speclj.core :refer :all]
            [strategy-pattern.functional-strategy :as fs]))

(describe "Strategy パターン - 関数型アプローチ"

  (context "基本的な戦略関数"
    (it "通常料金は金額をそのまま返す"
      (should= 1000 (fs/apply-pricing fs/regular-pricing 1000)))

    (it "割引戦略を適用できる"
      (let [strategy (fs/discount-pricing 0.10)]
        (should= 900.0 (fs/apply-pricing strategy 1000))))

    (it "会員戦略を適用できる"
      (let [gold (fs/member-pricing :gold)
            silver (fs/member-pricing :silver)]
        (should= 800.0 (fs/apply-pricing gold 1000))
        (should= 850.0 (fs/apply-pricing silver 1000)))))

  (context "戦略の合成"
    (it "複数の戦略を合成できる"
      (let [discount (fs/discount-pricing 0.10)
            tax (fs/tax-strategy 0.08)
            composed (fs/compose-strategies discount tax)
            result (fs/apply-pricing composed 1000)]
        ;; 1000 * 0.9 = 900, 900 * 1.08 = 972
        (should (> 0.01 (Math/abs (- 972.0 result))))))

    (it "割引と会員戦略を合成できる"
      (let [member (fs/member-pricing :gold)
            additional (fs/discount-pricing 0.10)
            composed (fs/compose-strategies member additional)]
        ;; 1000 * 0.8 = 800, 800 * 0.9 = 720
        (should= 720.0 (fs/apply-pricing composed 1000)))))

  (context "条件付き戦略"
    (it "条件に基づいて戦略を選択できる"
      (let [high-value-discount (fs/discount-pricing 0.20)
            normal-pricing fs/regular-pricing
            strategy (fs/conditional-strategy
                       #(>= % 5000)
                       high-value-discount
                       normal-pricing)]
        (should= 4800.0 (fs/apply-pricing strategy 6000))
        (should= 3000 (fs/apply-pricing strategy 3000)))))

  (context "税金計算"
    (it "税金を追加できる"
      (let [tax (fs/tax-strategy 0.10)]
        (should= 1100.0 (fs/apply-pricing tax 1000)))))

  (context "最低/最大金額制限"
    (it "最低金額を保証できる"
      (let [heavy-discount (fs/discount-pricing 0.90)
            with-min (fs/with-minimum 100 heavy-discount)]
        (should= 100 (fs/apply-pricing with-min 500))))

    (it "最大金額を制限できる"
      (let [expensive (fs/tax-strategy 1.0)
            with-max (fs/with-maximum 1500 expensive)]
        (should= 1500 (fs/apply-pricing with-max 1000))))))

(run-specs)
