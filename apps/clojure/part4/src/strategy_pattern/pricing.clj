(ns strategy-pattern.pricing
  "Strategy パターン - 料金計算

   料金計算のアルゴリズムを交換可能にするパターンの例です。
   マルチメソッドを使って、異なる計算戦略を実装します。")

;; =============================================================================
;; Strategy インターフェース
;; =============================================================================

(defmulti calculate-price
  "料金を計算する"
  (fn [strategy _amount] (:type strategy)))

;; =============================================================================
;; Concrete Strategy: 通常料金
;; =============================================================================

(defn make-regular-pricing
  "通常料金戦略を作成"
  []
  {:type :regular})

(defmethod calculate-price :regular [_strategy amount]
  amount)

;; =============================================================================
;; Concrete Strategy: 割引料金
;; =============================================================================

(defn make-discount-pricing
  "割引料金戦略を作成"
  [discount-rate]
  {:type :discount
   :discount-rate discount-rate})

(defmethod calculate-price :discount [strategy amount]
  (let [rate (:discount-rate strategy)]
    (* amount (- 1.0 rate))))

;; =============================================================================
;; Concrete Strategy: 会員料金
;; =============================================================================

(defn make-member-pricing
  "会員料金戦略を作成"
  [member-level]
  {:type :member
   :member-level member-level})

(defmethod calculate-price :member [strategy amount]
  (let [level (:member-level strategy)
        rate (case level
               :gold 0.20
               :silver 0.15
               :bronze 0.10
               0.0)]
    (* amount (- 1.0 rate))))

;; =============================================================================
;; Concrete Strategy: 数量割引
;; =============================================================================

(defn make-bulk-pricing
  "数量割引戦略を作成"
  [threshold bulk-discount]
  {:type :bulk
   :threshold threshold
   :bulk-discount bulk-discount})

(defmethod calculate-price :bulk [strategy {:keys [unit-price quantity]}]
  (let [threshold (:threshold strategy)
        discount (:bulk-discount strategy)
        total (* unit-price quantity)]
    (if (>= quantity threshold)
      (* total (- 1.0 discount))
      total)))
