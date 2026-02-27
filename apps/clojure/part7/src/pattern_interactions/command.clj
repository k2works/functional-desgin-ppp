(ns pattern-interactions.command
  "Command パターン - 操作のカプセル化")

;; コマンドのマルチメソッド
(defmulti execute
  "コマンドを実行"
  :command-type)

(defmulti undo
  "コマンドを取り消し"
  :command-type)

(defmulti describe
  "コマンドの説明を取得"
  :command-type)

;; 図形追加コマンド
(defn make-add-shape-command
  "図形追加コマンドを作成"
  [shape]
  {:command-type :add-shape
   :shape shape})

(defmethod execute :add-shape
  [cmd]
  (fn [canvas]
    (update canvas :shapes conj (:shape cmd))))

(defmethod undo :add-shape
  [cmd]
  (fn [canvas]
    (update canvas :shapes
            (fn [shapes]
              (vec (butlast shapes))))))

(defmethod describe :add-shape
  [cmd]
  (str "Add shape: " (:type (:shape cmd))))

;; 図形移動コマンド
(defn make-move-shape-command
  "図形移動コマンドを作成"
  [index dx dy]
  {:command-type :move-shape
   :index index
   :dx dx
   :dy dy})

(defmethod execute :move-shape
  [cmd]
  (fn [canvas]
    (let [{:keys [index dx dy]} cmd]
      (update-in canvas [:shapes index]
                 (fn [shape]
                   (-> shape
                       (update :x + dx)
                       (update :y + dy)))))))

(defmethod undo :move-shape
  [cmd]
  (fn [canvas]
    (let [{:keys [index dx dy]} cmd]
      (update-in canvas [:shapes index]
                 (fn [shape]
                   (-> shape
                       (update :x - dx)
                       (update :y - dy)))))))

(defmethod describe :move-shape
  [cmd]
  (str "Move shape[" (:index cmd) "] by (" (:dx cmd) ", " (:dy cmd) ")"))

;; 図形削除コマンド
(defn make-remove-shape-command
  "図形削除コマンドを作成"
  [index]
  {:command-type :remove-shape
   :index index
   :removed-shape nil})

(defmethod execute :remove-shape
  [cmd]
  (fn [canvas]
    (let [shape (get-in canvas [:shapes (:index cmd)])]
      (-> canvas
          (update :shapes
                  (fn [shapes]
                    (vec (concat (subvec shapes 0 (:index cmd))
                                 (subvec shapes (inc (:index cmd)))))))
          ;; 削除された図形をコマンドに記録（undo用）
          (assoc-in [:last-removed] shape)))))

(defmethod undo :remove-shape
  [cmd]
  (fn [canvas]
    (let [shape (:last-removed canvas)]
      (update canvas :shapes
              (fn [shapes]
                (vec (concat (subvec shapes 0 (:index cmd))
                             [shape]
                             (subvec shapes (:index cmd)))))))))

(defmethod describe :remove-shape
  [cmd]
  (str "Remove shape[" (:index cmd) "]"))

;; マクロコマンド（複数コマンドをまとめる）
(defn make-macro-command
  "マクロコマンドを作成"
  [commands]
  {:command-type :macro
   :commands commands})

(defmethod execute :macro
  [cmd]
  (fn [canvas]
    (reduce (fn [c sub-cmd]
              ((execute sub-cmd) c))
            canvas
            (:commands cmd))))

(defmethod undo :macro
  [cmd]
  (fn [canvas]
    (reduce (fn [c sub-cmd]
              ((undo sub-cmd) c))
            canvas
            (reverse (:commands cmd)))))

(defmethod describe :macro
  [cmd]
  (str "Macro[" (count (:commands cmd)) " commands]"))
