(ns abstract-server.repository
  "Abstract Server パターン - Repository

   データアクセスの抽象インターフェースを定義します。
   これにより、具体的なデータストアから独立したコードを書けます。")

;; =============================================================================
;; Repository プロトコル（Abstract Server）
;; =============================================================================

(defprotocol Repository
  "データリポジトリのインターフェース"
  (find-by-id [this id] "IDでエンティティを取得")
  (find-all [this] "全てのエンティティを取得")
  (save [this entity] "エンティティを保存")
  (delete [this id] "エンティティを削除"))
