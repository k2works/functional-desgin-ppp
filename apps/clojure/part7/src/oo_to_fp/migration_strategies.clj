(ns oo-to-fp.migration-strategies
  "移行戦略: OOからFPへの段階的な移行パターン"
  (:require [oo-to-fp.fp-style :as fp]))

;; ============================================
;; 戦略1: ラッパー関数による移行
;; ============================================

(defn wrap-with-immutability
  "OOスタイルの関数をイミュータブルなラッパーで包む"
  [oo-object]
  ;; OOオブジェクトの現在の状態をスナップショット
  {:id ((:get-id oo-object))
   :balance ((:get-balance oo-object))
   :transactions ((:get-transactions oo-object))})

;; ============================================
;; 戦略2: Strangler Fig パターン
;; ============================================

;; 古いコードと新しいコードを並行して動作させる
(defn create-account-strangler
  "段階的移行: 新旧両方のインターフェースをサポート"
  [id initial-balance use-fp?]
  (if use-fp?
    ;; 新しいFPスタイル
    {:style :fp
     :data (fp/make-account id initial-balance)}
    ;; 古いOOスタイル（参照用）
    {:style :oo
     :data {:id id :balance initial-balance :transactions []}}))

(defn account-deposit
  "統一されたインターフェースでの入金"
  [account amount]
  (if (= :fp (:style account))
    (update account :data fp/deposit amount)
    ;; OOスタイルの場合も同じデータ構造で処理
    (update account :data
            (fn [data]
              (-> data
                  (update :balance + amount)
                  (update :transactions conj {:type :deposit :amount amount}))))))

;; ============================================
;; 戦略3: アダプターパターン
;; ============================================

(defprotocol AccountOperations
  "口座操作のプロトコル"
  (get-account-balance [this])
  (deposit-to-account [this amount])
  (withdraw-from-account [this amount]))

;; FPスタイルのアダプター
(defrecord FPAccountAdapter [account-atom]
  AccountOperations
  (get-account-balance [_]
    (:balance @account-atom))
  (deposit-to-account [_ amount]
    (swap! account-atom fp/deposit amount)
    (:balance @account-atom))
  (withdraw-from-account [_ amount]
    (swap! account-atom fp/withdraw amount)
    (:balance @account-atom)))

(defn make-fp-account-adapter
  "FPスタイルの口座をアダプターでラップ"
  [id initial-balance]
  (->FPAccountAdapter (atom (fp/make-account id initial-balance))))

;; ============================================
;; 戦略4: イベントソーシング移行
;; ============================================

(defn account-event
  "口座イベントを作成"
  [event-type data]
  {:event-type event-type
   :data data
   :timestamp (System/currentTimeMillis)})

(defn apply-event
  "イベントを口座に適用"
  [account event]
  (case (:event-type event)
    :created (merge account (:data event))
    :deposited (fp/deposit account (:amount (:data event)))
    :withdrawn (fp/withdraw account (:amount (:data event)))
    account))

(defn replay-events
  "イベントをリプレイして状態を再構築"
  [events]
  (reduce apply-event {} events))

(defn migrate-to-event-sourcing
  "既存の口座データをイベントソーシング形式に変換"
  [account]
  (let [creation-event (account-event :created
                                      {:id (:id account)
                                       :balance 0
                                       :transactions []})
        transaction-events (map (fn [tx]
                                  (account-event
                                   (if (= :deposit (:type tx))
                                     :deposited
                                     :withdrawn)
                                   tx))
                                (:transactions account))]
    (cons creation-event transaction-events)))

;; ============================================
;; 戦略5: 段階的な関数抽出
;; ============================================

(defn extract-pure-logic
  "副作用を含むコードから純粋ロジックを抽出"
  [])

;; Step 1: 計算ロジックを純粋関数に抽出
(defn calculate-interest
  "利息計算（純粋関数）"
  [balance rate days]
  (* balance rate (/ days 365.0)))

(defn calculate-fee
  "手数料計算（純粋関数）"
  [balance fee-structure]
  (cond
    (< balance (:minimum-balance fee-structure)) (:low-balance-fee fee-structure)
    (> balance (:premium-threshold fee-structure)) 0
    :else (:standard-fee fee-structure)))

;; Step 2: 業務ルールを純粋関数として表現
(defn can-withdraw?
  "出金可能かどうかを判定（純粋関数）"
  [account amount overdraft-limit]
  (>= (+ (:balance account) overdraft-limit) amount))

(defn calculate-new-balance
  "新しい残高を計算（純粋関数）"
  [current-balance operation amount]
  (case operation
    :deposit (+ current-balance amount)
    :withdraw (- current-balance amount)
    current-balance))

;; Step 3: 副作用を境界に押し出す
(defn process-transaction
  "取引を処理（副作用なし）"
  [account operation amount rules]
  (let [{:keys [overdraft-limit]} rules
        can-process? (case operation
                       :deposit true
                       :withdraw (can-withdraw? account amount overdraft-limit))]
    (if can-process?
      {:success true
       :account (-> account
                    (update :balance calculate-new-balance operation amount)
                    (update :transactions conj {:type operation :amount amount}))}
      {:success false
       :account account
       :error "Insufficient funds"})))
