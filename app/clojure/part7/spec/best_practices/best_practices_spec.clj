(ns best-practices.best-practices-spec
  (:require [speclj.core :refer :all]
            [best-practices.data-centric :as dc]
            [best-practices.pure-functions :as pf]
            [best-practices.testable-design :as td]))

(describe "データ中心設計"

  (describe "データ構造の作成"
    (it "ユーザーデータを作成できる"
      (let [user (dc/make-user "u1" "John" "john@example.com")]
        (should= "u1" (:id user))
        (should= "John" (:name user))
        (should= "john@example.com" (:email user))))

    (it "注文データを作成できる"
      (let [items [(dc/make-order-item "p1" 2 100)
                   (dc/make-order-item "p2" 1 200)]
            order (dc/make-order "o1" "u1" items)]
        (should= "o1" (:id order))
        (should= "u1" (:user-id order))
        (should= 2 (count (:items order))))))

  (describe "純粋な計算関数"
    (it "アイテムの合計を計算できる"
      (let [item (dc/make-order-item "p1" 3 100)]
        (should= 300 (dc/calculate-item-total item))))

    (it "注文の合計を計算できる"
      (let [items [(dc/make-order-item "p1" 2 100)
                   (dc/make-order-item "p2" 1 200)]
            order (dc/make-order "o1" "u1" items)]
        (should= 400 (dc/calculate-order-total order))))

    (it "割引を適用できる"
      (should= 90.0 (dc/apply-discount 100 0.1))))

  (describe "データ変換パイプライン"
    (it "注文を処理できる"
      (let [items [(dc/make-order-item "p1" 2 100)]
            order (dc/make-order "o1" "u1" items)
            processed (dc/process-order order 0.1 0.08)]
        (should= :processed (:status processed))
        (should-contain :total processed)
        (should-contain :tax processed)
        (should-contain :grand-total processed))))

  (describe "データ検証"
    (it "有効なメールアドレスを検証できる"
      (should (dc/valid-email? "test@example.com"))
      (should-not (dc/valid-email? "invalid"))
      (should-not (dc/valid-email? nil)))

    (it "有効なユーザーを検証できる"
      (let [valid-user (dc/make-user "u1" "John" "john@example.com")
            invalid-user {:name "" :email "invalid"}]
        (should (dc/valid-user? valid-user))
        (should-not (dc/valid-user? invalid-user))))

    (it "有効な注文を検証できる"
      (let [valid-order (dc/make-order "o1" "u1"
                                       [(dc/make-order-item "p1" 1 100)])
            invalid-order {:items []}]
        (should (dc/valid-order? valid-order))
        (should-not (dc/valid-order? invalid-order)))))

  (describe "イミュータブルな更新"
    (it "メールアドレスを更新できる"
      (let [user (dc/make-user "u1" "John" "john@example.com")
            updated (dc/update-user-email user "new@example.com")]
        (should= "new@example.com" (:email updated))
        (should= "john@example.com" (:email user))))

    (it "無効なメールは更新されない"
      (let [user (dc/make-user "u1" "John" "john@example.com")
            updated (dc/update-user-email user "invalid")]
        (should= "john@example.com" (:email updated))))

    (it "注文にアイテムを追加できる"
      (let [order (dc/make-order "o1" "u1" [])
            item (dc/make-order-item "p1" 1 100)
            updated (dc/add-order-item order item)]
        (should= 1 (count (:items updated)))
        (should= 0 (count (:items order)))))

    (it "注文をキャンセルできる"
      (let [order (dc/make-order "o1" "u1" [(dc/make-order-item "p1" 1 100)])
            cancelled (dc/cancel-order order)]
        (should= :cancelled (:status cancelled))
        (should= :pending (:status order))))))

