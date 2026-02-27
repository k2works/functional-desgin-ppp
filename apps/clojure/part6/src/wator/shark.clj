(ns wator.shark
  "Wa-Tor シミュレーション - サメ

   サメ（捕食者）を表します。
   移動、繁殖、捕食、および体力管理の機能を持ちます。"
  (:require [wator.cell :as cell]
            [wator.animal :as animal]
            [wator.water :as water]
            [wator.fish :as fish]
            [wator.config :as config]))

;; =============================================================================
;; 判定関数
;; =============================================================================

(defn is?
  "サメかどうか判定"
  [cell]
  (= ::shark (::cell/type cell)))

;; =============================================================================
;; コンストラクタ
;; =============================================================================

(defn make
  "サメを作成"
  []
  (merge {::cell/type ::shark
          ::health config/shark-starting-health}
         (animal/make)))

;; =============================================================================
;; 体力管理
;; =============================================================================

(defn health
  "体力を取得"
  [shark]
  (::health shark))

(defn set-health
  "体力を設定"
  [shark new-health]
  (assoc shark ::health new-health))

(defn decrement-health
  "体力を1減少"
  [shark]
  (update shark ::health dec))

(defn feed
  "魚を食べて体力回復"
  [shark]
  (let [new-health (min config/shark-max-health
                        (+ (health shark) config/shark-eating-health))]
    (set-health shark new-health)))

;; =============================================================================
;; 捕食
;; =============================================================================

(defn find-fish-neighbors
  "隣接する魚を検索"
  [world loc]
  (let [neighbors ((:neighbors-fn world) world loc)]
    (filter #(fish/is? ((:get-cell-fn world) world %)) neighbors)))

(defn eat
  "魚を食べる"
  [shark loc world]
  (let [fishy-neighbors (find-fish-neighbors world loc)]
    (if (empty? fishy-neighbors)
      nil
      (let [target (rand-nth fishy-neighbors)]
        [{loc (water/make)}
         {target (feed shark)}]))))

;; =============================================================================
;; マルチメソッド実装
;; =============================================================================

(defmethod animal/make-child ::shark
  [_shark]
  (make))

(defmethod animal/get-reproduction-age ::shark
  [_shark]
  config/shark-reproduction-age)

(defmethod animal/move ::shark
  [shark loc world]
  (animal/do-move shark loc world))

(defmethod animal/reproduce ::shark
  [shark loc world]
  (if (< (health shark) config/shark-reproduction-health)
    nil
    (when-let [reproduction (animal/do-reproduce shark loc world)]
      (let [[from to] reproduction
            from-loc (first (keys from))
            to-loc (first (keys to))
            daughter-health (quot (health shark) 2)
            from-shark (set-health (first (vals from)) daughter-health)
            to-shark (set-health (first (vals to)) daughter-health)]
        [{from-loc from-shark}
         {to-loc to-shark}]))))

(defmethod cell/tick ::shark
  [shark loc world]
  (if (<= (health shark) 1)
    ;; 体力が尽きたら死亡
    [nil {loc (water/make)}]
    (let [aged-shark (-> shark
                         animal/increment-age
                         decrement-health)]
      ;; 優先順位: 繁殖 > 捕食 > 移動
      (or (animal/reproduce aged-shark loc world)
          (eat aged-shark loc world)
          (animal/move aged-shark loc world)))))

(defmethod cell/display ::shark
  [_shark]
  "S")
