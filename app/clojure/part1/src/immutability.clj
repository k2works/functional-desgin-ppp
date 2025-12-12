(ns immutability
  "第1章: 不変性とデータ変換

   関数型プログラミングにおける不変データ構造の基本から、
   データ変換パイプライン、副作用の分離までを扱います。")

;; =============================================================================
;; 1. 不変データ構造の基本
;; =============================================================================

(defn update-age
  "人物の年齢を更新する（元のデータは変更しない）"
  [person new-age]
  (assoc person :age new-age))

;; =============================================================================
;; 2. 構造共有（Structural Sharing）
;; =============================================================================

(defn add-member
  "チームに新しいメンバーを追加する"
  [team member]
  (update team :members conj member))

;; =============================================================================
;; 3. データ変換パイプライン
;; =============================================================================

(defn calculate-subtotal
  "各アイテムの小計を計算する"
  [item]
  (* (:price item) (:quantity item)))

(defn membership-discount
  "会員種別に応じた割引率を取得する"
  [membership]
  (case membership
    :gold 0.1
    :silver 0.05
    :bronze 0.02
    0))

(defn calculate-total
  "注文の合計金額を計算する"
  [order]
  (->> (:items order)
       (map calculate-subtotal)
       (reduce +)))

(defn apply-discount
  "割引後の金額を計算する"
  [order total]
  (let [discount-rate (-> order :customer :membership membership-discount)]
    (* total (- 1 discount-rate))))

(defn process-order
  "注文を処理し、割引後の合計金額を返す"
  [order]
  (let [total (calculate-total order)]
    (apply-discount order total)))

;; =============================================================================
;; 4. 副作用の分離
;; =============================================================================

(defn pure-calculate-tax
  "純粋関数：税額を計算する"
  [amount tax-rate]
  (* amount tax-rate))

(defn calculate-invoice
  "ビジネスロジック（純粋関数）：請求書を計算する"
  [items tax-rate]
  (let [subtotal (reduce + (map calculate-subtotal items))
        tax (pure-calculate-tax subtotal tax-rate)
        total (+ subtotal tax)]
    {:subtotal subtotal
     :tax tax
     :total total}))

;; 副作用を含む処理（分離）
(defn save-invoice!
  "データベースへの保存（副作用）"
  [invoice]
  (println "Saving invoice:" invoice)
  invoice)

(defn send-notification!
  "メール送信（副作用）"
  [invoice customer-email]
  (println "Sending notification to:" customer-email)
  invoice)

(defn process-and-save-invoice!
  "処理全体のオーケストレーション"
  [items tax-rate customer-email]
  (-> (calculate-invoice items tax-rate)
      save-invoice!
      (send-notification! customer-email)))

;; =============================================================================
;; 5. 永続的データ構造の活用：Undo/Redo の実装
;; =============================================================================

(defn create-history
  "履歴を保持するデータ構造を作成する"
  []
  {:current nil
   :past []
   :future []})

(defn push-state
  "新しい状態を履歴にプッシュする"
  [history new-state]
  (-> history
      (update :past conj (:current history))
      (assoc :current new-state)
      (assoc :future [])))

(defn undo
  "直前の状態に戻す"
  [history]
  (if (empty? (:past history))
    history
    (let [previous (peek (:past history))]
      (-> history
          (update :future conj (:current history))
          (assoc :current previous)
          (update :past pop)))))

(defn redo
  "やり直し操作"
  [history]
  (if (empty? (:future history))
    history
    (let [next-state (peek (:future history))]
      (-> history
          (update :past conj (:current history))
          (assoc :current next-state)
          (update :future pop)))))

;; =============================================================================
;; 6. トランスデューサーによる効率的な変換
;; =============================================================================

(def xf-process-items
  "複数の変換を合成したトランスデューサー"
  (comp
   (filter #(> (:quantity %) 0))
   (map #(assoc % :subtotal (calculate-subtotal %)))
   (filter #(> (:subtotal %) 100))))

(defn process-items-efficiently
  "トランスデューサーを使用した効率的な処理"
  [items]
  (into [] xf-process-items items))
