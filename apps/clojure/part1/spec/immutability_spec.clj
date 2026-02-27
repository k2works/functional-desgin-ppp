(ns immutability-spec
  (:require [speclj.core :refer :all]
            [immutability :refer :all]))

(describe "不変性とデータ変換"

  (context "不変データ構造の基本"
    (it "update-age は元のデータを変更しない"
      (let [original {:name "田中" :age 30}
            updated (update-age original 31)]
        (should= 30 (:age original))
        (should= 31 (:age updated))
        (should= "田中" (:name updated)))))

  (context "構造共有"
    (it "add-member は新しいメンバーを追加した新しいチームを返す"
      (let [team {:name "開発チーム"
                  :members [{:name "田中" :role :developer}]}
            new-team (add-member team {:name "鈴木" :role :designer})]
        (should= 1 (count (:members team)))
        (should= 2 (count (:members new-team)))
        (should= "開発チーム" (:name new-team)))))

  (context "データ変換パイプライン"
    (it "calculate-subtotal は単価×数量を計算する"
      (should= 2000 (calculate-subtotal {:price 1000 :quantity 2}))
      (should= 1500 (calculate-subtotal {:price 500 :quantity 3})))

    (it "membership-discount は会員種別に応じた割引率を返す"
      (should= 0.1 (membership-discount :gold))
      (should= 0.05 (membership-discount :silver))
      (should= 0.02 (membership-discount :bronze))
      (should= 0 (membership-discount :regular)))

    (it "calculate-total は注文の合計金額を計算する"
      (let [order {:items [{:price 1000 :quantity 2}
                           {:price 500 :quantity 3}]}]
        (should= 3500 (calculate-total order))))

    (it "apply-discount は割引後の金額を計算する"
      (let [order {:customer {:membership :gold}}]
        (should= 900.0 (apply-discount order 1000))))

    (it "process-order は注文処理全体を行う"
      (let [order {:items [{:price 1000 :quantity 2}
                           {:price 500 :quantity 3}]
                   :customer {:membership :gold}}]
        (should= 3150.0 (process-order order)))))

  (context "副作用の分離"
    (it "pure-calculate-tax は税額を計算する"
      (should= 100.0 (pure-calculate-tax 1000 0.1))
      (should= 80.0 (pure-calculate-tax 1000 0.08)))

    (it "calculate-invoice は請求書を計算する"
      (let [items [{:price 1000 :quantity 2}
                   {:price 500 :quantity 1}]
            invoice (calculate-invoice items 0.1)]
        (should= 2500 (:subtotal invoice))
        (should= 250.0 (:tax invoice))
        (should= 2750.0 (:total invoice)))))

  (context "Undo/Redo の実装"
    (it "create-history は空の履歴を作成する"
      (let [history (create-history)]
        (should= nil (:current history))
        (should= [] (:past history))
        (should= [] (:future history))))

    (it "push-state は新しい状態を追加する"
      (let [history (-> (create-history)
                        (push-state {:text "Hello"}))]
        (should= {:text "Hello"} (:current history))
        (should= [nil] (:past history))))

    (it "undo は直前の状態に戻す"
      (let [history (-> (create-history)
                        (push-state {:text "Hello"})
                        (push-state {:text "Hello World"})
                        undo)]
        (should= {:text "Hello"} (:current history))
        (should= [{:text "Hello World"}] (:future history))))

    (it "redo はやり直しを行う"
      (let [history (-> (create-history)
                        (push-state {:text "Hello"})
                        (push-state {:text "Hello World"})
                        undo
                        redo)]
        (should= {:text "Hello World"} (:current history))
        (should= [] (:future history))))

    (it "空の履歴で undo しても安全"
      (let [history (create-history)
            after-undo (undo history)]
        (should= nil (:current after-undo))))

    (it "future が空で redo しても安全"
      (let [history (-> (create-history)
                        (push-state {:text "Hello"}))
            after-redo (redo history)]
        (should= {:text "Hello"} (:current after-redo)))))

  (context "トランスデューサー"
    (it "process-items-efficiently は効率的にアイテムを処理する"
      (let [items [{:price 100 :quantity 2}   ; subtotal 200 > 100 ✓
                   {:price 50 :quantity 1}    ; subtotal 50 <= 100 ✗
                   {:price 200 :quantity 0}   ; quantity 0 ✗
                   {:price 300 :quantity 1}]] ; subtotal 300 > 100 ✓
        (should= 2 (count (process-items-efficiently items)))))))

(run-specs)
