(ns oo-to-fp.fp-style
  "関数型スタイルへの移行後のコード
   OOスタイルを関数型に変換した例")

;; ============================================
;; FPスタイル: データ + 関数
;; ============================================

;; 関数型での銀行口座
(defn make-account
  "FPスタイル: 口座データを作成
   プレーンなマップとして表現"
  [id initial-balance]
  {:id id
   :balance initial-balance
   :transactions []})

(defn get-balance
  "残高を取得"
  [account]
  (:balance account))

(defn get-transactions
  "取引履歴を取得"
  [account]
  (:transactions account))

(defn deposit
  "入金（純粋関数: 新しい口座を返す）"
  [account amount]
  (if (pos? amount)
    (-> account
        (update :balance + amount)
        (update :transactions conj
                {:type :deposit
                 :amount amount}))
    account))

(defn withdraw
  "出金（純粋関数: 新しい口座を返す）"
  [account amount]
  (if (and (pos? amount)
           (>= (:balance account) amount))
    (-> account
        (update :balance - amount)
        (update :transactions conj
                {:type :withdrawal
                 :amount amount}))
    account))

;; 複数の操作を組み合わせる
(defn transfer
  "送金（純粋関数）"
  [from-account to-account amount]
  (if (>= (:balance from-account) amount)
    {:from (withdraw from-account amount)
     :to (deposit to-account amount)
     :success true}
    {:from from-account
     :to to-account
     :success false}))

;; ============================================
;; FPスタイル: マルチメソッドによる多態性
;; ============================================

(defn make-circle
  "円データを作成"
  [x y radius]
  {:type :circle
   :x x
   :y y
   :radius radius})

(defn make-rectangle
  "矩形データを作成"
  [x y width height]
  {:type :rectangle
   :x x
   :y y
   :width width
   :height height})

;; マルチメソッドで多態性を実現
(defmulti area
  "図形の面積を計算"
  :type)

(defmethod area :circle
  [shape]
  (* Math/PI (:radius shape) (:radius shape)))

(defmethod area :rectangle
  [shape]
  (* (:width shape) (:height shape)))

(defmulti perimeter
  "図形の周囲長を計算"
  :type)

(defmethod perimeter :circle
  [shape]
  (* 2 Math/PI (:radius shape)))

(defmethod perimeter :rectangle
  [shape]
  (* 2 (+ (:width shape) (:height shape))))

;; 図形の移動（純粋関数）
(defn move
  "図形を移動"
  [shape dx dy]
  (-> shape
      (update :x + dx)
      (update :y + dy)))

;; 図形の拡大（マルチメソッド）
(defmulti scale
  "図形を拡大"
  :type)

(defmethod scale :circle
  [shape factor]
  (update shape :radius * factor))

(defmethod scale :rectangle
  [shape factor]
  (-> shape
      (update :width * factor)
      (update :height * factor)))

;; ============================================
;; FPスタイル: イベント駆動（データとして表現）
;; ============================================

(defn make-event-system
  "イベントシステムのデータ構造を作成"
  []
  {:handlers {}
   :event-log []})

(defn subscribe
  "イベントを購読（純粋関数）"
  [system event-type handler]
  (update-in system [:handlers event-type]
             (fnil conj []) handler))

(defn publish
  "イベントを発行し、ハンドラを実行
   返り値: 更新されたシステム状態と実行結果"
  [system event-type data]
  (let [handlers (get-in system [:handlers event-type] [])
        event {:type event-type :data data}
        results (mapv #(% event) handlers)]
    {:system (update system :event-log conj event)
     :results results}))

(defn get-event-log
  "イベントログを取得"
  [system]
  (:event-log system))
