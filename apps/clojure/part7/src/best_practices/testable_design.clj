(ns best-practices.testable-design
  "テスト可能な設計のベストプラクティス")

;; ============================================
;; 1. 依存性注入（関数パラメータ）
;; ============================================

;; 悪い例: 外部依存が埋め込まれている
;; (defn get-user-bad [id]
;;   (db/query "SELECT * FROM users WHERE id = ?" id))

;; 良い例: 依存性を注入
(defn get-user
  "ユーザーを取得（リポジトリを注入）"
  [repository id]
  ((:find-by-id repository) id))

(defn save-user
  "ユーザーを保存（リポジトリを注入）"
  [repository user]
  ((:save repository) user))

;; テスト用のモックリポジトリ
(defn make-mock-repository
  "テスト用モックリポジトリを作成"
  [initial-data]
  (let [data (atom initial-data)]
    {:find-by-id (fn [id]
                   (first (filter #(= (:id %) id) @data)))
     :find-all (fn []
                 @data)
     :save (fn [entity]
             (swap! data conj entity)
             entity)
     :delete (fn [id]
               (swap! data (fn [d] (remove #(= (:id %) id) d))))}))

;; ============================================
;; 2. 時間の抽象化
;; ============================================

;; 悪い例: 時間が埋め込まれている
;; (defn create-order-bad [items]
;;   {:items items :created-at (System/currentTimeMillis)})

;; 良い例: 時間を注入
(defn create-order
  "注文を作成（現在時刻を注入）"
  [items now-fn]
  {:items items :created-at (now-fn)})

(defn is-expired?
  "注文が期限切れかどうか判定"
  [order now-fn expiry-duration-ms]
  (let [age (- (now-fn) (:created-at order))]
    (> age expiry-duration-ms)))

;; テスト用の固定時刻関数
(defn make-fixed-clock
  "テスト用の固定時刻を返す関数を作成"
  [fixed-time]
  (fn [] fixed-time))

;; ============================================
;; 3. ランダム性の抽象化
;; ============================================

;; 悪い例: ランダム性が埋め込まれている
;; (defn generate-id-bad []
;;   (java.util.UUID/randomUUID))

;; 良い例: ランダム性を注入
(defn generate-id
  "IDを生成（ID生成関数を注入）"
  [id-gen-fn]
  (id-gen-fn))

(defn create-entity
  "エンティティを作成（依存性を注入）"
  [data id-gen-fn now-fn]
  (assoc data
         :id (id-gen-fn)
         :created-at (now-fn)))

;; テスト用のシーケンシャルID生成器
(defn make-sequential-id-gen
  "テスト用のシーケンシャルID生成器を作成"
  []
  (let [counter (atom 0)]
    (fn []
      (swap! counter inc)
      (str "id-" @counter))))

;; ============================================
;; 4. 設定の分離
;; ============================================

(defn make-config
  "設定を作成"
  [& {:keys [tax-rate discount-rate currency]
      :or {tax-rate 0.1 discount-rate 0.0 currency "JPY"}}]
  {:tax-rate tax-rate
   :discount-rate discount-rate
   :currency currency})

(defn calculate-price
  "価格を計算（設定を注入）"
  [config base-price]
  (let [discounted (* base-price (- 1.0 (:discount-rate config)))
        with-tax (* discounted (+ 1.0 (:tax-rate config)))]
    {:base-price base-price
     :discounted discounted
     :tax (* discounted (:tax-rate config))
     :total with-tax
     :currency (:currency config)}))

;; ============================================
;; 5. エラーハンドリングの分離
;; ============================================

(defn validate-input
  "入力を検証し、結果を返す"
  [input validations]
  (let [errors (keep (fn [[field validation]]
                       (let [value (get input field)]
                         (when-not (validation value)
                           field)))
                     validations)]
    (if (empty? errors)
      {:valid true :data input}
      {:valid false :errors errors})))

(defn process-with-validation
  "検証付きで処理を実行"
  [input validations process-fn error-fn]
  (let [result (validate-input input validations)]
    (if (:valid result)
      (process-fn (:data result))
      (error-fn (:errors result)))))

;; 検証ルールの定義
(def user-validations
  {:name (fn [v] (and (string? v) (not (empty? v))))
   :email (fn [v] (and (string? v) (re-matches #"^[^@]+@[^@]+\.[^@]+$" v)))
   :age (fn [v] (and (number? v) (>= v 0)))})

;; ============================================
;; 6. テスト容易なインターフェース
;; ============================================

(defprotocol Notifier
  "通知インターフェース"
  (send-notification [this recipient message]))

;; 本番用実装
(defrecord EmailNotifier [smtp-config]
  Notifier
  (send-notification [_ recipient message]
    ;; 実際のメール送信ロジック（副作用）
    {:sent true :recipient recipient :message message}))

;; テスト用実装
(defrecord MockNotifier [sent-messages]
  Notifier
  (send-notification [_ recipient message]
    (swap! sent-messages conj {:recipient recipient :message message})
    {:sent true :recipient recipient :message message}))

(defn make-mock-notifier
  "テスト用モック通知サービスを作成"
  []
  (->MockNotifier (atom [])))

(defn get-sent-messages
  "送信されたメッセージを取得（テスト用）"
  [mock-notifier]
  @(:sent-messages mock-notifier))
