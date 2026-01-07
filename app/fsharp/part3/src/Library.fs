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
