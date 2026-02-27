(ns clojure-spec
  "第4章: Clojure Spec による仕様定義

   データ構造の仕様定義、関数仕様の定義（fdef）、
   実行時検証と自動テスト生成について学びます。"
  (:require [clojure.spec.alpha :as s]
            [clojure.spec.gen.alpha :as gen]
            [clojure.spec.test.alpha :as stest]))

;; =============================================================================
;; 1. 基本的なスペック定義
;; =============================================================================

;; シンプルなスペック
(s/def ::name (s/and string? #(< 0 (count %) 100)))
(s/def ::age (s/and int? #(<= 0 % 150)))
(s/def ::email (s/and string? #(re-matches #".+@.+\..+" %)))

;; 列挙型のスペック
(s/def ::membership #{:bronze :silver :gold :platinum})
(s/def ::status #{:active :inactive :suspended})

;; =============================================================================
;; 2. コレクションのスペック
;; =============================================================================

;; ベクターのスペック
(s/def ::tags (s/coll-of string? :kind vector? :min-count 0 :max-count 10))

;; マップのスペック（必須キーとオプションキー）
(s/def ::person
  (s/keys :req-un [::name ::age]
          :opt-un [::email ::membership]))

;; 入れ子のマップ
(s/def ::address
  (s/keys :req-un [::street ::city ::postal-code]))

(s/def ::street string?)
(s/def ::city string?)
(s/def ::postal-code (s/and string? #(re-matches #"\d{3}-\d{4}" %)))

(s/def ::person-with-address
  (s/keys :req-un [::name ::age ::address]))

;; =============================================================================
;; 3. 商品と注文のドメインモデル
;; =============================================================================

(s/def ::product-id (s/and string? #(re-matches #"PROD-\d{5}" %)))
(s/def ::product-name (s/and string? #(< 0 (count %) 200)))
(s/def ::price (s/and number? pos?))
(s/def ::quantity (s/and int? pos?))

(s/def ::product
  (s/keys :req-un [::product-id ::product-name ::price]
          :opt-un [::description ::category]))

(s/def ::description string?)
(s/def ::category #{:electronics :clothing :food :books :other})

(s/def ::order-item
  (s/keys :req-un [::product-id ::quantity ::price]))

(s/def ::items (s/coll-of ::order-item :min-count 1))

(s/def ::order-id (s/and string? #(re-matches #"ORD-\d{8}" %)))
(s/def ::customer-id (s/and string? #(re-matches #"CUST-\d{6}" %)))
(s/def ::order-date inst?)
(s/def ::total (s/and number? #(>= % 0)))

(s/def ::order
  (s/keys :req-un [::order-id ::customer-id ::items ::order-date]
          :opt-un [::total ::status]))

;; =============================================================================
;; 4. 関数仕様の定義（fdef）
;; =============================================================================

(defn calculate-item-total
  "注文アイテムの合計を計算する"
  [{:keys [price quantity]}]
  (* price quantity))

(s/fdef calculate-item-total
  :args (s/cat :item ::order-item)
  :ret number?
  :fn (s/and #(pos? (:ret %))
             #(= (:ret %)
                 (* (get-in % [:args :item :price])
                    (get-in % [:args :item :quantity])))))

(defn calculate-order-total
  "注文全体の合計を計算する"
  [order]
  (->> (:items order)
       (map calculate-item-total)
       (reduce +)))

(s/fdef calculate-order-total
  :args (s/cat :order ::order)
  :ret number?
  :fn #(>= (:ret %) 0))

(defn apply-discount
  "割引を適用する"
  [total discount-rate]
  {:pre [(s/valid? ::total total)
         (s/valid? (s/and number? #(<= 0 % 1)) discount-rate)]}
  (* total (- 1 discount-rate)))

(s/fdef apply-discount
  :args (s/cat :total ::total :discount-rate (s/and number? #(<= 0 % 1)))
  :ret number?
  :fn #(<= (:ret %) (get-in % [:args :total])))

;; =============================================================================
;; 5. 多引数と可変長引数のスペック
;; =============================================================================

(defn create-person
  "人物を作成する"
  ([name age]
   {:name name :age age})
  ([name age email]
   {:name name :age age :email email}))

(s/fdef create-person
  :args (s/alt :two-args (s/cat :name ::name :age ::age)
               :three-args (s/cat :name ::name :age ::age :email ::email))
  :ret ::person)

(defn sum-prices
  "複数の価格を合計する"
  [& prices]
  (reduce + 0 prices))

(s/fdef sum-prices
  :args (s/* ::price)
  :ret number?)

;; =============================================================================
;; 6. 条件付きスペック（マルチスペック）
;; =============================================================================

(s/def ::notification-type #{:email :sms :push})

(defmulti notification-spec :type)

(defmethod notification-spec :email [_]
  (s/keys :req-un [::type ::to ::subject ::body]))

(defmethod notification-spec :sms [_]
  (s/keys :req-un [::type ::phone-number ::body]))

(defmethod notification-spec :push [_]
  (s/keys :req-un [::type ::device-token ::body]))

(s/def ::type ::notification-type)
(s/def ::to ::email)
(s/def ::subject string?)
(s/def ::body string?)
(s/def ::phone-number (s/and string? #(re-matches #"\d{2,4}-\d{2,4}-\d{4}" %)))
(s/def ::device-token string?)

(s/def ::notification (s/multi-spec notification-spec :type))

;; =============================================================================
;; 7. カスタムジェネレータ
;; =============================================================================

(defn product-id-gen
  "商品IDのジェネレータ"
  []
  (gen/fmap #(str "PROD-" (format "%05d" %))
            (gen/choose 0 99999)))

(s/def ::product-id-with-gen
  (s/with-gen
    (s/and string? #(re-matches #"PROD-\d{5}" %))
    product-id-gen))

(defn order-id-gen
  "注文IDのジェネレータ"
  []
  (gen/fmap #(str "ORD-" (format "%08d" %))
            (gen/choose 0 99999999)))

(defn email-gen
  "メールアドレスのジェネレータ"
  []
  (gen/fmap (fn [[user domain]]
              (str user "@" domain ".com"))
            (gen/tuple (gen/such-that #(not (empty? %))
                                       (gen/string-alphanumeric))
                       (gen/such-that #(not (empty? %))
                                       (gen/string-alphanumeric)))))

;; =============================================================================
;; 8. バリデーションとエラーハンドリング
;; =============================================================================

(defn validate-person
  "人物データを検証し、結果を返す"
  [person]
  (if (s/valid? ::person person)
    {:valid true :data person}
    {:valid false
     :errors (s/explain-data ::person person)}))

(defn validate-order
  "注文データを検証し、結果を返す"
  [order]
  (if (s/valid? ::order order)
    {:valid true :data order}
    {:valid false
     :errors (s/explain-data ::order order)}))

(defn conform-or-throw
  "スペックに適合しない場合は例外をスロー"
  [spec data]
  (let [conformed (s/conform spec data)]
    (if (= conformed ::s/invalid)
      (throw (ex-info "Validation failed"
                      {:spec spec
                       :data data
                       :problems (s/explain-data spec data)}))
      conformed)))

;; =============================================================================
;; 9. 実行時検証の有効化
;; =============================================================================

(defn enable-instrumentation!
  "関数のインストルメンテーションを有効化"
  []
  (stest/instrument))

(defn disable-instrumentation!
  "関数のインストルメンテーションを無効化"
  []
  (stest/unstrument))

;; =============================================================================
;; 10. データ生成ユーティリティ
;; =============================================================================

(defn generate-sample
  "スペックに基づいてサンプルデータを生成"
  ([spec]
   (gen/generate (s/gen spec)))
  ([spec n]
   (gen/sample (s/gen spec) n)))

(defn generate-person
  "人物データのサンプルを生成"
  []
  (generate-sample ::person))

(defn generate-order
  "注文データのサンプルを生成"
  []
  (generate-sample ::order))
