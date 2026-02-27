(ns strategy-pattern.context
  "Strategy パターン - Context

   Strategy を使用するクライアントコードです。
   戦略を注入して料金計算を行います。"
  (:require [strategy-pattern.pricing :as pricing]))

;; =============================================================================
;; Context: ショッピングカート
;; =============================================================================

(defn make-cart
  "ショッピングカートを作成"
  [items pricing-strategy]
  {:items items
   :strategy pricing-strategy})

(defn cart-total
  "カートの合計金額を計算"
  [cart]
  (let [items (:items cart)
        strategy (:strategy cart)
        subtotal (reduce + (map :price items))]
    (pricing/calculate-price strategy subtotal)))

(defn add-item
  "カートにアイテムを追加"
  [cart item]
  (update cart :items conj item))

(defn change-strategy
  "料金戦略を変更"
  [cart new-strategy]
  (assoc cart :strategy new-strategy))

;; =============================================================================
;; Context: 配送料金計算
;; =============================================================================

(defmulti calculate-shipping
  "配送料金を計算"
  (fn [strategy _weight _distance] (:type strategy)))

(defn make-standard-shipping
  "標準配送戦略"
  []
  {:type :standard-shipping})

(defmethod calculate-shipping :standard-shipping [_strategy weight distance]
  (+ (* weight 10) (* distance 5)))

(defn make-express-shipping
  "速達配送戦略"
  []
  {:type :express-shipping})

(defmethod calculate-shipping :express-shipping [_strategy weight distance]
  (+ (* weight 20) (* distance 15)))

(defn make-free-shipping
  "無料配送戦略"
  [min-order-amount]
  {:type :free-shipping
   :min-order-amount min-order-amount})

(defmethod calculate-shipping :free-shipping [strategy _weight _distance]
  0)

(defn get-shipping-cost
  "配送料金を取得"
  [shipping-strategy weight distance]
  (calculate-shipping shipping-strategy weight distance))
