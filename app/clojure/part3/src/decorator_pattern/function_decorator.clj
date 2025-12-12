(ns decorator-pattern.function-decorator
  "Decorator パターン - 関数デコレータ

   高階関数を使用して、既存の関数に新しい機能を
   動的に追加します。ログ出力、リトライ、キャッシュなど
   の横断的関心事を実装します。")

;; =============================================================================
;; ログ出力デコレータ
;; =============================================================================

(defn with-logging
  "関数にログ出力を追加するデコレータ"
  [f name]
  (fn [& args]
    (println (str "[LOG] " name " called with: " args))
    (let [result (apply f args)]
      (println (str "[LOG] " name " returned: " result))
      result)))

;; =============================================================================
;; 実行時間計測デコレータ
;; =============================================================================

(defn with-timing
  "関数に実行時間計測を追加するデコレータ"
  [f name]
  (fn [& args]
    (let [start (System/nanoTime)
          result (apply f args)
          end (System/nanoTime)
          elapsed-ms (/ (- end start) 1000000.0)]
      (println (str "[TIMING] " name " took " elapsed-ms " ms"))
      result)))

;; =============================================================================
;; リトライデコレータ
;; =============================================================================

(defn with-retry
  "関数にリトライ機能を追加するデコレータ"
  [f max-retries]
  (fn [& args]
    (loop [attempts 0]
      (let [result (try
                     {:success true :value (apply f args)}
                     (catch Exception e
                       {:success false :error e}))]
        (if (:success result)
          (:value result)
          (if (< attempts max-retries)
            (do
              (println (str "[RETRY] Attempt " (inc attempts) " failed, retrying..."))
              (recur (inc attempts)))
            (throw (:error result))))))))

;; =============================================================================
;; キャッシュデコレータ
;; =============================================================================

(defn with-cache
  "関数にキャッシュを追加するデコレータ"
  [f]
  (let [cache (atom {})]
    (fn [& args]
      (if-let [cached (get @cache args)]
        (do
          (println "[CACHE] Hit for" args)
          cached)
        (let [result (apply f args)]
          (println "[CACHE] Miss for" args)
          (swap! cache assoc args result)
          result)))))

;; =============================================================================
;; バリデーションデコレータ
;; =============================================================================

(defn with-validation
  "関数に入力バリデーションを追加するデコレータ"
  [f validator error-msg]
  (fn [& args]
    (if (apply validator args)
      (apply f args)
      (throw (ex-info error-msg {:args args})))))

;; =============================================================================
;; デコレータの組み合わせ
;; =============================================================================

(defn compose-decorators
  "複数のデコレータを組み合わせる"
  [f & decorators]
  (reduce (fn [decorated decorator]
            (decorator decorated))
          f
          decorators))
