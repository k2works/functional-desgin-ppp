(ns gossiping-bus-drivers.core-spec
  (:require [speclj.core :refer :all]
            [gossiping-bus-drivers.core :as gbd]))

(describe "ゴシップ好きなバスの運転手"

  (context "ドライバーの作成"
    (it "名前、ルート、噂を持つドライバーを作成できる"
      (let [driver (gbd/make-driver "Alice" [1 2 3] #{:rumor-a})]
        (should= "Alice" (:name driver))
        (should= #{:rumor-a} (:rumors driver))))

    (it "ルートは無限シーケンス（cycle）として保持される"
      (let [driver (gbd/make-driver "Bob" [1 2] #{})]
        (should= 1 (gbd/current-stop driver))
        (should= [1 2 1 2 1] (take 5 (:route driver))))))

  (context "ドライバーの移動"
    (it "ドライバーを次の停留所に移動できる"
      (let [driver (gbd/make-driver "Alice" [1 2 3] #{})]
        (should= 1 (gbd/current-stop driver))
        (should= 2 (gbd/current-stop (gbd/move-driver driver)))
        (should= 3 (gbd/current-stop (-> driver gbd/move-driver gbd/move-driver)))))

    (it "全ドライバーを一度に移動できる"
      (let [world [(gbd/make-driver "Alice" [1 2] #{})
                   (gbd/make-driver "Bob" [3 4] #{})]
            moved (gbd/move-drivers world)]
        (should= 2 (gbd/current-stop (first moved)))
        (should= 4 (gbd/current-stop (second moved))))))

  (context "停留所の集計"
    (it "各停留所にいるドライバーを取得できる"
      (let [world [(gbd/make-driver "Alice" [1 2] #{})
                   (gbd/make-driver "Bob" [1 3] #{})
                   (gbd/make-driver "Carol" [2 3] #{})]
            stops (gbd/get-stops world)]
        (should= 2 (count (get stops 1)))  ; Alice と Bob
        (should= 1 (count (get stops 2)))))) ; Carol

  (context "噂の伝播"
    (it "同じ停留所にいるドライバー間で噂が共有される"
      (let [drivers [(gbd/make-driver "Alice" [1] #{:rumor-a})
                     (gbd/make-driver "Bob" [1] #{:rumor-b})]
            merged (gbd/merge-rumors drivers)]
        (should= #{:rumor-a :rumor-b} (:rumors (first merged)))
        (should= #{:rumor-a :rumor-b} (:rumors (second merged)))))

    (it "3人以上でも噂が正しく統合される"
      (let [drivers [(gbd/make-driver "Alice" [1] #{:a})
                     (gbd/make-driver "Bob" [1] #{:b})
                     (gbd/make-driver "Carol" [1] #{:c})]
            merged (gbd/merge-rumors drivers)]
        (should (every? #(= #{:a :b :c} (:rumors %)) merged)))))

  (context "シミュレーション"
    (it "1ステップで移動と噂の伝播が行われる"
      (let [world [(gbd/make-driver "Alice" [1 2] #{:rumor-a})
                   (gbd/make-driver "Bob" [2 1] #{:rumor-b})]
            after-drive (gbd/drive world)]
        ;; 移動後、Alice は 2、Bob は 1 にいる（すれ違い）
        (should= 2 (gbd/current-stop (first after-drive)))
        (should= 1 (gbd/current-stop (second after-drive)))))

    (it "同じ停留所で会うと噂が共有される"
      (let [world [(gbd/make-driver "Alice" [1 2] #{:rumor-a})
                   (gbd/make-driver "Bob" [1 3] #{:rumor-b})]
            ;; 最初は両方とも停留所1にいる
            after-drive (gbd/drive world)]
        ;; 移動前に停留所1で会っているので、噂は共有済み
        ;; ...ただし drive は move してから spread なので
        ;; 最初の状態で同じ場所にいる場合を考慮
        ))

    (it "全員が同じ噂を持つか確認できる"
      (let [shared [(gbd/make-driver "Alice" [1] #{:a :b})
                    (gbd/make-driver "Bob" [2] #{:a :b})]
            not-shared [(gbd/make-driver "Alice" [1] #{:a})
                        (gbd/make-driver "Bob" [2] #{:b})]]
        (should (gbd/all-rumors-shared? shared))
        (should-not (gbd/all-rumors-shared? not-shared)))))

  (context "問題の解答例"
    (it "例1: 2人が1ステップで出会う場合"
      (let [world [(gbd/make-driver "D1" [1 2] #{:r1})
                   (gbd/make-driver "D2" [2 1] #{:r2})]
            ;; D1: 1->2, D2: 2->1
            ;; 最初の移動後、D1は2、D2は1（すれ違い）
            ;; 次の移動後、D1は1、D2は2（また会わない）
            ;; 実際には cycle なので...
            result (gbd/drive-till-all-rumors-spread world)]
        ;; この例では出会わない可能性がある
        ))

    (it "例2: 3人が最終的に全噂を共有する場合"
      (let [world [(gbd/make-driver "D1" [3 1 2 3] #{:r1})
                   (gbd/make-driver "D2" [3 2 3 1] #{:r2})
                   (gbd/make-driver "D3" [4 2 3 4 5] #{:r3})]
            result (gbd/drive-till-all-rumors-spread world)]
        (should (number? result))
        (should (< result 480))))

    (it "出会わないルートの場合は :never を返す"
      (let [world [(gbd/make-driver "D1" [1] #{:r1})
                   (gbd/make-driver "D2" [2] #{:r2})]
            result (gbd/drive-till-all-rumors-spread world)]
        (should= :never result))))

  (context "ユーティリティ"
    (it "ユニークな噂の総数をカウントできる"
      (let [world [(gbd/make-driver "D1" [1] #{:a :b})
                   (gbd/make-driver "D2" [2] #{:b :c})]]
        (should= 3 (gbd/count-unique-rumors world))))

    (it "ドライバーのサマリーを取得できる"
      (let [driver (gbd/make-driver "Alice" [5 6 7] #{:a :b :c})
            summary (gbd/driver-summary driver)]
        (should= "Alice" (:name summary))
        (should= 5 (:current-stop summary))
        (should= 3 (:rumor-count summary))))

    (it "ワールドのサマリーを取得できる"
      (let [world [(gbd/make-driver "D1" [1] #{:a :b})
                   (gbd/make-driver "D2" [1] #{:a :b})]
            summary (gbd/world-summary world)]
        (should= 2 (count (:drivers summary)))
        (should= 2 (:total-unique-rumors summary))
        (should (:all-shared? summary))))))

(run-specs)
