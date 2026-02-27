(ns strategy-pattern.functional-strategy
  "Strategy パターン - 関数型アプローチ

   高階関数を使った Strategy パターンの実装です。
   関数を戦略として直接渡すことができます。")

;; =============================================================================
;; 関数による Strategy
;; =============================================================================

(defn apply-pricing
  "料金戦略を適用"
  [strategy-fn amount]
  (strategy-fn amount))

;; 戦略関数の定義
(def regular-pricing identity)

(defn discount-pricing
  "割引戦略を作成"
  [rate]
  (fn [amount]
    (* amount (- 1.0 rate))))

(defn member-pricing
  "会員戦略を作成"
  [level]
  (let [rate (case level
               :gold 0.20
               :silver 0.15
               :bronze 0.10
               0.0)]
    (fn [amount]
      (* amount (- 1.0 rate)))))

;; =============================================================================
;; 戦略の合成
;; =============================================================================

(defn compose-strategies
  "複数の戦略を合成"
  [& strategies]
  (fn [amount]
    (reduce (fn [a strategy] (strategy a)) amount strategies)))

(defn conditional-strategy
  "条件付き戦略"
  [pred then-strategy else-strategy]
  (fn [amount]
    (if (pred amount)
      (then-strategy amount)
      (else-strategy amount))))

;; =============================================================================
;; 税金計算の例
;; =============================================================================

(defn tax-strategy
  "税金戦略を作成"
  [tax-rate]
  (fn [amount]
    (* amount (+ 1.0 tax-rate))))

(defn with-minimum
  "最低金額を保証する戦略"
  [min-amount strategy-fn]
  (fn [amount]
    (max min-amount (strategy-fn amount))))

(defn with-maximum
  "最大金額を制限する戦略"
  [max-amount strategy-fn]
  (fn [amount]
    (min max-amount (strategy-fn amount))))
