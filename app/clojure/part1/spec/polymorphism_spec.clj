(ns polymorphism-spec
  (:require [speclj.core :refer :all]
            [polymorphism :refer :all])
  (:import [polymorphism EmailNotification SMSNotification PushNotification]))

(describe "多態性とディスパッチ"

  (context "マルチメソッド"
    (it "calculate-area は長方形の面積を計算する"
      (should= 20 (calculate-area {:shape :rectangle :width 4 :height 5})))

    (it "calculate-area は円の面積を計算する"
      (let [area (calculate-area {:shape :circle :radius 3})]
        (should (< (Math/abs (- area (* Math/PI 9))) 0.001))))

    (it "calculate-area は三角形の面積を計算する"
      (should= 15 (calculate-area {:shape :triangle :base 6 :height 5})))

    (it "calculate-area は未知の図形でエラーを投げる"
      (should-throw clojure.lang.ExceptionInfo
                    (calculate-area {:shape :hexagon}))))

  (context "複合ディスパッチ"
    (it "process-payment はクレジットカード円決済を処理する"
      (let [result (process-payment {:method :credit-card :currency :jpy :amount 1000})]
        (should= :processed (:status result))
        (should= 1000 (:amount result))))

    (it "process-payment はクレジットカードドル決済を変換する"
      (let [result (process-payment {:method :credit-card :currency :usd :amount 100})]
        (should= :processed (:status result))
        (should= 15000 (:converted result))))

    (it "process-payment は銀行振込を受け付ける"
      (let [result (process-payment {:method :bank-transfer :currency :jpy :amount 5000})]
        (should= :pending (:status result))))

    (it "process-payment はサポートされていない方法でエラーを返す"
      (let [result (process-payment {:method :bitcoin :currency :btc :amount 1})]
        (should= :error (:status result)))))

  (context "階層的ディスパッチ"
    (it "calculate-interest は普通預金の利息を計算する"
      (should= 200.0 (calculate-interest {:account-type :polymorphism/savings :balance 10000})))

    (it "calculate-interest はプレミアム預金の利息を計算する"
      (should= 500.0 (calculate-interest {:account-type :polymorphism/premium-savings :balance 10000})))

    (it "calculate-interest は当座預金の利息を計算する"
      (should= 10.0 (calculate-interest {:account-type :polymorphism/checking :balance 10000}))))

  (context "プロトコルとレコード"
    (it "Rectangle は Drawable を実装する"
      (let [rect (->Rectangle 10 20 100 50)]
        (should= "Rectangle at (10,20) with size 100x50" (draw rect))
        (should= {:x 10 :y 20 :width 100 :height 50} (bounding-box rect))))

    (it "Circle は Drawable を実装する"
      (let [circle (->Circle 50 50 25)]
        (should= "Circle at (50,50) with radius 25" (draw circle))
        (should= {:x 25 :y 25 :width 50 :height 50} (bounding-box circle))))

    (it "Rectangle は Transformable を実装する"
      (let [rect (->Rectangle 10 20 100 50)
            moved (translate rect 5 10)
            scaled (scale rect 2)]
        (should= 15 (:x moved))
        (should= 30 (:y moved))
        (should= 200 (:width scaled))
        (should= 100 (:height scaled))))

    (it "Circle は Transformable を実装する"
      (let [circle (->Circle 50 50 25)
            moved (translate circle 10 10)
            scaled (scale circle 2)]
        (should= 60 (:x moved))
        (should= 60 (:y moved))
        (should= 50 (:radius scaled)))))

  (context "既存の型にプロトコルを拡張"
    (it "to-string はマップを文字列に変換する"
      (should= "{name: 田中, age: 30}" (to-string {:name "田中" :age 30})))

    (it "to-string はベクターを文字列に変換する"
      (should= "[1, 2, 3]" (to-string [1 2 3])))

    (it "to-string は文字列をそのまま返す"
      (should= "hello" (to-string "hello")))

    (it "to-string は数値を文字列に変換する"
      (should= "42" (to-string 42)))

    (it "to-string は nil を 'nil' に変換する"
      (should= "nil" (to-string nil))))

  (context "コンポーネントパターン"
    (it "DatabaseConnection はライフサイクルを管理する"
      (let [db (->DatabaseConnection "localhost" 5432 false)
            started (start db)
            stopped (stop started)]
        (should (:connected? started))
        (should-not (:connected? stopped))))

    (it "WebServer はデータベースと共にライフサイクルを管理する"
      (let [db (->DatabaseConnection "localhost" 5432 false)
            server (->WebServer 8080 db false)
            started (start server)
            stopped (stop started)]
        (should (:running? started))
        (should (:connected? (:db started)))
        (should-not (:running? stopped))
        (should-not (:connected? (:db stopped))))))

  (context "通知パターン"
    (it "EmailNotification は通知を送信する"
      (let [notification (->EmailNotification "user@example.com" "テスト")
            result (send-notification notification "メッセージ本文")]
        (should= :email (:type result))
        (should= "user@example.com" (:to result))
        (should= :sent (:status result))))

    (it "SMSNotification は長いメッセージを切り詰める"
      (let [notification (->SMSNotification "090-1234-5678")
            long-message (apply str (repeat 200 "あ"))
            result (send-notification notification long-message)]
        (should= :sms (:type result))
        (should= 157 (count (:body result)))))

    (it "create-notification はファクトリとして機能する"
      (let [email (create-notification :email :to "test@example.com")
            sms (create-notification :sms :phone "090-0000-0000")
            push (create-notification :push :device "token123")]
        (should= EmailNotification (type email))
        (should= SMSNotification (type sms))
        (should= PushNotification (type push))))

    (it "create-notification は未知のタイプでエラーを投げる"
      (should-throw clojure.lang.ExceptionInfo
                    (create-notification :unknown))))

  (context "シリアライズとデシリアライズ"
    (it "deserialize は JSON フォーマットを処理する"
      (let [result (deserialize :json "{\"key\": \"value\"}")]
        (should= :json (:format result))
        (should (:parsed result))))

    (it "deserialize は EDN フォーマットを処理する"
      (let [result (deserialize :edn "{:key \"value\"}")]
        (should= "value" (:key result))))

    (it "deserialize はサポートされていないフォーマットでエラーを投げる"
      (should-throw clojure.lang.ExceptionInfo
                    (deserialize :xml "<root/>")))))

(run-specs)
