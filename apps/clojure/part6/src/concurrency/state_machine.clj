(ns concurrency.state-machine
  "並行処理システム - 状態機械

   電話通話システムを状態機械パターンで実装します。
   Clojure のエージェントを使った非同期状態遷移を
   モデル化します。")

;; =============================================================================
;; 状態機械の定義
;; =============================================================================

(def user-sm
  "ユーザー状態機械の定義
   {現在の状態 {イベント [次の状態 アクション]}}"
  {:idle {:call [:calling :caller-off-hook]
          :ring [:waiting-for-connection :callee-off-hook]
          :disconnect [:idle nil]}
   :calling {:dialtone [:dialing :dial]}
   :dialing {:ringback [:waiting-for-connection nil]}
   :waiting-for-connection {:connected [:talking :talk]}
   :talking {:disconnect [:idle nil]}})

;; =============================================================================
;; アクション関数
;; =============================================================================

(defn caller-off-hook
  "発信者がオフフック（受話器を上げる）"
  [from-user to-user]
  (println (str from-user " picked up the phone to call " to-user)))

(defn callee-off-hook
  "着信者がオフフック（電話に出る）"
  [from-user to-user]
  (println (str from-user " answered the call from " to-user)))

(defn dial
  "ダイヤル"
  [from-user to-user]
  (println (str from-user " is dialing " to-user)))

(defn talk
  "通話開始"
  [from-user to-user]
  (println (str from-user " is now talking with " to-user)))

(def actions
  {:caller-off-hook caller-off-hook
   :callee-off-hook callee-off-hook
   :dial dial
   :talk talk})

;; =============================================================================
;; 状態機械エージェント
;; =============================================================================

(defn make-user-agent
  "ユーザーエージェントを作成"
  [user-id]
  (agent {:user-id user-id
          :state :idle
          :machine user-sm
          :peer nil}))

(defn get-state
  "現在の状態を取得"
  [user-agent]
  (:state @user-agent))

(defn get-user-id
  "ユーザーIDを取得"
  [user-agent]
  (:user-id @user-agent))

;; =============================================================================
;; 状態遷移
;; =============================================================================

(defn transition
  "状態遷移を実行"
  [agent-state event event-data]
  (let [{:keys [state machine user-id peer]} agent-state
        result (get-in machine [state event])]
    (if result
      (let [[next-state action-key] result
            action (get actions action-key)]
        (when action
          (action user-id (or (:peer event-data) peer "unknown")))
        (assoc agent-state
               :state next-state
               :peer (or (:peer event-data) peer)))
      (do
        (println (str "Invalid transition: " state " -> " event))
        agent-state))))

(defn send-event
  "イベントを送信"
  ([user-agent event]
   (send-event user-agent event {}))
  ([user-agent event event-data]
   (send user-agent transition event event-data)))

;; =============================================================================
;; 電話操作
;; =============================================================================

(defn make-call
  "電話をかける"
  [caller callee]
  (let [callee-id (get-user-id callee)]
    (send-event caller :call {:peer callee-id})
    (send-event callee :ring {:peer (get-user-id caller)})))

(defn answer-call
  "電話に出る"
  [caller callee]
  (send-event caller :dialtone {})
  (send-event caller :ringback {})
  (send-event caller :connected {})
  (send-event callee :connected {}))

(defn hang-up
  "電話を切る"
  [caller callee]
  (send-event caller :disconnect {})
  (send-event callee :disconnect {}))

;; =============================================================================
;; ユーティリティ
;; =============================================================================

(defn await-agents
  "全エージェントの処理完了を待つ"
  [& agents]
  (apply await agents))

(defn reset-agent
  "エージェントの状態をリセット"
  [user-agent]
  (send user-agent (fn [_] {:user-id (get-user-id user-agent)
                             :state :idle
                             :machine user-sm
                             :peer nil})))
