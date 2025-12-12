(ns polymorphism
  "第3章: 多態性とディスパッチ

   Clojure における多態性の実現方法を学びます。
   マルチメソッド、プロトコル、レコードを活用した
   柔軟な多態的設計パターンを扱います。")

;; =============================================================================
;; 1. マルチメソッド（Multimethods）
;; =============================================================================

;; ディスパッチ関数を定義
(defmulti calculate-area
  "図形の面積を計算するマルチメソッド"
  :shape)

;; 各図形タイプに対する実装
(defmethod calculate-area :rectangle
  [{:keys [width height]}]
  (* width height))

(defmethod calculate-area :circle
  [{:keys [radius]}]
  (* Math/PI radius radius))

(defmethod calculate-area :triangle
  [{:keys [base height]}]
  (/ (* base height) 2))

(defmethod calculate-area :default
  [shape]
  (throw (ex-info "未知の図形タイプ" {:shape shape})))

;; =============================================================================
;; 2. 複合ディスパッチ
;; =============================================================================

;; 複数の値に基づくディスパッチ
(defmulti process-payment
  "支払いを処理するマルチメソッド（支払い方法と通貨でディスパッチ）"
  (fn [payment] [(:method payment) (:currency payment)]))

(defmethod process-payment [:credit-card :jpy]
  [payment]
  {:status :processed
   :message "クレジットカード（円）で処理しました"
   :amount (:amount payment)})

(defmethod process-payment [:credit-card :usd]
  [payment]
  {:status :processed
   :message "Credit card (USD) processed"
   :amount (:amount payment)
   :converted (* (:amount payment) 150)})

(defmethod process-payment [:bank-transfer :jpy]
  [payment]
  {:status :pending
   :message "銀行振込を受け付けました"
   :amount (:amount payment)})

(defmethod process-payment :default
  [payment]
  {:status :error
   :message "サポートされていない支払い方法です"})

;; =============================================================================
;; 3. 階層的ディスパッチ
;; =============================================================================

;; 型階層を定義
(derive ::savings ::account)
(derive ::checking ::account)
(derive ::premium-savings ::savings)

(defmulti calculate-interest
  "利息を計算するマルチメソッド（口座タイプでディスパッチ）"
  :account-type)

(defmethod calculate-interest ::savings
  [{:keys [balance]}]
  (* balance 0.02))

(defmethod calculate-interest ::premium-savings
  [{:keys [balance]}]
  (* balance 0.05))

(defmethod calculate-interest ::checking
  [{:keys [balance]}]
  (* balance 0.001))

(defmethod calculate-interest ::account
  [{:keys [balance]}]
  (* balance 0.01))

;; =============================================================================
;; 4. プロトコル（Protocols）
;; =============================================================================

(defprotocol Drawable
  "描画可能なオブジェクトのプロトコル"
  (draw [this] "オブジェクトを描画する")
  (bounding-box [this] "バウンディングボックスを取得する"))

(defprotocol Transformable
  "変換可能なオブジェクトのプロトコル"
  (translate [this dx dy] "移動する")
  (scale [this factor] "拡大・縮小する")
  (rotate [this angle] "回転する"))

;; =============================================================================
;; 5. レコード（Records）
;; =============================================================================

(defrecord Rectangle [x y width height]
  Drawable
  (draw [this]
    (str "Rectangle at (" x "," y ") with size " width "x" height))
  (bounding-box [this]
    {:x x :y y :width width :height height})

  Transformable
  (translate [this dx dy]
    (->Rectangle (+ x dx) (+ y dy) width height))
  (scale [this factor]
    (->Rectangle x y (* width factor) (* height factor)))
  (rotate [this angle]
    ;; 簡略化：中心を基準に回転した新しい矩形を返す
    this))

(defrecord Circle [x y radius]
  Drawable
  (draw [this]
    (str "Circle at (" x "," y ") with radius " radius))
  (bounding-box [this]
    {:x (- x radius) :y (- y radius)
     :width (* 2 radius) :height (* 2 radius)})

  Transformable
  (translate [this dx dy]
    (->Circle (+ x dx) (+ y dy) radius))
  (scale [this factor]
    (->Circle x y (* radius factor)))
  (rotate [this angle]
    this))

;; =============================================================================
;; 6. 既存の型にプロトコルを拡張
;; =============================================================================

(defprotocol Stringable
  "文字列に変換可能なプロトコル"
  (to-string [this] "文字列表現を返す"))

;; マップに対する実装
(extend-protocol Stringable
  clojure.lang.IPersistentMap
  (to-string [this]
    (str "{" (clojure.string/join ", "
                                   (map (fn [[k v]] (str (name k) ": " v)) this)) "}"))

  clojure.lang.IPersistentVector
  (to-string [this]
    (str "[" (clojure.string/join ", " this) "]"))

  java.lang.String
  (to-string [this] this)

  java.lang.Number
  (to-string [this] (str this))

  nil
  (to-string [this] "nil"))

;; =============================================================================
;; 7. コンポーネントパターン
;; =============================================================================

(defprotocol Lifecycle
  "ライフサイクル管理プロトコル"
  (start [this] "コンポーネントを開始する")
  (stop [this] "コンポーネントを停止する"))

(defrecord DatabaseConnection [host port connected?]
  Lifecycle
  (start [this]
    (println "データベースに接続中:" host ":" port)
    (assoc this :connected? true))
  (stop [this]
    (println "データベース接続を切断中")
    (assoc this :connected? false)))

(defrecord WebServer [port db running?]
  Lifecycle
  (start [this]
    (println "Webサーバーを起動中 ポート:" port)
    (let [started-db (start db)]
      (assoc this :db started-db :running? true)))
  (stop [this]
    (println "Webサーバーを停止中")
    (let [stopped-db (stop db)]
      (assoc this :db stopped-db :running? false))))

;; =============================================================================
;; 8. データ型による条件分岐の置き換え
;; =============================================================================

(defprotocol NotificationSender
  "通知送信プロトコル"
  (send-notification [this message] "通知を送信する")
  (get-delivery-time [this] "配信時間を取得する"))

(defrecord EmailNotification [to subject]
  NotificationSender
  (send-notification [this message]
    {:type :email
     :to to
     :subject subject
     :body message
     :status :sent})
  (get-delivery-time [this]
    "1-2分"))

(defrecord SMSNotification [phone-number]
  NotificationSender
  (send-notification [this message]
    {:type :sms
     :to phone-number
     :body (if (> (count message) 160)
             (subs message 0 157)
             message)
     :status :sent})
  (get-delivery-time [this]
    "数秒"))

(defrecord PushNotification [device-token]
  NotificationSender
  (send-notification [this message]
    {:type :push
     :device device-token
     :body message
     :status :sent})
  (get-delivery-time [this]
    "即時"))

;; ファクトリ関数
(defn create-notification
  "通知タイプに応じた通知オブジェクトを作成する"
  [type & {:as opts}]
  (case type
    :email (->EmailNotification (:to opts) (:subject opts "通知"))
    :sms (->SMSNotification (:phone opts))
    :push (->PushNotification (:device opts))
    (throw (ex-info "未知の通知タイプ" {:type type}))))

;; =============================================================================
;; 9. 動的ディスパッチとプロトコルの組み合わせ
;; =============================================================================

(defprotocol Serializable
  "シリアライズ可能なプロトコル"
  (serialize [this format] "指定フォーマットでシリアライズする"))

(defmulti deserialize
  "フォーマットに応じてデシリアライズするマルチメソッド"
  (fn [format data] format))

(defmethod deserialize :json
  [_ data]
  ;; 簡略化：実際にはJSONパーサーを使用
  {:parsed true :format :json :data data})

(defmethod deserialize :edn
  [_ data]
  (read-string data))

(defmethod deserialize :default
  [format data]
  (throw (ex-info "サポートされていないフォーマット" {:format format})))
