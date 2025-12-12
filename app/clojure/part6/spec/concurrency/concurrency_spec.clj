(ns concurrency.concurrency-spec
  (:require [speclj.core :refer :all]
            [concurrency.state-machine :as sm]
            [concurrency.event-system :as es]))

(describe "並行処理システム"

  (context "状態機械 - 基本"
    (it "ユーザーエージェントを作成できる"
      (let [user (sm/make-user-agent "Alice")]
        (should= "Alice" (sm/get-user-id user))
        (should= :idle (sm/get-state user))))

    (it "状態遷移を実行できる"
      (let [user (sm/make-user-agent "Alice")]
        (sm/send-event user :call {:peer "Bob"})
        (await user)
        (should= :calling (sm/get-state user))))

    (it "無効な遷移は状態を変更しない"
      (let [user (sm/make-user-agent "Alice")]
        ;; idle状態でdialtoneイベントは無効
        (sm/send-event user :dialtone {})
        (await user)
        (should= :idle (sm/get-state user)))))

  (context "状態機械 - 通話フロー"
    (it "発信から通話までの完全なフロー"
      (let [alice (sm/make-user-agent "Alice")
            bob (sm/make-user-agent "Bob")]
        ;; Alice が Bob に電話をかける
        (sm/make-call alice bob)
        (await alice bob)
        (should= :calling (sm/get-state alice))
        (should= :waiting-for-connection (sm/get-state bob))

        ;; Bob が電話に出る
        (sm/answer-call alice bob)
        (await alice bob)
        (should= :talking (sm/get-state alice))
        (should= :talking (sm/get-state bob))))

    (it "電話を切ると idle に戻る"
      (let [alice (sm/make-user-agent "Alice")
            bob (sm/make-user-agent "Bob")]
        ;; 通話状態まで進める
        (sm/make-call alice bob)
        (sm/answer-call alice bob)
        (await alice bob)

        ;; 電話を切る
        (sm/hang-up alice bob)
        (await alice bob)
        (should= :idle (sm/get-state alice))
        (should= :idle (sm/get-state bob)))))

  (context "イベントシステム - 基本"
    (it "イベントバスを作成できる"
      (let [bus (es/make-event-bus)]
        (await bus)
        (should (empty? (es/get-event-log bus)))))

    (it "イベントを購読できる"
      (let [bus (es/make-event-bus)
            received (atom nil)
            handler (fn [event] (reset! received event))]
        (es/subscribe bus :test handler)
        (await bus)
        (should= 1 (count (es/get-subscribers bus :test)))))

    (it "イベントを発行するとハンドラが呼ばれる"
      (let [bus (es/make-event-bus)
            received (atom nil)
            handler (fn [event] (reset! received (:data event)))]
        (es/subscribe bus :test handler)
        (es/publish bus :test {:message "Hello"})
        (await bus)
        (Thread/sleep 50) ; ハンドラ実行を待つ
        (should= {:message "Hello"} @received))))

  (context "イベントシステム - イベントログ"
    (it "発行されたイベントがログに記録される"
      (let [bus (es/make-event-bus)]
        (es/publish bus :event1 {:a 1})
        (es/publish bus :event2 {:b 2})
        (await bus)
        (should= 2 (count (es/get-event-log bus)))
        (should= :event1 (:type (first (es/get-event-log bus))))))

    (it "イベントログをクリアできる"
      (let [bus (es/make-event-bus)]
        (es/publish bus :test {})
        (await bus)
        (es/clear-event-log bus)
        (await bus)
        (should (empty? (es/get-event-log bus))))))

  (context "イベントシステム - 複数購読者"
    (it "同じイベントに複数のハンドラを登録できる"
      (let [bus (es/make-event-bus)
            counter (atom 0)
            handler1 (fn [_] (swap! counter inc))
            handler2 (fn [_] (swap! counter inc))]
        (es/subscribe bus :test handler1)
        (es/subscribe bus :test handler2)
        (es/publish bus :test {})
        (await bus)
        (Thread/sleep 50)
        (should= 2 @counter)))

    (it "購読を解除できる"
      (let [bus (es/make-event-bus)
            counter (atom 0)
            handler (fn [_] (swap! counter inc))]
        (es/subscribe bus :test handler)
        (es/unsubscribe bus :test handler)
        (es/publish bus :test {})
        (await bus)
        (Thread/sleep 50)
        (should= 0 @counter)))))

(run-specs)
