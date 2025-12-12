(ns wator.animal
  "Wa-Tor シミュレーション - 動物

   魚とサメに共通する動物の基本機能を定義します。"
  (:require [wator.cell :as cell]
            [wator.water :as water]))

;; =============================================================================
;; マルチメソッド宣言
;; =============================================================================

(defmulti move
  "動物を移動"
  (fn [animal & _args] (::cell/type animal)))

(defmulti reproduce
  "動物を繁殖"
  (fn [animal & _args] (::cell/type animal)))

(defmulti make-child
  "子を作成"
  ::cell/type)

(defmulti get-reproduction-age
  "繁殖可能年齢を取得"
  ::cell/type)

;; =============================================================================
;; コンストラクタ
;; =============================================================================

(defn make
  "動物の基本属性を作成"
  []
  {::age 0})

;; =============================================================================
;; アクセサ
;; =============================================================================

(defn age
  "年齢を取得"
  [animal]
  (::age animal))

(defn set-age
  "年齢を設定"
  [animal new-age]
  (assoc animal ::age new-age))

(defn increment-age
  "年齢を1増加"
  [animal]
  (update animal ::age inc))

;; =============================================================================
;; 移動ロジック
;; =============================================================================

(defn find-empty-neighbors
  "隣接する空のセルを検索"
  [world loc]
  (let [neighbors ((:neighbors-fn world) world loc)]
    (filter #(water/is? ((:get-cell-fn world) world %)) neighbors)))

(defn do-move
  "動物を空のセルに移動"
  [animal loc world]
  (let [destinations (find-empty-neighbors world loc)]
    (if (empty? destinations)
      [nil {loc animal}]
      (let [new-loc (rand-nth destinations)]
        [{loc (water/make)} {new-loc animal}]))))

;; =============================================================================
;; 繁殖ロジック
;; =============================================================================

(defn do-reproduce
  "動物が繁殖を試みる"
  [animal loc world]
  (if (>= (age animal) (get-reproduction-age animal))
    (let [birth-places (find-empty-neighbors world loc)]
      (if (empty? birth-places)
        nil
        (let [new-loc (rand-nth birth-places)]
          [{loc (set-age animal 0)}
           {new-loc (make-child animal)}])))
    nil))

;; =============================================================================
;; ティック処理
;; =============================================================================

(defn tick
  "動物の1ステップを実行"
  [animal loc world]
  (let [aged-animal (increment-age animal)
        reproduction (reproduce aged-animal loc world)]
    (if reproduction
      reproduction
      (move aged-animal loc world))))
