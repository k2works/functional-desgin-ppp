(ns property-based-testing-spec
  (:require [speclj.core :refer :all]
            [clojure.test.check :as tc]
            [clojure.test.check.generators :as gen]
            [clojure.test.check.properties :as prop]
            [property-based-testing :refer :all]))

(describe "プロパティベーステスト"

  (context "基本的なジェネレータ"
    (it "age-gen は0から150の範囲の値を生成する"
      (let [samples (gen/sample age-gen 100)]
        (should (every? #(and (>= % 0) (<= % 150)) samples))))

    (it "membership-gen は有効な会員種別を生成する"
      (let [samples (gen/sample membership-gen 100)]
        (should (every? #{:bronze :silver :gold :platinum} samples)))))

  (context "複合ジェネレータ"
    (it "person-gen は有効な人物データを生成する"
      (let [samples (gen/sample person-gen 10)]
        (should (every? #(contains? % :name) samples))
        (should (every? #(contains? % :age) samples))
        (should (every? #(contains? % :membership) samples))))

    (it "product-gen は有効な商品データを生成する"
      (let [samples (gen/sample product-gen 10)]
        (should (every? #(re-matches #"PROD-\d{5}" (:product-id %)) samples))
        (should (every? #(pos? (:price %)) samples)))))

  (context "テスト対象の関数"
    (it "reverse-string は文字列を反転する"
      (should= "olleh" (reverse-string "hello"))
      (should= "" (reverse-string "")))

    (it "sort-numbers は数値をソートする"
      (should= '(1 1 2 3 4 5) (sort-numbers [3 1 4 1 5 2]))
      (should= () (sort-numbers [])))

    (it "calculate-discount は割引を適用する"
      (should= 90.0 (calculate-discount 100 0.1))
      (should= 100 (calculate-discount 100 0))
      (should= 0 (calculate-discount 100 1)))

    (it "merge-sorted は2つのソート済みリストをマージする"
      (should= [1 2 3 4 5 6] (merge-sorted [1 3 5] [2 4 6]))
      (should= [1 2 3] (merge-sorted [1 2 3] []))
      (should= [] (merge-sorted [] [])))

    (it "encode-run-length はランレングス圧縮する"
      (should= [[\a 3] [\b 2] [\c 1]] (encode-run-length "aaabbc")))

    (it "decode-run-length はランレングス展開する"
      (should= "aaabbc" (decode-run-length [[\a 3] [\b 2] [\c 1]]))))

  (context "プロパティベーステスト"
    (it "文字列を2回反転すると元に戻る"
      (let [result (tc/quick-check 100 prop-reverse-involutory)]
        (should (:pass? result))))

    (it "反転しても長さは変わらない"
      (let [result (tc/quick-check 100 prop-reverse-length-preserved)]
        (should (:pass? result))))

    (it "ソートは冪等"
      (let [result (tc/quick-check 100 prop-sort-idempotent)]
        (should (:pass? result))))

    (it "ソートは要素を保存する"
      (let [result (tc/quick-check 100 prop-sort-preserves-elements)]
        (should (:pass? result))))

    (it "ソート結果は昇順"
      (let [result (tc/quick-check 100 prop-sort-ordered)]
        (should (:pass? result))))

    (it "割引後の価格は適切な範囲内"
      (let [result (tc/quick-check 100 prop-discount-bounds)]
        (should (:pass? result))))

    (it "マージ結果はソート済み"
      (let [result (tc/quick-check 100 prop-merge-sorted-is-sorted)]
        (should (:pass? result))))

    (it "ランレングス符号化は可逆"
      (let [result (tc/quick-check 100 prop-run-length-roundtrip)]
        (should (:pass? result)))))

  (context "注文に関するプロパティ"
    (it "注文合計は常に正"
      (let [result (tc/quick-check 100 prop-order-total-positive)]
        (should (:pass? result))))

    (it "注文合計は各アイテムの合計と等しい"
      (let [result (tc/quick-check 100 prop-order-total-sum-of-items)]
        (should (:pass? result)))))

  (context "run-property ユーティリティ"
    (it "プロパティを実行してレポートを返す"
      (let [result (run-property prop-reverse-involutory 50)]
        (should (:pass? result))
        (should= 50 (:num-tests result)))))

  (context "calculate-order-total"
    (it "注文合計を正しく計算する"
      (let [order {:order-id "ORD-00000001"
                   :items [{:product-id "PROD-00001" :quantity 2 :price 1000}
                           {:product-id "PROD-00002" :quantity 3 :price 500}]}]
        (should= 3500 (calculate-order-total order))))))

(run-specs)
