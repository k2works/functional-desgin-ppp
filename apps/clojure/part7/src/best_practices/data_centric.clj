(ns best-practices.data-centric
  "データ中心設計のベストプラクティス
   - データをシンプルな構造で表現
   - 関数はデータを変換する")

;; ============================================
;; 1. データファースト - データ構造の定義
;; ============================================

(defn make-user
  "ユーザーデータを作成
   データはプレーンなマップで表現"
  [id name email]
  {:id id
   :name name
   :email email
   :created-at (System/currentTimeMillis)})

(defn make-order
  "注文データを作成"
  [id user-id items]
  {:id id
   :user-id user-id
   :items items
   :status :pending
   :created-at (System/currentTimeMillis)})

(defn make-order-item
  "注文アイテムを作成"
  [product-id quantity price]
  {:product-id product-id
   :quantity quantity
   :price price})

;; ============================================
;; 2. 小さな純粋関数
;; ============================================

(defn calculate-item-total
  "アイテムの合計金額を計算"
  [item]
  (* (:quantity item) (:price item)))

(defn calculate-order-total
  "注文の合計金額を計算"
  [order]
  (reduce + 0 (map calculate-item-total (:items order))))

(defn apply-discount
  "割引を適用"
  [total discount-rate]
  (* total (- 1.0 discount-rate)))

;; ============================================
;; 3. データ変換パイプライン
;; ============================================

(defn enrich-order
  "注文データを拡張"
  [order]
  (assoc order :total (calculate-order-total order)))

(defn apply-tax
  "税金を適用"
  [order tax-rate]
  (let [total (:total order)
        tax (* total tax-rate)]
    (assoc order
           :tax tax
           :grand-total (+ total tax))))

(defn process-order
  "注文を処理（データ変換のパイプライン）"
  [order discount-rate tax-rate]
  (-> order
      enrich-order
      (update :total apply-discount discount-rate)
      (apply-tax tax-rate)
      (assoc :status :processed)))

;; ============================================
;; 4. データの検証（仕様）
;; ============================================

(defn valid-email?
  "メールアドレスの形式を検証"
  [email]
  (and (string? email)
       (re-matches #"^[^@]+@[^@]+\.[^@]+$" email)))

(defn valid-user?
  "ユーザーデータの妥当性を検証"
  [user]
  (and (map? user)
       (string? (:name user))
       (not (empty? (:name user)))
       (valid-email? (:email user))))

(defn valid-order-item?
  "注文アイテムの妥当性を検証"
  [item]
  (and (map? item)
       (pos? (:quantity item))
       (pos? (:price item))))

(defn valid-order?
  "注文データの妥当性を検証"
  [order]
  (and (map? order)
       (not (empty? (:items order)))
       (every? valid-order-item? (:items order))))

;; ============================================
;; 5. イミュータブルな更新
;; ============================================

(defn update-user-email
  "ユーザーのメールアドレスを更新（イミュータブル）"
  [user new-email]
  (if (valid-email? new-email)
    (assoc user :email new-email :updated-at (System/currentTimeMillis))
    user))

(defn add-order-item
  "注文にアイテムを追加（イミュータブル）"
  [order item]
  (if (valid-order-item? item)
    (update order :items conj item)
    order))

(defn cancel-order
  "注文をキャンセル（イミュータブル）"
  [order]
  (if (= :pending (:status order))
    (assoc order :status :cancelled :cancelled-at (System/currentTimeMillis))
    order))
