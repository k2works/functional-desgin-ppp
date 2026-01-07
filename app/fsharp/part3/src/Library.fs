namespace FunctionalDesign.Part3

// ============================================
// 第7章: Composite パターン
// ============================================

module CompositePattern =

    // ============================================
    // 1. 2D座標とバウンディングボックス
    // ============================================

    /// 2D座標
    type Point =
        { X: float
          Y: float }

        static member (+)(p1: Point, p2: Point) = { X = p1.X + p2.X; Y = p1.Y + p2.Y }
        static member (*)(p: Point, factor: float) = { X = p.X * factor; Y = p.Y * factor }

    module Point =
        let create x y = { X = x; Y = y }
        let origin = { X = 0.0; Y = 0.0 }

    /// バウンディングボックス
    type BoundingBox =
        { Min: Point
          Max: Point }

    module BoundingBox =
        let create minP maxP = { Min = minP; Max = maxP }

        let empty =
            { Min = Point.origin
              Max = Point.origin }

        let union (bb1: BoundingBox) (bb2: BoundingBox) =
            { Min = { X = min bb1.Min.X bb2.Min.X; Y = min bb1.Min.Y bb2.Min.Y }
              Max = { X = max bb1.Max.X bb2.Max.X; Y = max bb1.Max.Y bb2.Max.Y } }

        let width bb = bb.Max.X - bb.Min.X
        let height bb = bb.Max.Y - bb.Min.Y

    // ============================================
    // 2. Shape - 図形の Composite パターン
    // ============================================

    /// 図形の共通インターフェース（判別共用体）
    [<RequireQualifiedAccess>]
    type Shape =
        | Circle of center: Point * radius: float
        | Square of topLeft: Point * side: float
        | Rectangle of topLeft: Point * width: float * height: float
        | Composite of shapes: Shape list

    module Shape =
        /// 図形を移動
        let rec translate dx dy shape =
            match shape with
            | Shape.Circle(center, radius) ->
                Shape.Circle({ X = center.X + dx; Y = center.Y + dy }, radius)
            | Shape.Square(topLeft, side) ->
                Shape.Square({ X = topLeft.X + dx; Y = topLeft.Y + dy }, side)
            | Shape.Rectangle(topLeft, width, height) ->
                Shape.Rectangle({ X = topLeft.X + dx; Y = topLeft.Y + dy }, width, height)
            | Shape.Composite shapes ->
                Shape.Composite(shapes |> List.map (translate dx dy))

        /// 図形を拡大・縮小
        let rec scale factor shape =
            match shape with
            | Shape.Circle(center, radius) -> Shape.Circle(center, radius * factor)
            | Shape.Square(topLeft, side) -> Shape.Square(topLeft, side * factor)
            | Shape.Rectangle(topLeft, width, height) ->
                Shape.Rectangle(topLeft, width * factor, height * factor)
            | Shape.Composite shapes -> Shape.Composite(shapes |> List.map (scale factor))

        /// 図形の面積を計算
        let rec area shape =
            match shape with
            | Shape.Circle(_, radius) -> System.Math.PI * radius * radius
            | Shape.Square(_, side) -> side * side
            | Shape.Rectangle(_, width, height) -> width * height
            | Shape.Composite shapes -> shapes |> List.sumBy area

        /// バウンディングボックスを取得
        let rec boundingBox shape =
            match shape with
            | Shape.Circle(center, radius) ->
                { Min = { X = center.X - radius; Y = center.Y - radius }
                  Max = { X = center.X + radius; Y = center.Y + radius } }
            | Shape.Square(topLeft, side) ->
                { Min = topLeft
                  Max = { X = topLeft.X + side; Y = topLeft.Y + side } }
            | Shape.Rectangle(topLeft, width, height) ->
                { Min = topLeft
                  Max = { X = topLeft.X + width; Y = topLeft.Y + height } }
            | Shape.Composite shapes ->
                match shapes with
                | [] -> BoundingBox.empty
                | head :: tail -> tail |> List.fold (fun acc s -> BoundingBox.union acc (boundingBox s)) (boundingBox head)

        /// Composite に図形を追加
        let add shape composite =
            match composite with
            | Shape.Composite shapes -> Shape.Composite(shapes @ [ shape ])
            | _ -> Shape.Composite([ composite; shape ])

        /// Composite を平坦化（ネストした Composite を展開）
        let rec flatten shape =
            match shape with
            | Shape.Composite shapes -> shapes |> List.collect flatten
            | _ -> [ shape ]

        /// 図形の数を取得
        let rec count shape =
            match shape with
            | Shape.Composite shapes -> shapes |> List.sumBy count
            | _ -> 1

        /// 空の Composite を作成
        let emptyComposite = Shape.Composite []

    // ============================================
    // 3. Switchable - スイッチの Composite パターン
    // ============================================

    /// スイッチの共通インターフェース
    [<RequireQualifiedAccess>]
    type Switchable =
        | Light of on: bool * name: string
        | DimmableLight of intensity: int * name: string
        | Fan of on: bool * speed: int * name: string
        | Composite of switchables: Switchable list * name: string

    module Switchable =
        /// スイッチをオンにする
        let rec turnOn switchable =
            match switchable with
            | Switchable.Light(_, name) -> Switchable.Light(true, name)
            | Switchable.DimmableLight(_, name) -> Switchable.DimmableLight(100, name)
            | Switchable.Fan(_, speed, name) -> Switchable.Fan(true, speed, name)
            | Switchable.Composite(switchables, name) ->
                Switchable.Composite(switchables |> List.map turnOn, name)

        /// スイッチをオフにする
        let rec turnOff switchable =
            match switchable with
            | Switchable.Light(_, name) -> Switchable.Light(false, name)
            | Switchable.DimmableLight(_, name) -> Switchable.DimmableLight(0, name)
            | Switchable.Fan(_, _, name) -> Switchable.Fan(false, 0, name)
            | Switchable.Composite(switchables, name) ->
                Switchable.Composite(switchables |> List.map turnOff, name)

        /// スイッチがオンかどうか
        let rec isOn switchable =
            match switchable with
            | Switchable.Light(on, _) -> on
            | Switchable.DimmableLight(intensity, _) -> intensity > 0
            | Switchable.Fan(on, _, _) -> on
            | Switchable.Composite(switchables, _) -> switchables |> List.exists isOn

        /// すべてのスイッチがオンかどうか
        let rec allOn switchable =
            match switchable with
            | Switchable.Light(on, _) -> on
            | Switchable.DimmableLight(intensity, _) -> intensity > 0
            | Switchable.Fan(on, _, _) -> on
            | Switchable.Composite(switchables, _) ->
                not (List.isEmpty switchables) && switchables |> List.forall allOn

        /// Composite にスイッチを追加
        let add switchable composite =
            match composite with
            | Switchable.Composite(switchables, name) ->
                Switchable.Composite(switchables @ [ switchable ], name)
            | _ -> Switchable.Composite([ composite; switchable ], "Group")

        /// 調光レベルを設定
        let setIntensity value switchable =
            let clampedValue = max 0 (min 100 value)

            match switchable with
            | Switchable.DimmableLight(_, name) -> Switchable.DimmableLight(clampedValue, name)
            | _ -> switchable

        /// ファンの速度を設定
        let setSpeed speed switchable =
            let clampedSpeed = max 0 (min 3 speed)

            match switchable with
            | Switchable.Fan(on, _, name) -> Switchable.Fan(on, clampedSpeed, name)
            | _ -> switchable

        /// 名前を取得
        let getName switchable =
            match switchable with
            | Switchable.Light(_, name) -> name
            | Switchable.DimmableLight(_, name) -> name
            | Switchable.Fan(_, _, name) -> name
            | Switchable.Composite(_, name) -> name

        /// 空の Composite を作成
        let emptyComposite name = Switchable.Composite([], name)

    // ============================================
    // 4. FileSystem - ファイルシステムの Composite パターン
    // ============================================

    /// ファイルシステムエントリ
    [<RequireQualifiedAccess>]
    type FileSystemEntry =
        | File of name: string * size: int64 * extension: string
        | Directory of name: string * children: FileSystemEntry list

    module FileSystemEntry =
        /// サイズを取得
        let rec size entry =
            match entry with
            | FileSystemEntry.File(_, fileSize, _) -> fileSize
            | FileSystemEntry.Directory(_, children) -> children |> List.sumBy size

        /// 名前を取得
        let name entry =
            match entry with
            | FileSystemEntry.File(n, _, _) -> n
            | FileSystemEntry.Directory(n, _) -> n

        /// パスを取得（親パスを指定）
        let rec path parentPath entry =
            let currentPath =
                if System.String.IsNullOrEmpty(parentPath) then
                    name entry
                else
                    parentPath + "/" + name entry

            match entry with
            | FileSystemEntry.File _ -> currentPath
            | FileSystemEntry.Directory _ -> currentPath

        /// ファイル数を取得
        let rec fileCount entry =
            match entry with
            | FileSystemEntry.File _ -> 1
            | FileSystemEntry.Directory(_, children) -> children |> List.sumBy fileCount

        /// ディレクトリ数を取得
        let rec directoryCount entry =
            match entry with
            | FileSystemEntry.File _ -> 0
            | FileSystemEntry.Directory(_, children) ->
                1 + (children |> List.sumBy directoryCount)

        /// エントリを検索
        let rec find predicate entry =
            match entry with
            | FileSystemEntry.File _ as f ->
                if predicate f then [ f ] else []
            | FileSystemEntry.Directory(_, children) as d ->
                let childResults = children |> List.collect (find predicate)
                if predicate d then d :: childResults else childResults

        /// 拡張子でファイルを検索
        let findByExtension ext entry =
            find
                (function
                | FileSystemEntry.File(_, _, e) -> e = ext
                | _ -> false)
                entry

        /// 名前でエントリを検索
        let findByName (searchName: string) entry =
            find
                (fun e ->
                    match e with
                    | FileSystemEntry.File(n, _, _) -> n.Contains(searchName: string)
                    | FileSystemEntry.Directory(n, _) -> n.Contains(searchName: string))
                entry

        /// ディレクトリにエントリを追加
        let add entry directory =
            match directory with
            | FileSystemEntry.Directory(dirName, children) ->
                FileSystemEntry.Directory(dirName, children @ [ entry ])
            | _ -> directory

        /// すべてのファイルを取得
        let rec allFiles entry =
            match entry with
            | FileSystemEntry.File _ as f -> [ f ]
            | FileSystemEntry.Directory(_, children) -> children |> List.collect allFiles

        /// すべてのディレクトリを取得
        let rec allDirectories entry =
            match entry with
            | FileSystemEntry.File _ -> []
            | FileSystemEntry.Directory(_, children) as d -> d :: (children |> List.collect allDirectories)

    // ============================================
    // 5. Menu - メニューの Composite パターン
    // ============================================

    /// メニュー項目
    [<RequireQualifiedAccess>]
    type MenuItem =
        | Item of name: string * price: decimal * category: string
        | SetMenu of name: string * items: MenuItem list * discountRate: float

    module MenuItem =
        /// 価格を計算
        let rec price menuItem =
            match menuItem with
            | MenuItem.Item(_, itemPrice, _) -> itemPrice
            | MenuItem.SetMenu(_, items, discountRate) ->
                let totalPrice = items |> List.sumBy price
                totalPrice * (1m - decimal discountRate)

        /// 名前を取得
        let name menuItem =
            match menuItem with
            | MenuItem.Item(n, _, _) -> n
            | MenuItem.SetMenu(n, _, _) -> n

        /// カテゴリを取得（Item のみ）
        let category menuItem =
            match menuItem with
            | MenuItem.Item(_, _, cat) -> Some cat
            | MenuItem.SetMenu _ -> None

        /// セットメニューに項目を追加
        let addToSet item setMenu =
            match setMenu with
            | MenuItem.SetMenu(name, items, discount) -> MenuItem.SetMenu(name, items @ [ item ], discount)
            | _ -> setMenu

        /// すべてのアイテムを取得（セットを展開）
        let rec allItems menuItem =
            match menuItem with
            | MenuItem.Item _ as item -> [ item ]
            | MenuItem.SetMenu(_, items, _) -> items |> List.collect allItems

        /// アイテム数を取得
        let rec itemCount menuItem =
            match menuItem with
            | MenuItem.Item _ -> 1
            | MenuItem.SetMenu(_, items, _) -> items |> List.sumBy itemCount

    // ============================================
    // 6. Expression - 数式の Composite パターン
    // ============================================

    /// 数式
    [<RequireQualifiedAccess>]
    type Expression =
        | Number of float
        | Variable of name: string * value: float option
        | Add of left: Expression * right: Expression
        | Subtract of left: Expression * right: Expression
        | Multiply of left: Expression * right: Expression
        | Divide of left: Expression * right: Expression
        | Negate of Expression

    module Expression =
        /// 数式を評価
        let rec evaluate expr =
            match expr with
            | Expression.Number n -> n
            | Expression.Variable(name, value) ->
                match value with
                | Some v -> v
                | None -> failwithf "Variable %s has no value" name
            | Expression.Add(left, right) -> evaluate left + evaluate right
            | Expression.Subtract(left, right) -> evaluate left - evaluate right
            | Expression.Multiply(left, right) -> evaluate left * evaluate right
            | Expression.Divide(left, right) ->
                let divisor = evaluate right
                if divisor = 0.0 then failwith "Division by zero"
                else evaluate left / divisor
            | Expression.Negate e -> -(evaluate e)

        /// 数式を簡略化
        let rec simplify expr =
            match expr with
            | Expression.Number _ -> expr
            | Expression.Variable(_, Some v) -> Expression.Number v
            | Expression.Variable _ -> expr
            | Expression.Add(left, right) ->
                match simplify left, simplify right with
                | Expression.Number 0.0, r -> r
                | l, Expression.Number 0.0 -> l
                | Expression.Number a, Expression.Number b -> Expression.Number(a + b)
                | l, r -> Expression.Add(l, r)
            | Expression.Subtract(left, right) ->
                match simplify left, simplify right with
                | l, Expression.Number 0.0 -> l
                | Expression.Number a, Expression.Number b -> Expression.Number(a - b)
                | l, r -> Expression.Subtract(l, r)
            | Expression.Multiply(left, right) ->
                match simplify left, simplify right with
                | Expression.Number 0.0, _ -> Expression.Number 0.0
                | _, Expression.Number 0.0 -> Expression.Number 0.0
                | Expression.Number 1.0, r -> r
                | l, Expression.Number 1.0 -> l
                | Expression.Number a, Expression.Number b -> Expression.Number(a * b)
                | l, r -> Expression.Multiply(l, r)
            | Expression.Divide(left, right) ->
                match simplify left, simplify right with
                | Expression.Number 0.0, _ -> Expression.Number 0.0
                | l, Expression.Number 1.0 -> l
                | Expression.Number a, Expression.Number b when b <> 0.0 -> Expression.Number(a / b)
                | l, r -> Expression.Divide(l, r)
            | Expression.Negate e ->
                match simplify e with
                | Expression.Number n -> Expression.Number(-n)
                | Expression.Negate inner -> inner
                | simplified -> Expression.Negate simplified

        /// 変数を取得
        let rec variables expr =
            match expr with
            | Expression.Number _ -> Set.empty
            | Expression.Variable(name, None) -> Set.singleton name
            | Expression.Variable(_, Some _) -> Set.empty
            | Expression.Add(left, right) -> Set.union (variables left) (variables right)
            | Expression.Subtract(left, right) -> Set.union (variables left) (variables right)
            | Expression.Multiply(left, right) -> Set.union (variables left) (variables right)
            | Expression.Divide(left, right) -> Set.union (variables left) (variables right)
            | Expression.Negate e -> variables e

        /// 変数に値をバインド
        let rec bind bindings expr =
            match expr with
            | Expression.Number _ -> expr
            | Expression.Variable(name, _) ->
                match Map.tryFind name bindings with
                | Some v -> Expression.Variable(name, Some v)
                | None -> expr
            | Expression.Add(left, right) -> Expression.Add(bind bindings left, bind bindings right)
            | Expression.Subtract(left, right) -> Expression.Subtract(bind bindings left, bind bindings right)
            | Expression.Multiply(left, right) -> Expression.Multiply(bind bindings left, bind bindings right)
            | Expression.Divide(left, right) -> Expression.Divide(bind bindings left, bind bindings right)
            | Expression.Negate e -> Expression.Negate(bind bindings e)

        /// 数式を文字列に変換
        let rec toString expr =
            match expr with
            | Expression.Number n -> string n
            | Expression.Variable(name, _) -> name
            | Expression.Add(left, right) -> sprintf "(%s + %s)" (toString left) (toString right)
            | Expression.Subtract(left, right) -> sprintf "(%s - %s)" (toString left) (toString right)
            | Expression.Multiply(left, right) -> sprintf "(%s * %s)" (toString left) (toString right)
            | Expression.Divide(left, right) -> sprintf "(%s / %s)" (toString left) (toString right)
            | Expression.Negate e -> sprintf "-%s" (toString e)

    // ============================================
    // 7. Organization - 組織構造の Composite パターン
    // ============================================

    /// 組織の構成員
    [<RequireQualifiedAccess>]
    type OrganizationMember =
        | Employee of name: string * salary: decimal * role: string
        | Department of name: string * members: OrganizationMember list * manager: string option

    module OrganizationMember =
        /// 総給与を計算
        let rec totalSalary orgMember =
            match orgMember with
            | OrganizationMember.Employee(_, salary, _) -> salary
            | OrganizationMember.Department(_, members, _) -> members |> List.sumBy totalSalary

        /// 名前を取得
        let name orgMember =
            match orgMember with
            | OrganizationMember.Employee(n, _, _) -> n
            | OrganizationMember.Department(n, _, _) -> n

        /// 従業員数を取得
        let rec employeeCount orgMember =
            match orgMember with
            | OrganizationMember.Employee _ -> 1
            | OrganizationMember.Department(_, members, _) -> members |> List.sumBy employeeCount

        /// 部門数を取得（自身は除く）
        let rec departmentCount orgMember =
            match orgMember with
            | OrganizationMember.Employee _ -> 0
            | OrganizationMember.Department(_, members, _) ->
                members
                |> List.sumBy (fun m ->
                    match m with
                    | OrganizationMember.Department _ -> 1 + departmentCount m
                    | _ -> 0)

        /// 部門にメンバーを追加
        let addMember newMember department =
            match department with
            | OrganizationMember.Department(deptName, members, manager) ->
                OrganizationMember.Department(deptName, members @ [ newMember ], manager)
            | _ -> department

        /// 役職で従業員を検索
        let rec findByRole role orgMember =
            match orgMember with
            | OrganizationMember.Employee(_, _, r) as emp ->
                if r = role then [ emp ] else []
            | OrganizationMember.Department(_, members, _) -> members |> List.collect (findByRole role)

        /// すべての従業員を取得
        let rec allEmployees orgMember =
            match orgMember with
            | OrganizationMember.Employee _ as emp -> [ emp ]
            | OrganizationMember.Department(_, members, _) -> members |> List.collect allEmployees


