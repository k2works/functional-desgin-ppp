(ns abstract-server.user-service
  "Abstract Server パターン - UserService

   ユーザー管理のサービスです。
   Repository プロトコルに依存することで、
   具体的なデータストアから独立しています。"
  (:require [abstract-server.repository :as repo]))

;; =============================================================================
;; UserService の定義
;; =============================================================================

(defn create-user
  "ユーザーを作成"
  [repository name email]
  (let [user {:name name
              :email email
              :created-at (java.util.Date.)}]
    (repo/save repository user)))

(defn get-user
  "ユーザーを取得"
  [repository id]
  (repo/find-by-id repository id))

(defn get-all-users
  "全ユーザーを取得"
  [repository]
  (repo/find-all repository))

(defn update-user
  "ユーザーを更新"
  [repository id updates]
  (when-let [user (repo/find-by-id repository id)]
    (repo/save repository (merge user updates))))

(defn delete-user
  "ユーザーを削除"
  [repository id]
  (repo/delete repository id))

(defn find-by-email
  "メールアドレスでユーザーを検索"
  [repository email]
  (->> (repo/find-all repository)
       (filter #(= (:email %) email))
       first))
