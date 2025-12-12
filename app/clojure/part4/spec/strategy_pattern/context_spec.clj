(ns strategy-pattern.context-spec
  (:require [speclj.core :refer :all]
            [strategy-pattern.context :as ctx]
            [strategy-pattern.pricing :as pricing]))

(describe "Strategy パターン - Context"

  (context "ショッピングカート"
    (it "カートを作成できる"
      (let [items [{:name "Item A" :price 100}
                   {:name "Item B" :price 200}]
            strategy (pricing/make-regular-pricing)
            cart (ctx/make-cart items strategy)]
        (should= 2 (count (:items cart)))
        (should= :regular (:type (:strategy cart)))))

    (it "通常料金で合計を計算できる"
      (let [items [{:name "Item A" :price 100}
                   {:name "Item B" :price 200}]
            strategy (pricing/make-regular-pricing)
            cart (ctx/make-cart items strategy)]
        (should= 300 (ctx/cart-total cart))))

    (it "割引料金で合計を計算できる"
      (let [items [{:name "Item A" :price 100}
                   {:name "Item B" :price 200}]
            strategy (pricing/make-discount-pricing 0.10)
            cart (ctx/make-cart items strategy)]
        (should= 270.0 (ctx/cart-total cart))))

    (it "会員料金で合計を計算できる"
      (let [items [{:name "Item A" :price 500}
                   {:name "Item B" :price 500}]
            strategy (pricing/make-member-pricing :gold)
            cart (ctx/make-cart items strategy)]
        (should= 800.0 (ctx/cart-total cart))))

    (it "アイテムを追加できる"
      (let [cart (ctx/make-cart [] (pricing/make-regular-pricing))
            cart (ctx/add-item cart {:name "New Item" :price 150})]
        (should= 1 (count (:items cart)))
        (should= 150 (ctx/cart-total cart))))

    (it "戦略を変更できる"
      (let [items [{:name "Item" :price 1000}]
            cart (ctx/make-cart items (pricing/make-regular-pricing))
            cart (ctx/change-strategy cart (pricing/make-discount-pricing 0.20))]
        (should= :discount (:type (:strategy cart)))
        (should= 800.0 (ctx/cart-total cart)))))

  (context "配送料金計算"
    (it "標準配送料金を計算できる"
      (let [strategy (ctx/make-standard-shipping)]
        (should= 75 (ctx/get-shipping-cost strategy 5 5))))

    (it "速達配送料金を計算できる"
      (let [strategy (ctx/make-express-shipping)]
        (should= 175 (ctx/get-shipping-cost strategy 5 5))))

    (it "無料配送は0を返す"
      (let [strategy (ctx/make-free-shipping 5000)]
        (should= 0 (ctx/get-shipping-cost strategy 5 5))))))

(run-specs)