// ============================================
// 第8章: Decorator パターン
// ============================================

module DecoratorPattern =

    // ============================================
    // 1. JournaledShape - 形状デコレータ
    // ============================================

    /// ジャーナルエントリ（操作の記録）
    type JournalEntry =
        | Translate of dx: float * dy: float
        | Scale of factor: float
        | Rotate of angle: float

    /// 基本形状（デコレート対象）
    [<RequireQualifiedAccess>]
    type Shape =
        | Circle of centerX: float * centerY: float * radius: float
        | Square of topLeftX: float * topLeftY: float * side: float
        | Rectangle of topLeftX: float * topLeftY: float * width: float * height: float

    module Shape =
        let translate dx dy shape =
            match shape with
            | Shape.Circle(cx, cy, r) -> Shape.Circle(cx + dx, cy + dy, r)
            | Shape.Square(x, y, s) -> Shape.Square(x + dx, y + dy, s)
            | Shape.Rectangle(x, y, w, h) -> Shape.Rectangle(x + dx, y + dy, w, h)

        let scale factor shape =
            match shape with
            | Shape.Circle(cx, cy, r) -> Shape.Circle(cx, cy, r * factor)
            | Shape.Square(x, y, s) -> Shape.Square(x, y, s * factor)
            | Shape.Rectangle(x, y, w, h) -> Shape.Rectangle(x, y, w * factor, h * factor)

        let area shape =
            match shape with
            | Shape.Circle(_, _, r) -> System.Math.PI * r * r
            | Shape.Square(_, _, s) -> s * s
            | Shape.Rectangle(_, _, w, h) -> w * h

    /// ジャーナル付き形状（デコレータ）
    type JournaledShape =
        { Shape: Shape
          Journal: JournalEntry list }

    module JournaledShape =
        let create shape =
            { Shape = shape; Journal = [] }

        let translate dx dy js =
            { Shape = Shape.translate dx dy js.Shape
              Journal = js.Journal @ [ Translate(dx, dy) ] }

        let scale factor js =
            { Shape = Shape.scale factor js.Shape
              Journal = js.Journal @ [ Scale factor ] }

        let area js = Shape.area js.Shape

        let clearJournal js = { js with Journal = [] }

        let getJournal js = js.Journal

        let getShape js = js.Shape

        /// ジャーナルエントリを再生
        let replay entries js =
            entries
            |> List.fold
                (fun acc entry ->
                    match entry with
                    | Translate(dx, dy) -> translate dx dy acc
                    | Scale factor -> scale factor acc
                    | Rotate _ -> acc)
                js

    // ============================================
    // 2. 関数デコレータ
    // ============================================

    /// ログコレクター（副作用を追跡）
    type LogCollector() =
        let mutable logs: string list = []
        member _.Add(msg: string) = logs <- logs @ [ msg ]
        member _.GetLogs() = logs
        member _.Clear() = logs <- []

    /// ログ付きデコレータ
    let withLogging (name: string) (collector: LogCollector) (f: 'a -> 'b) : 'a -> 'b =
        fun a ->
            collector.Add(sprintf "[%s] called with: %A" name a)
            let result = f a
            collector.Add(sprintf "[%s] returned: %A" name result)
            result

    /// リトライデコレータ
    let withRetry (maxRetries: int) (f: 'a -> 'b) : 'a -> 'b =
        fun a ->
            let rec attempt remaining =
                try
                    f a
                with ex ->
                    if remaining > 0 then
                        attempt (remaining - 1)
                    else
                        raise ex

            attempt maxRetries

    /// キャッシュデコレータ
    let withCache () : ('a -> 'b) -> ('a -> 'b) =
        fun f ->
            let cache = System.Collections.Generic.Dictionary<'a, 'b>()

            fun a ->
                if cache.ContainsKey(a) then
                    cache.[a]
                else
                    let result = f a
                    cache.[a] <- result
                    result

    /// バリデーションデコレータ
    let withValidation (validator: 'a -> bool) (errorMsg: string) (f: 'a -> 'b) : 'a -> 'b =
        fun a ->
            if validator a then
                f a
            else
                invalidArg "input" (sprintf "%s: %A" errorMsg a)

    /// タイムアウトデコレータ（同期版、簡易実装）
    let withTimeout (timeoutMs: int) (f: 'a -> 'b) : 'a -> 'b =
        fun a ->
            let task =
                System.Threading.Tasks.Task.Run(fun () -> f a)

            if task.Wait(timeoutMs) then
                task.Result
            else
                raise (System.TimeoutException("Operation timed out"))

    /// 計測デコレータ
    let withTiming (collector: LogCollector) (name: string) (f: 'a -> 'b) : 'a -> 'b =
        fun a ->
            let sw = System.Diagnostics.Stopwatch.StartNew()
            let result = f a
            sw.Stop()
            collector.Add(sprintf "[%s] took %d ms" name sw.ElapsedMilliseconds)
            result

    /// Option結果デコレータ（例外をOptionに変換）
    let withOptionResult (f: 'a -> 'b) : 'a -> 'b option =
        fun a ->
            try
                Some(f a)
            with _ ->
                None

    /// Either結果デコレータ（例外をResultに変換）
    let withEitherResult (f: 'a -> 'b) : 'a -> Result<'b, exn> =
        fun a ->
            try
                Ok(f a)
            with ex ->
                Error ex

    /// デフォルト値デコレータ
    let withDefault (defaultValue: 'b) (f: 'a -> 'b) : 'a -> 'b =
        fun a ->
            try
                f a
            with _ ->
                defaultValue

    // ============================================
    // 3. デコレータの合成
    // ============================================

    /// 複数のデコレータを合成
    let composeDecorators (decorators: (('a -> 'b) -> ('a -> 'b)) list) (f: 'a -> 'b) : 'a -> 'b =
        decorators |> List.fold (fun decorated decorator -> decorator decorated) f

    // ============================================
    // 4. AuditedList - コレクションデコレータ
    // ============================================

    /// 操作履歴付きリスト
    type AuditedList<'T> =
        { Items: 'T list
          Operations: string list }

    module AuditedList =
        let empty<'T> : AuditedList<'T> = { Items = []; Operations = [] }

        let add (item: 'T) (list: AuditedList<'T>) =
            { Items = list.Items @ [ item ]
              Operations = list.Operations @ [ sprintf "add(%A)" item ] }

        let remove (item: 'T) (list: AuditedList<'T>) =
            { Items = list.Items |> List.filter ((<>) item)
              Operations = list.Operations @ [ sprintf "remove(%A)" item ] }

        let map (f: 'T -> 'U) (list: AuditedList<'T>) : AuditedList<'U> =
            { Items = List.map f list.Items
              Operations = list.Operations @ [ "map" ] }

        let filter (predicate: 'T -> bool) (list: AuditedList<'T>) =
            { Items = List.filter predicate list.Items
              Operations = list.Operations @ [ "filter" ] }

        let items (list: AuditedList<'T>) = list.Items
        let operations (list: AuditedList<'T>) = list.Operations
        let clearOperations (list: AuditedList<'T>) = { list with Operations = [] }

    // ============================================
    // 5. HTTPクライアントデコレータ（型定義）
    // ============================================

    /// HTTPレスポンス
    type HttpResponse = { StatusCode: int; Body: string }

    /// HTTPクライアントインターフェース
    type IHttpClient =
        abstract member Get: string -> HttpResponse

    /// シンプルなHTTPクライアント
    type SimpleHttpClient() =
        interface IHttpClient with
            member _.Get(url: string) =
                { StatusCode = 200
                  Body = sprintf "Response from %s" url }

    /// ログ付きHTTPクライアント（デコレータ）
    type LoggingHttpClient(client: IHttpClient, collector: LogCollector) =
        interface IHttpClient with
            member _.Get(url: string) =
                collector.Add(sprintf "[HTTP] GET %s" url)
                let response = client.Get(url)
                collector.Add(sprintf "[HTTP] Response: %d" response.StatusCode)
                response

    /// キャッシュ付きHTTPクライアント（デコレータ）
    type CachingHttpClient(client: IHttpClient) =
        let cache = System.Collections.Generic.Dictionary<string, HttpResponse>()

        interface IHttpClient with
            member _.Get(url: string) =
                if cache.ContainsKey(url) then
                    cache.[url]
                else
                    let response = client.Get(url)
                    cache.[url] <- response
                    response

    // ============================================
    // 6. FunctionBuilder - ビルダースタイル
    // ============================================

    /// 関数ビルダー
    type FunctionBuilder<'a, 'b>(f: 'a -> 'b, collector: LogCollector) =
        let mutable current = f

        member _.WithLogging(name: string) =
            current <- withLogging name collector current
            FunctionBuilder(current, collector)

        member _.WithValidation(validator: 'a -> bool, errorMsg: string) =
            current <- withValidation validator errorMsg current
            FunctionBuilder(current, collector)

        member _.WithRetry(maxRetries: int) =
            current <- withRetry maxRetries current
            FunctionBuilder(current, collector)

        member _.WithTiming(name: string) =
            current <- withTiming collector name current
            FunctionBuilder(current, collector)

        member _.Build() = current

    module FunctionBuilder =
        let create (collector: LogCollector) (f: 'a -> 'b) = FunctionBuilder(f, collector)

    // ============================================
    // 7. TransactionalOperation - トランザクションデコレータ
    // ============================================

    /// トランザクション状態
    type TransactionState =
        | NotStarted
        | InProgress
        | Committed
        | RolledBack

    /// トランザクション付き操作
    type TransactionalOperation<'T> =
        { Operations: ('T -> 'T) list
          State: TransactionState
          OriginalValue: 'T option
          CurrentValue: 'T option }

    module TransactionalOperation =
        let create () =
            { Operations = []
              State = NotStarted
              OriginalValue = None
              CurrentValue = None }

        let begin' (value: 'T) (tx: TransactionalOperation<'T>) =
            { tx with
                State = InProgress
                OriginalValue = Some value
                CurrentValue = Some value }

        let addOperation (op: 'T -> 'T) (tx: TransactionalOperation<'T>) =
            match tx.State with
            | InProgress ->
                let newValue = tx.CurrentValue |> Option.map op
                { tx with
                    Operations = tx.Operations @ [ op ]
                    CurrentValue = newValue }
            | _ -> tx

        let commit (tx: TransactionalOperation<'T>) =
            match tx.State with
            | InProgress -> { tx with State = Committed }
            | _ -> tx

        let rollback (tx: TransactionalOperation<'T>) =
            match tx.State with
            | InProgress ->
                { tx with
                    State = RolledBack
                    CurrentValue = tx.OriginalValue
                    Operations = [] }
            | _ -> tx

        let getValue (tx: TransactionalOperation<'T>) = tx.CurrentValue


// ============================================
// 第9章: Adapter パターン
// ============================================

module AdapterPattern =

    // ============================================
    // 1. VariableLightAdapter - インターフェースアダプター
    // ============================================

    /// スイッチの共通インターフェース
    type ISwitchable =
        abstract member TurnOn: unit -> ISwitchable
        abstract member TurnOff: unit -> ISwitchable
        abstract member IsOn: bool

    /// 可変強度ライト（既存クラス - アダプティー）
    type VariableLight =
        { Intensity: int }

        static member Create(intensity: int) =
            { Intensity = max 0 (min 100 intensity) }

        member this.SetIntensity(value: int) =
            { Intensity = max 0 (min 100 value) }

        member this.Brighten(amount: int) =
            this.SetIntensity(this.Intensity + amount)

        member this.Dim(amount: int) =
            this.SetIntensity(this.Intensity - amount)

    /// VariableLight を ISwitchable に適応させるアダプター
    type VariableLightAdapter(light: VariableLight, minIntensity: int, maxIntensity: int) =
        member _.Light = light
        member _.MinIntensity = minIntensity
        member _.MaxIntensity = maxIntensity

        interface ISwitchable with
            member this.TurnOn() =
                VariableLightAdapter(light.SetIntensity(maxIntensity), minIntensity, maxIntensity)

            member this.TurnOff() =
                VariableLightAdapter(light.SetIntensity(minIntensity), minIntensity, maxIntensity)

            member this.IsOn = light.Intensity > minIntensity

    module VariableLightAdapter =
        let create light =
            VariableLightAdapter(light, 0, 100)

        let createWithRange minI maxI light =
            VariableLightAdapter(light, minI, maxI)

        let getIntensity (adapter: VariableLightAdapter) =
            adapter.Light.Intensity

    // ============================================
    // 2. UserFormatAdapter - データフォーマット変換
    // ============================================

    /// 旧ユーザーフォーマット
    type OldUserFormat =
        { FirstName: string
          LastName: string
          EmailAddress: string
          PhoneNumber: string }

    /// 新ユーザーフォーマット
    type NewUserFormat =
        { Name: string
          Email: string
          Phone: string
          Metadata: Map<string, obj> }

    module UserFormatAdapter =
        /// 旧フォーマット → 新フォーマット
        let adaptOldToNew (old: OldUserFormat) : NewUserFormat =
            { Name = sprintf "%s %s" old.LastName old.FirstName
              Email = old.EmailAddress
              Phone = old.PhoneNumber
              Metadata =
                Map.ofList
                    [ ("migrated", box true)
                      ("originalFormat", box "old") ] }

        /// 新フォーマット → 旧フォーマット
        let adaptNewToOld (newUser: NewUserFormat) : OldUserFormat =
            let nameParts = newUser.Name.Split(' ') |> Array.toList

            let (lastName, firstName) =
                match nameParts with
                | [ ln; fn ] -> (ln, fn)
                | [ ln ] -> (ln, "")
                | ln :: rest -> (ln, String.concat " " rest)
                | [] -> ("", "")

            { FirstName = firstName
              LastName = lastName
              EmailAddress = newUser.Email
              PhoneNumber = newUser.Phone }

    // ============================================
    // 3. TemperatureAdapter - 単位変換
    // ============================================

    /// 摂氏
    type Celsius = Celsius of float

    /// 華氏
    type Fahrenheit = Fahrenheit of float

    /// ケルビン
    type Kelvin = Kelvin of float

    module TemperatureAdapter =
        let celsiusToFahrenheit (Celsius c) =
            Fahrenheit(c * 9.0 / 5.0 + 32.0)

        let fahrenheitToCelsius (Fahrenheit f) =
            Celsius((f - 32.0) * 5.0 / 9.0)

        let celsiusToKelvin (Celsius c) = Kelvin(c + 273.15)

        let kelvinToCelsius (Kelvin k) = Celsius(k - 273.15)

        let fahrenheitToKelvin f =
            f |> fahrenheitToCelsius |> celsiusToKelvin

        let kelvinToFahrenheit k =
            k |> kelvinToCelsius |> celsiusToFahrenheit

    // ============================================
    // 4. DateTimeAdapter - 日時フォーマット変換
    // ============================================

    module DateTimeAdapter =
        /// Unix タイムスタンプ → DateTime
        let fromUnixTimestamp (timestamp: int64) =
            System.DateTimeOffset.FromUnixTimeSeconds(timestamp).DateTime

        /// DateTime → Unix タイムスタンプ
        let toUnixTimestamp (dt: System.DateTime) =
            System.DateTimeOffset(dt).ToUnixTimeSeconds()

        /// ISO 8601 文字列 → DateTime
        let fromIso8601 (str: string) =
            try
                Some(System.DateTime.Parse(str, null, System.Globalization.DateTimeStyles.RoundtripKind))
            with _ ->
                None

        /// DateTime → ISO 8601 文字列
        let toIso8601 (dt: System.DateTime) =
            dt.ToString("o")

        /// カスタムフォーマット文字列 → DateTime
        let fromCustomFormat (format: string) (str: string) =
            try
                Some(System.DateTime.ParseExact(str, format, System.Globalization.CultureInfo.InvariantCulture))
            with _ ->
                None

        /// DateTime → カスタムフォーマット文字列
        let toCustomFormat (format: string) (dt: System.DateTime) =
            dt.ToString(format, System.Globalization.CultureInfo.InvariantCulture)

    // ============================================
    // 5. CurrencyAdapter - 通貨変換
    // ============================================

    /// 通貨型
    type Currency =
        | USD of decimal
        | EUR of decimal
        | JPY of decimal
        | GBP of decimal

    module CurrencyAdapter =
        /// 為替レート（USD基準）
        let private exchangeRates =
            Map.ofList
                [ ("USD", 1.0m)
                  ("EUR", 0.85m)
                  ("JPY", 110.0m)
                  ("GBP", 0.73m) ]

        /// USDに変換
        let toUSD currency =
            match currency with
            | USD amount -> USD amount
            | EUR amount -> USD(amount / exchangeRates.["EUR"])
            | JPY amount -> USD(amount / exchangeRates.["JPY"])
            | GBP amount -> USD(amount / exchangeRates.["GBP"])

        /// USDから変換
        let fromUSD (USD amount) targetCurrency =
            match targetCurrency with
            | "EUR" -> EUR(amount * exchangeRates.["EUR"])
            | "JPY" -> JPY(amount * exchangeRates.["JPY"])
            | "GBP" -> GBP(amount * exchangeRates.["GBP"])
            | _ -> USD amount

        /// 通貨間変換
        let convert source (target: string) =
            let (USD amount) = toUSD source
            fromUSD (USD amount) target

        /// 金額を取得
        let getAmount currency =
            match currency with
            | USD a -> a
            | EUR a -> a
            | JPY a -> a
            | GBP a -> a

    // ============================================
    // 6. FilePathAdapter - パス形式変換
    // ============================================

    module FilePathAdapter =
        /// Windows パス → Unix パス
        let windowsToUnix (path: string) =
            path.Replace("\\", "/")

        /// Unix パス → Windows パス
        let unixToWindows (path: string) =
            path.Replace("/", "\\")

        /// 相対パス → 絶対パス
        let toAbsolute (basePath: string) (relativePath: string) =
            System.IO.Path.GetFullPath(System.IO.Path.Combine(basePath, relativePath))

        /// パスコンポーネントを取得
        let getComponents (path: string) =
            path.Split([| '/'; '\\' |], System.StringSplitOptions.RemoveEmptyEntries)
            |> Array.toList

        /// コンポーネントからパスを構築
        let fromComponents (separator: char) (components: string list) =
            String.concat (string separator) components

    // ============================================
    // 7. LogLevelAdapter - ログレベル変換
    // ============================================

    /// アプリケーションのログレベル
    [<RequireQualifiedAccess>]
    type AppLogLevel =
        | Trace
        | Debug
        | Info
        | Warning
        | Error
        | Fatal

    /// 外部ライブラリのログレベル
    type ExternalLogLevel =
        | Verbose = 0
        | Debug = 1
        | Information = 2
        | Warning = 3
        | Error = 4
        | Critical = 5

    module LogLevelAdapter =
        let appToExternal level =
            match level with
            | AppLogLevel.Trace -> ExternalLogLevel.Verbose
            | AppLogLevel.Debug -> ExternalLogLevel.Debug
            | AppLogLevel.Info -> ExternalLogLevel.Information
            | AppLogLevel.Warning -> ExternalLogLevel.Warning
            | AppLogLevel.Error -> ExternalLogLevel.Error
            | AppLogLevel.Fatal -> ExternalLogLevel.Critical

        let externalToApp level =
            match level with
            | ExternalLogLevel.Verbose -> AppLogLevel.Trace
            | ExternalLogLevel.Debug -> AppLogLevel.Debug
            | ExternalLogLevel.Information -> AppLogLevel.Info
            | ExternalLogLevel.Warning -> AppLogLevel.Warning
            | ExternalLogLevel.Error -> AppLogLevel.Error
            | ExternalLogLevel.Critical -> AppLogLevel.Fatal
            | _ -> AppLogLevel.Info

    // ============================================
    // 8. JsonAdapter - JSON データ変換
    // ============================================

    /// 内部データ形式
    type InternalData =
        { Id: string
          Name: string
          Value: decimal
          Tags: string list }

    /// 外部JSON形式（シンプルなMap）
    type ExternalJsonData = Map<string, obj>

    module JsonAdapter =
        /// Map → InternalData
        let fromExternalJson (json: ExternalJsonData) : InternalData option =
            try
                let id = json.["id"] :?> string
                let name = json.["name"] :?> string
                let value = json.["value"] :?> decimal

                let tags =
                    match json.TryFind "tags" with
                    | Some t -> (t :?> obj list) |> List.map string
                    | None -> []

                Some
                    { Id = id
                      Name = name
                      Value = value
                      Tags = tags }
            with _ ->
                None

        /// InternalData → Map
        let toExternalJson (data: InternalData) : ExternalJsonData =
            Map.ofList
                [ ("id", box data.Id)
                  ("name", box data.Name)
                  ("value", box data.Value)
                  ("tags", box data.Tags) ]

    // ============================================
    // 9. CollectionAdapter - コレクション変換
    // ============================================

    module CollectionAdapter =
        /// Array → List
        let arrayToList (arr: 'T array) = Array.toList arr

        /// List → Array
        let listToArray (lst: 'T list) = List.toArray lst

        /// Seq → List
        let seqToList (seq: 'T seq) = Seq.toList seq

        /// List → Seq
        let listToSeq (lst: 'T list) = List.toSeq lst

        /// Dictionary → Map
        let dictToMap (dict: System.Collections.Generic.Dictionary<'K, 'V>) =
            dict |> Seq.map (fun kvp -> (kvp.Key, kvp.Value)) |> Map.ofSeq

        /// Map → Dictionary
        let mapToDict (map: Map<'K, 'V>) =
            let dict = System.Collections.Generic.Dictionary<'K, 'V>()
            map |> Map.iter (fun k v -> dict.[k] <- v)
            dict

    // ============================================
    // 10. ResultAdapter - 結果型変換
    // ============================================

    module ResultAdapter =
        /// Option → Result
        let optionToResult (error: 'E) (opt: 'T option) : Result<'T, 'E> =
            match opt with
            | Some v -> Ok v
            | None -> Error error

        /// Result → Option
        let resultToOption (result: Result<'T, 'E>) : 'T option =
            match result with
            | Ok v -> Some v
            | Error _ -> None

        /// Exception ベース → Result
        let tryToResult (f: unit -> 'T) : Result<'T, exn> =
            try
                Ok(f ())
            with ex ->
                Error ex

        /// Result → Exception ベース（例外をスロー）
        let resultToTry (result: Result<'T, exn>) : 'T =
            match result with
            | Ok v -> v
            | Error ex -> raise ex
