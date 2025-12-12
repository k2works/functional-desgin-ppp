(ns wator.wator-spec
  (:require [speclj.core :refer :all]
            [wator.config :as config]
            [wator.cell :as cell]
            [wator.water :as water]
            [wator.fish :as fish]
            [wator.shark :as shark]
            [wator.animal :as animal]
            [wator.world :as world]))

(describe "Wa-Tor シミュレーション"

  (context "水セル"
    (it "水セルを作成できる"
      (let [w (water/make)]
        (should (water/is? w))
        (should= "." (cell/display w)))))

  (context "魚"
    (it "魚を作成できる"
      (let [f (fish/make)]
        (should (fish/is? f))
        (should= 0 (animal/age f))
        (should= "f" (cell/display f))))

    (it "魚の年齢を増やせる"
      (let [f (fish/make)
            aged (animal/increment-age f)]
        (should= 1 (animal/age aged))))

    (it "魚の繁殖可能年齢を取得できる"
      (let [f (fish/make)]
        (should= config/fish-reproduction-age
                 (animal/get-reproduction-age f)))))

  (context "サメ"
    (it "サメを作成できる"
      (let [s (shark/make)]
        (should (shark/is? s))
        (should= config/shark-starting-health (shark/health s))
        (should= "S" (cell/display s))))

    (it "サメの体力を減らせる"
      (let [s (shark/make)
            hungry (shark/decrement-health s)]
        (should= (dec config/shark-starting-health) (shark/health hungry))))

    (it "サメが魚を食べると体力が回復する"
      (let [s (-> (shark/make)
                  shark/decrement-health
                  shark/decrement-health
                  shark/feed)]
        (should= (min config/shark-max-health
                      (+ (- config/shark-starting-health 2)
                         config/shark-eating-health))
                 (shark/health s))))

    (it "サメの繁殖可能年齢を取得できる"
      (let [s (shark/make)]
        (should= config/shark-reproduction-age
                 (animal/get-reproduction-age s)))))

  (context "ワールド"
    (it "ワールドを作成できる"
      (let [w (world/make 5 5)]
        (should= 5 (:width w))
        (should= 5 (:height w))
        (should= 25 (count (:cells w)))))

    (it "全てのセルが初期状態で水"
      (let [w (world/make 3 3)]
        (should= 9 (world/count-water w))
        (should= 0 (world/count-fish w))
        (should= 0 (world/count-sharks w))))

    (it "セルを取得・設定できる"
      (let [w (world/make 3 3)
            w' (world/set-cell w [1 1] (fish/make))]
        (should (water/is? (world/get-cell w [1 1])))
        (should (fish/is? (world/get-cell w' [1 1])))))

    (it "トーラス上で座標がラップされる"
      (let [w (world/make 5 5)]
        (should= [0 0] (world/wrap w [5 5]))
        (should= [4 4] (world/wrap w [-1 -1]))
        (should= [2 3] (world/wrap w [7 8])))))

  (context "隣接セル"
    (it "8つの隣接セルを取得できる"
      (let [w (world/make 5 5)
            neighbors (world/neighbors w [2 2])]
        (should= 8 (count neighbors))
        (should-contain [1 1] neighbors)
        (should-contain [3 3] neighbors)))

    (it "端のセルも正しくラップされる"
      (let [w (world/make 5 5)
            neighbors (world/neighbors w [0 0])]
        (should= 8 (count neighbors))
        (should-contain [4 4] neighbors)
        (should-contain [4 0] neighbors)
        (should-contain [0 4] neighbors))))

  (context "ランダム配置"
    (it "魚とサメをランダムに配置できる"
      (let [w (-> (world/make 10 10)
                  (world/populate-random 20 5))]
        (should= 20 (world/count-fish w))
        (should= 5 (world/count-sharks w))
        (should= 75 (world/count-water w)))))

  (context "統計"
    (it "統計情報を取得できる"
      (let [w (-> (world/make 10 10)
                  (world/populate-random 20 5))
            stats (world/statistics w)]
        (should= 20 (:fish stats))
        (should= 5 (:sharks stats))
        (should= 75 (:water stats))
        (should= 100 (:total stats)))))

  (context "表示"
    (it "ワールドを文字列で表示できる"
      (let [w (-> (world/make 3 3)
                  (world/set-fish [0 0])
                  (world/set-shark [2 2]))
            display (world/display w)]
        (should-contain "f" display)
        (should-contain "S" display)
        (should-contain "." display))))

  (context "シミュレーション"
    (it "tickでワールドが更新される"
      (let [w (-> (world/make 5 5)
                  (world/set-fish [2 2]))
            w' (world/tick w)]
        ;; 魚は移動するか、その場にとどまる
        (should= 1 (world/count-fish w'))))))

(run-specs)
