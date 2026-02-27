(ns video-rental.movie
  "レンタルビデオシステム - 映画モデル

   映画の基本情報とカテゴリを定義します。")

;; =============================================================================
;; 映画カテゴリ
;; =============================================================================

(def categories
  #{:regular :new-release :childrens})

;; =============================================================================
;; コンストラクタ
;; =============================================================================

(defn make-movie
  "映画を作成"
  [title category]
  {:title title
   :category category})

(defn make-regular
  "通常映画を作成"
  [title]
  (make-movie title :regular))

(defn make-new-release
  "新作映画を作成"
  [title]
  (make-movie title :new-release))

(defn make-childrens
  "子供向け映画を作成"
  [title]
  (make-movie title :childrens))

;; =============================================================================
;; アクセサ
;; =============================================================================

(defn get-title [movie]
  (:title movie))

(defn get-category [movie]
  (:category movie))
