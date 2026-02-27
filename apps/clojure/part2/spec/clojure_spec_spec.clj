(ns clojure-spec-spec
  (:require [speclj.core :refer :all]
            [clojure.spec.alpha :as s]
            [clojure.spec.gen.alpha :as gen]
            [clojure-spec :refer :all]))

(describe "Clojure Spec による仕様定義"

  (context "基本的なスペック定義"
    (it "name スペックは有効な名前を検証する"
      (should (s/valid? :clojure-spec/name "田中太郎"))
      (should-not (s/valid? :clojure-spec/name ""))
      (should-not (s/valid? :clojure-spec/name (apply str (repeat 101 "a")))))

    (it "age スペックは有効な年齢を検証する"
      (should (s/valid? :clojure-spec/age 25))
      (should (s/valid? :clojure-spec/age 0))
      (should (s/valid? :clojure-spec/age 150))
      (should-not (s/valid? :clojure-spec/age -1))
      (should-not (s/valid? :clojure-spec/age 151)))

    (it "email スペックは有効なメールを検証する"
      (should (s/valid? :clojure-spec/email "test@example.com"))
      (should-not (s/valid? :clojure-spec/email "invalid-email")))

    (it "membership スペックは列挙値を検証する"
      (should (s/valid? :clojure-spec/membership :gold))
      (should (s/valid? :clojure-spec/membership :silver))
      (should-not (s/valid? :clojure-spec/membership :diamond))))

  (context "コレクションのスペック"
    (it "tags スペックはベクターを検証する"
      (should (s/valid? :clojure-spec/tags ["tag1" "tag2"]))
      (should (s/valid? :clojure-spec/tags []))
      (should-not (s/valid? :clojure-spec/tags '("tag1")))
      (should-not (s/valid? :clojure-spec/tags (vec (repeat 11 "tag")))))

    (it "person スペックはマップを検証する"
      (should (s/valid? :clojure-spec/person {:name "田中" :age 30}))
      (should (s/valid? :clojure-spec/person {:name "田中" :age 30 :email "tanaka@example.com"}))
      (should-not (s/valid? :clojure-spec/person {:name "田中"}))
      (should-not (s/valid? :clojure-spec/person {:age 30}))))

  (context "商品と注文のドメインモデル"
    (it "product-id スペックは商品IDを検証する"
      (should (s/valid? :clojure-spec/product-id "PROD-00001"))
      (should (s/valid? :clojure-spec/product-id "PROD-99999"))
      (should-not (s/valid? :clojure-spec/product-id "PROD-1"))
      (should-not (s/valid? :clojure-spec/product-id "PRD-00001")))

    (it "product スペックは商品を検証する"
      (should (s/valid? :clojure-spec/product
                        {:product-id "PROD-00001"
                         :product-name "テスト商品"
                         :price 1000}))
      (should (s/valid? :clojure-spec/product
                        {:product-id "PROD-00001"
                         :product-name "テスト商品"
                         :price 1000
                         :category :electronics})))

    (it "order スペックは注文を検証する"
      (should (s/valid? :clojure-spec/order
                        {:order-id "ORD-00000001"
                         :customer-id "CUST-000001"
                         :items [{:product-id "PROD-00001" :quantity 2 :price 1000}]
                         :order-date (java.util.Date.)}))))

  (context "関数仕様の定義（fdef）"
    (it "calculate-item-total は正しく計算する"
      (should= 2000 (calculate-item-total {:product-id "PROD-00001"
                                           :quantity 2
                                           :price 1000}))
      (should= 1500 (calculate-item-total {:product-id "PROD-00002"
                                           :quantity 3
                                           :price 500})))

    (it "calculate-order-total は注文全体を計算する"
      (let [order {:order-id "ORD-00000001"
                   :customer-id "CUST-000001"
                   :items [{:product-id "PROD-00001" :quantity 2 :price 1000}
                           {:product-id "PROD-00002" :quantity 3 :price 500}]
                   :order-date (java.util.Date.)}]
        (should= 3500 (calculate-order-total order))))

    (it "apply-discount は割引を適用する"
      (should= 900.0 (apply-discount 1000 0.1))
      (should= 800.0 (apply-discount 1000 0.2))
      (should= 1000 (apply-discount 1000 0))))

  (context "多引数と可変長引数のスペック"
    (it "create-person は2引数または3引数で動作する"
      (should= {:name "田中" :age 30} (create-person "田中" 30))
      (should= {:name "田中" :age 30 :email "tanaka@example.com"}
               (create-person "田中" 30 "tanaka@example.com")))

    (it "sum-prices は複数の価格を合計する"
      (should= 0 (sum-prices))
      (should= 100 (sum-prices 100))
      (should= 300 (sum-prices 100 200))))

  (context "条件付きスペック（マルチスペック）"
    (it "email 通知を検証する"
      (should (s/valid? :clojure-spec/notification
                        {:type :email
                         :to "test@example.com"
                         :subject "テスト"
                         :body "本文"})))

    (it "SMS 通知を検証する"
      (should (s/valid? :clojure-spec/notification
                        {:type :sms
                         :phone-number "090-1234-5678"
                         :body "本文"})))

    (it "push 通知を検証する"
      (should (s/valid? :clojure-spec/notification
                        {:type :push
                         :device-token "token123"
                         :body "本文"})))

    (it "不正な通知タイプは拒否する"
      (should-not (s/valid? :clojure-spec/notification
                            {:type :unknown
                             :body "本文"}))))

  (context "バリデーションとエラーハンドリング"
    (it "validate-person は有効なデータで valid: true を返す"
      (let [result (validate-person {:name "田中" :age 30})]
        (should (:valid result))
        (should= {:name "田中" :age 30} (:data result))))

    (it "validate-person は無効なデータで valid: false を返す"
      (let [result (validate-person {:name "" :age 30})]
        (should-not (:valid result))
        (should-not-be-nil (:errors result))))

    (it "conform-or-throw は有効なデータで値を返す"
      (should= {:name "田中" :age 30}
               (conform-or-throw :clojure-spec/person {:name "田中" :age 30})))

    (it "conform-or-throw は無効なデータで例外をスロー"
      (should-throw clojure.lang.ExceptionInfo
                    (conform-or-throw :clojure-spec/person {:name "" :age 30}))))

  (context "データ生成ユーティリティ"
    (it "generate-sample は指定数のサンプルを生成する"
      (let [samples (generate-sample :clojure-spec/age 5)]
        (should= 5 (count samples))
        (should (every? #(s/valid? :clojure-spec/age %) samples))))))

(run-specs)
