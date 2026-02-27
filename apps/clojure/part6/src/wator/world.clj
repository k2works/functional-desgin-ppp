(ns wator.world
  "Wa-Tor シミュレーション - ワールド

   トーラス（ドーナツ型）のワールドを管理します。
   端は反対側につながっています。"
  (:require [wator.cell :as cell]
            [wator.water :as water]
            [wator.fish :as fish]
            [wator.shark :as shark]))

;; =============================================================================
;; 前方宣言
;; =============================================================================

(declare neighbors get-cell)

;; =============================================================================
;; ワールド構造
;; =============================================================================

(defn make
  "ワールドを作成"
  [width height]
  (let [locs (for [x (range width) y (range height)] [x y])
        cells (into {} (map (fn [loc] [loc (water/make)]) locs))]
    {:type ::world
     :width width
     :height height
     :cells cells
     :neighbors-fn neighbors
     :get-cell-fn get-cell}))

;; =============================================================================
;; セル操作
;; =============================================================================

(defn get-cell
  "指定位置のセルを取得"
  [world [x y]]
  (get-in world [:cells [x y]]))

(defn set-cell
  "指定位置にセルを設定"
  [world [x y] cell]
  (assoc-in world [:cells [x y]] cell))

;; =============================================================================
;; 座標計算（トーラス）
;; =============================================================================

(defn wrap
  "座標をトーラス上でラップ"
  [world [x y]]
  (let [{:keys [width height]} world]
    [(mod x width) (mod y height)]))

(defn neighbors
  "隣接セルの座標を取得（8方向）"
  [world [x y]]
  (let [deltas (for [dx [-1 0 1] dy [-1 0 1]
                     :when (not (and (= dx 0) (= dy 0)))]
                 [dx dy])]
    (map (fn [[dx dy]]
           (wrap world [(+ x dx) (+ y dy)]))
         deltas)))

;; =============================================================================
;; ワールド生成
;; =============================================================================

(defn populate-random
  "ランダムに魚とサメを配置"
  [world fish-count shark-count]
  (let [all-locs (keys (:cells world))
        shuffled (shuffle all-locs)
        fish-locs (take fish-count shuffled)
        shark-locs (take shark-count (drop fish-count shuffled))]
    (as-> world w
      (reduce (fn [w loc] (set-cell w loc (fish/make))) w fish-locs)
      (reduce (fn [w loc] (set-cell w loc (shark/make))) w shark-locs))))

(defn set-fish
  "指定位置に魚を配置"
  [world loc]
  (set-cell world loc (fish/make)))

(defn set-shark
  "指定位置にサメを配置"
  [world loc]
  (set-cell world loc (shark/make)))

;; =============================================================================
;; シミュレーション
;; =============================================================================

(defn tick-cell
  "1つのセルを更新"
  [world loc]
  (let [cell (get-cell world loc)]
    (cell/tick cell loc world)))

(defn apply-changes
  "変更をワールドに適用"
  [world changes]
  (reduce (fn [w change]
            (if change
              (reduce (fn [w' [loc cell]]
                        (set-cell w' loc cell))
                      w change)
              w))
          world changes))

(defn tick
  "ワールドの1ステップを実行"
  [world]
  (let [locs (shuffle (keys (:cells world)))
        changes (map #(tick-cell world %) locs)]
    (apply-changes world (flatten (remove nil? changes)))))

;; =============================================================================
;; 統計
;; =============================================================================

(defn count-fish
  "魚の数をカウント"
  [world]
  (count (filter fish/is? (vals (:cells world)))))

(defn count-sharks
  "サメの数をカウント"
  [world]
  (count (filter shark/is? (vals (:cells world)))))

(defn count-water
  "水の数をカウント"
  [world]
  (count (filter water/is? (vals (:cells world)))))

(defn statistics
  "統計情報を取得"
  [world]
  {:fish (count-fish world)
   :sharks (count-sharks world)
   :water (count-water world)
   :total (count (:cells world))})

;; =============================================================================
;; 表示
;; =============================================================================

(defn display-row
  "1行を表示文字列として取得"
  [world y]
  (let [{:keys [width]} world]
    (apply str (map (fn [x]
                      (cell/display (get-cell world [x y])))
                    (range width)))))

(defn display
  "ワールド全体を表示文字列として取得"
  [world]
  (let [{:keys [height]} world]
    (clojure.string/join "\n"
                         (map #(display-row world %) (range height)))))