(describe "純粋関数と副作用の分離"

  (describe "純粋関数"
    (it "同じ入力に対して同じ出力を返す"
      (should= 5 (pf/add 2 3))
      (should= 5 (pf/add 2 3)))

    (it "副作用なしで計算できる"
      (should= 6 (pf/multiply 2 3))
      (should= 4 (pf/square 2))))

  (describe "高階関数によるロギング"
    (it "ロギング付き関数を作成できる"
      (let [logs (atom [])
            logger (fn [msg] (swap! logs conj msg))
            logged-add (pf/with-logging pf/add logger)]
        (should= 5 (logged-add 2 3))
        (should= 2 (count @logs)))))

  (describe "副作用を端に押し出す"
    (it "金額を検証できる"
      (should (:valid (pf/validate-amount 100)))
      (should-not (:valid (pf/validate-amount 0)))
      (should-not (:valid (pf/validate-amount nil))))

    (it "手数料を計算できる"
      (should= 10.0 (pf/calculate-fee 100 0.1)))

    (it "支払い処理で副作用関数を呼び出せる"
      (let [side-effects (atom [])
            side-effect-fn (fn [result] (swap! side-effects conj result))
            result (pf/process-payment! 100 0.1 side-effect-fn)]
        (should= :success (:status result))
        (should= 100 (:amount result))
        (should= 10.0 (:fee result))
        (should= 1 (count @side-effects)))))

  (describe "関数合成"
    (it "パイプラインで関数を合成できる"
      ;; (1 + 1) * 2 - 3 = 1
      (should= 1 (pf/process-number 1))
      ;; (5 + 1) * 2 - 3 = 9
      (should= 9 (pf/process-number 5))))

  (describe "メモ化"
    (it "メモ化された関数は結果をキャッシュする"
      (let [call-count (atom 0)
            expensive-fn (fn [x]
                           (swap! call-count inc)
                           (* x x))
            memoized (pf/memoize-fn expensive-fn)]
        (should= 4 (memoized 2))
        (should= 4 (memoized 2))
        (should= 1 @call-count)))))

(describe "テスト可能な設計"

  (describe "依存性注入"
    (it "モックリポジトリでユーザーを取得できる"
      (let [repo (td/make-mock-repository [{:id "u1" :name "John"}])
            user (td/get-user repo "u1")]
        (should= "John" (:name user))))

    (it "モックリポジトリでユーザーを保存できる"
      (let [repo (td/make-mock-repository [])
            saved (td/save-user repo {:id "u2" :name "Jane"})]
        (should= "u2" (:id saved)))))

  (describe "時間の抽象化"
    (it "固定時刻で注文を作成できる"
      (let [fixed-clock (td/make-fixed-clock 1000)
            order (td/create-order [{:item "A"}] fixed-clock)]
        (should= 1000 (:created-at order))))

    (it "期限切れを判定できる"
      (let [fixed-clock (td/make-fixed-clock 1000)
            order (td/create-order [{:item "A"}] fixed-clock)
            later-clock (td/make-fixed-clock 2000)]
        (should-not (td/is-expired? order later-clock 1500))
        (should (td/is-expired? order later-clock 500)))))

  (describe "ランダム性の抽象化"
    (it "シーケンシャルIDを生成できる"
      (let [id-gen (td/make-sequential-id-gen)]
        (should= "id-1" (td/generate-id id-gen))
        (should= "id-2" (td/generate-id id-gen))))

    (it "依存性注入でエンティティを作成できる"
      (let [id-gen (td/make-sequential-id-gen)
            clock (td/make-fixed-clock 1000)
            entity (td/create-entity {:name "Test"} id-gen clock)]
        (should= "id-1" (:id entity))
        (should= 1000 (:created-at entity))
        (should= "Test" (:name entity)))))

  (describe "設定の分離"
    (it "デフォルト設定で価格を計算できる"
      (let [config (td/make-config)
            result (td/calculate-price config 1000)]
        (should= 1000 (:base-price result))
        (should= 1100.0 (:total result))))

    (it "カスタム設定で価格を計算できる"
      (let [config (td/make-config :tax-rate 0.08 :discount-rate 0.1)
            result (td/calculate-price config 1000)]
        (should= 1000 (:base-price result))
        (should= 900.0 (:discounted result))
        (should (< (Math/abs (- 972.0 (:total result))) 0.001)))))

  (describe "エラーハンドリング"
    (it "有効な入力を検証できる"
      (let [input {:name "John" :email "john@example.com" :age 30}
            result (td/validate-input input td/user-validations)]
        (should (:valid result))))

    (it "無効な入力を検証できる"
      (let [input {:name "" :email "invalid" :age -1}
            result (td/validate-input input td/user-validations)]
        (should-not (:valid result))
        (should= 3 (count (:errors result))))))

  (describe "モック通知サービス"
    (it "モック通知サービスでメッセージを送信できる"
      (let [notifier (td/make-mock-notifier)]
        (td/send-notification notifier "user@example.com" "Hello")
        (should= 1 (count (td/get-sent-messages notifier)))
        (should= "user@example.com" (:recipient (first (td/get-sent-messages notifier))))))))

(run-specs)
