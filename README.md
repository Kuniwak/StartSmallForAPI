Swift の HTTP ライブラリで苦しまないための自作 API クライアント設計
===========================================

iOS 開発で必須とも言える API クライアントの設計手法を、標準ライブラリだけを使って紹介します。



はじめに
-------

あなたは、どのように API クライアントを設計していますか。

まずはライブラリを選ぶでしょうか。
それとも、クラス図を書くのでしょうか。
なるほど、なるほど、ふーむ。

この記事では、もっと別のより良い設計方法を紹介します。

紹介する設計方法は、ほとんど設計知識のない状況から始めることができます。しかも、最終的にはあなたのプロジェクトにぴったりの設計を手に入れられる方法です。



### 対象読者

さて、この記事では、対象読者を次のように設定しています:

- どのような API 設計にしたらいいかわからない人
- どのような API のライブラリを使うべきかわからない人

また、最終的には以下のレベルの目標を達成できることでしょう:

- あなたのプロジェクトの API 層設計者になれるレベル



目次 
----

1. はじめに
2. 目次
3. プロジェクトを準備する
4. インターフェースを想像する
    1. API についてわかっていることを整理する
    2. リクエストとレスポンス
    3. リクエストについてわかっていること
    4. リクエストとレスポンスの対応関係
    5. レスポンスについてわかっていること
    6. リクエストからレスポンスへの変換過程
5. わかっているところまでコードにする
    1. なぜコードにするのか
    2. `XCTestCase` クラスをつくる
    3. リクエストの入力部分をコードにする
    4. レスポンスの出力部分をコードにする
    5. レスポンスをわかりやすいオブジェクトへと変換する
    6. 非同期な部分をコードにする
6. 標準ライブラリから出発する
    1. `URLSession` クラスを使う
    2. リクエストを `URLRequest` へ変換する
    3. `URLResponse` などからレスポンスを作成する
    4. 通信部分を実装する
7. 使いやすさを再点検する
    1. API クライアントを使ってみる
    2. API 呼び出し部分を簡略化する
    3. 対応 API を増やしてみる
8. サードパーティ製ライブラリを使う
    1. 現時点の標準ライブラリでは対応していないもの
    2. サードパーティ製ライブラリを使うメリットとリスク
    3. Easy と Simple のどちらを選ぶべきか
9. 終わりに



プロジェクトを準備する
----------------------

この記事では、実際に手を動かしながら解説をします。



### STEP1: Single View App を作成する

まずは、Xcode9 を開き「Single View App」を作成しましょう。

プロジェクト名は「`StartSmallForAPI`」、チーム・組織名・組織IDは適当なもので構いません。
言語は「Swift」を選び、「Include Unit test」にチェックをつけておいてください。

![](https://raw.githubusercontent.com/Kuniwak/StartSmallForAPI/master/Documentation/Images/step-1.png)
![](https://raw.githubusercontent.com/Kuniwak/StartSmallForAPI/master/Documentation/Images/step-2.png)
![](https://raw.githubusercontent.com/Kuniwak/StartSmallForAPI/master/Documentation/Images/step-3.png)


### STEP2: `⌘ + U` で正常に作成できたことを確認する

新しいファイルをつくる前に、Destination に iOS Simulator のいずれかを選び（iPhone X とかで OK）、必ず ⌘+U を実行しましょう。

![](https://raw.githubusercontent.com/Kuniwak/StartSmallForAPI/master/Documentation/Images/step-4.png)

成功した場合は、次のようなモーダルが表示されます。

![](https://raw.githubusercontent.com/Kuniwak/StartSmallForAPI/master/Documentation/Images/step-5.png)

もし、これが失敗するようならプロジェクトをうまく作成できていません。最初からやり直してみてください。


### STEP3: 最初のファイルを作成する

うまくプロジェクトを作成できたら、Project navigator から「`StartSmallForAPI`」グループに「`WebAPI.swift`」を作成してください。ビルドターゲットには「`StartSmallForAPI`」を選んでおいてください。



### 準備完了！

お疲れ様です。
以上で準備が整いました。



インターフェースを想像する
--------------------

では、設計の主要部分であるインターフェースの設計に移ります。



### API についてわかっていることを整理する

インターフェースを設計する上では、わかっていることの整理がとても重要です。そのため、まずは一般的な API についてわかっていることを整理しましょう。



### リクエストとレスポンス

API にはリクエストとレスポンスがあります。一般的には、リクエストをサーバーへ送信し、サーバーの応答をレスポンスとして受け取ります。

```
           +---------+                +----------+
Client --> | Request | --> Server --> | Response | --> Client
           +---------+                +----------+
```

では、このリクエストについてわかっていることを整理しましょう。



### リクエストについてわかっていること

まず、個別の API に注目せずともリクエストについてわかっていることがあります。それは、すべての Web API が共通で備えている構成要素です。「なんだ、構成要素だけか」と思われるかもしれませんが、共通の構成要素を知ることはとても重要です。なぜなら、構成要素が同じであれば、多くの場合で同じコードを使いまわせるからです。

さて、リクエストは一般的に次の要素から構成されます:

<dl>
<dt>URL
<dd>
    <dl>
        <dt>説明
        <dd>リソースの所在地。
        <dt>例
        <dd><code>http://example.com/foo/bar</code>のような URL。</dd>
    </dl>
</dd>
<dt>URL クエリ文字列
<dd>
    <dl>
        <dt>説明
        <dd>URL に付与される、<code>?</code> 始まりで <code>&amp;</code> で連結された文字列。
        <dt>例
        <dd>GitHub API でページ番号や1ページに含まれる要素数を指定するクエリ文字列は <code>?page=1&per_page=100</code>。</dd>
    </dl>
</dd>
<dt>HTTP メソッド
<dd>
    <dl>
        <dt>説明
        <dd>リクエストの種類。
        <dt>例
        <dd>何かを取得したければ <code>GET</code> など、何かをサーバーへ送信したければ <code>POST</code> や <code>PUT</code> など。</dd>
    </dl>
</dd>
<dt>HTTP ヘッダー
<dd>
    <dl>
        <dt>説明
        <dd>リクエストに付与できる追加情報。ユーザーの認証や認可などによく使われる。
        <dt>例
        <dd>認可情報のトークンを示す HTTP ヘッダーは <code>Authorization: token XXXXXXXXX</code>。他にも送信主のアプリケーションを示す HTTP ヘッダーは <code>User-Agent: XXXXXX</code>。</dd>
    </dl>
</dd>
<dt>ペイロード
<dd>
    <dl>
        <dt>説明
        <dd>リクエストの本文。<code>POST</code> や <code>PUT</code> の送信内容はペイロードに置く決まりになっている。なお、HTTP メソッドが <code>GET</code> のときは、ペイロードは取れないという制約がある。
        <dt>例
        <dd>様々な種類があるが、<code>key=value</code> や <code>{"key":"value"}</code> のような文字列や、画像などのデータを配置できる。
    </dl>
</dd>
</dl>

さて、この世界の Web API のほとんどは、これらの構成要素を揃えています。そして、これらの構成要素はすべてリクエストとして指定できるようにするべきです。

たとえば、このリクエストの構成要素をすべて指定できることを前提とすれば、あなたの API でも GitHub の API でも同じコードを使いまわせます。しかし、もしいくつかの構成要素を指定できなくすると、コードを使いまわせる範囲が減っていきます。

また、別の例も考えてみましょう。今まで HTTP ヘッダーを指定していない状況から、サーバーのフレームワークが変わって HTTP ヘッダーを指定しないといけない状況に変わったとします。この状況でも依然としてクライアントが対応できるようにするためには、構成要素をなるべく広く受け取れるようにしておいた方がいいのです。

つまり、**使いまわせる範囲を広くしつつ、サーバーの変更にも耐えらえるようにするためには、なるべくこれら現時点で判明しているすべての構成要素をリクエストとして指定できるようにするべきなのです**。

さて、リクエストを送信した後、サーバーから返ってくるのがレスポンスです。このレスポンスについてもわかっていることを整理してみましょう。



### レスポンスについてわかっていること

レスポンスについてもわかっていることは構成要素です。
一般的に、レスポンスは次の要素から構成されます:

<dl>
<dt>HTTP ステータスコード
<dd>
    <dl>
        <dt>説明
        <dd>レスポンスの意味。
        <dt>例
        <dd>もし成功であれば 200 番台の整数で、よく見かける 404 は指定した項目が見つからないという意味を持つ。
    </dl>
</dd>
<dt>HTTP ヘッダー
<dd>
    <dl>
        <dt>説明
        <dd>レスポンスに付与できる追加情報。
        <dt>例
        <dd><code>Content-Type</code> ヘッダーは、後述するペイロードの形式を表す。また、<code>Link</code> ヘッダーは次のページや最後のページの URL を表す。
    </dl>
</dd>
<dt>ペイロード
<dd>
    <dl>
        <dt>説明
        <dd>レスポンスの内容。
        <dt>例
        <dd><code>Content-Type</code> の形式で表現されたデータ。このデータは画像や動画なこともあるので、文字列がくるとは限らない。
    </dl>
</dd>
</dl>

このレスポンスとリクエストの関係についても整理してみましょう。



### リクエストからレスポンスへの変換過程

一般的に、何かリクエストを選べば、対応するレスポンスはざっくりと決まります。つまり、リクエストとレスポンスの間には対応関係があるということです。

ただ、一点例外があり、リクエストを送信したとしてもレスポンスが返ってこない場合があります。たとえば、何らかの理由で通信が遮断されたり、サーバーが故障している場合にはレスポンスは返ってきません。以降では、これらのことを通信エラーと呼ぶことにします。

まとめると、**リクエストとレスポンスの間には、リクエストがレスポンスまたは通信エラーになるという対応関係があるということです**。

なお、一点付け加えるなら、この関係は非同期の対応関係になっています。なぜ非同期かというと、この変換の途中で UI の描画処理などを止めないためです。もし、UI の描画処理が止まってしまうと、API の呼び出しがあるたび、ユーザーは何も操作ができなくなってしまいます。これはなるべく避けたいですから、リクエストからレスポンスを受け取るまでは非同期であるべきなのです。

これまでで、リクエストとレスポンスについてわかっていることを整理できました。次から、実際に今わかっているところまでをコードにしてみましょう。



わかっているところまでをコードにする
------------------------------------

さて、ここまで読んだあなたは、1つ疑問を持っているかもしれません。
おそらく、この疑問は「私の API の詳細がわかっていないのに、私にぴったりな API 設計ができるのか」ということでしょう。

答えは、「Yes」です。
しかし不安でしょうから、これからの流れを軽く説明しておきましょう。はじめに、これまでわかっている一般的な部分をコード化します。次に、この一般的なコードをそれぞれの API に合った形へと修正していきます。そして最後に、ライブラリによるコードの省略について説明をします。

では、まず一般的な部分のコード化について説明してきます。



### なぜコードにするのか

しかし、ちょっと待ってください。
なぜ、クラス図などの設計文書も書かずにコードを書き始めるのでしょうか。

これには2つの目的があります:

1. より具体的にしたいから
2. 実際に動作を検証できた方が、自分の理解を確認できるから

これらの目的を満たすには、コードを書くことが一番です。そのため、設計文書については傍に置いておいて、わかっているところまでコードにしてみましょう。



### `XCTestCase` クラスをつくる

さて、先ほどコード化する目的の1つとして「実際に動作を検証できること」をあげました。この動作の検証とはどのようにすればいいのでしょうか。

ささっと Playground などを使ったりもできますが、きちんと設計したいときには Playground は不向きです。こういうとき、できるエンジニアは `XCTestCase` で動作を確認します。この `XCTestCase` は動作を確認するためのクラスで、Swift に標準で組み込まれています。

`XCTestCase` の使い方は簡単です。次のようなボイラープレートを用意し、ビルドターゲットを `StartSmallForAPITests` にしてから ⌘ + U で実行するだけです:

```swift:StartSmallForAPITests.swift
import XCTest
@testable import StartSmallForAPI


class StartSmallForAPITests: XCTestCase {
    func testExample() {
        // ここに動作を確認したいコードを書く。
    }
}
```

実は、`StartSmallForAPITests` というグループの中には、既に `StartSmallForAPITests.swift` という XCTestCase が入っているはずです。そこで、これを改造していくこととしましょう。



### コードを書くときの約束

なお、今回コードにするとき、下の3つの約束を守っています:

<dl>
    <dt>約束1
    <dd>
        <dl>
            <dt>内容<dd><code>WebAPI.swift</code> では force unwrap してはダメ。</dd>
            <dt>理由
            <dd>本番でクラッシュするのを防ぐため。
        </dl>
    </dd>
    <dt>約束2
    <dd>
        <dl>
            <dt>内容
            <dd><code>StartSmallForAPITests.swift</code> は動作確認用なので force unwrap してもいい。</dd>
            <dt>理由
            <dd>バグに気づきやすいため。むしろ、クラッシュしてくれればすぐにおかしいことがわかって便利。
        </dl>
    </dd>
    <dt>約束3
    <dd>
        <dl>
            <dt>内容
            <dd>エラーの情報量は落とさない。
            <dt>理由
            <dd>バグの原因を素早く特定できるようにすることで、デバッグ時間を短縮したいため。なお、記事末にエラーの情報量を落とさない実装方法を解説しています。
        </dl>
    </dd>
</dl>

いずれも、多くのプロジェクトの約束とずれていないはずです。



### リクエストの入力部分をコードにする

では、リクエストの入力部分をコード化してみましょう。先ほど、リクエストの構成要素は、URLとクエリ文字列、HTTPヘッダー、ペイロードと説明しました。これらをまとめたタプルを `Request` とし、`WebAPI.swift` に書きます（タプルでなく struct でも問題はありません）:

```swift:WebAPI.swift
import Foundation


/// API への入力は Request そのもの。
typealias Input = Request


/// Request は以下の要素から構成される:
typealias Request = (
    /// リクエストの向き先の URL。
    url: URL,

    /// クエリ文字列。クエリは URLQueryItem という標準のクラスを使っている。
    queries: [URLQueryItem],

    /// HTTP ヘッダー。ヘッダー名と値の辞書になっている。
    headers: [String: String],

    /// HTTP メソッドとペイロードの組み合わせ。
    /// GET にはペイロードがなく、PUT や POST にはペイロードがあることを
    /// 表現するために、後述する enum を使っている。
    methodAndPayload: HTTPMethodAndPayload
)


/// HTTP メソッドとペイロードの組み合わせ。
enum HTTPMethodAndPayload {
    /// GET メソッドの定義。
    case get

    /// POST メソッドの定義（必要になるまでは省略）。
    // case post(payload: Data?)

    /// メソッドの文字列表現。
    var method: String {
        switch self {
        case .get:
            return "GET"
        }
    }

    /// ペイロード。ペイロードがないメソッドの場合は nil。
    var body: Data? {
        switch self {
        case .get:
            // GET はペイロードを取れないので nil。
            return nil
        }
    }
}
```

このコードの動作確認をするために、`StartSmallForAPITests.swift` に次のようなコードを書きます。対象の API はなんでもいいのですが、とりあえず誰でも使える GitHub Zen API を使うようにしてみましょう:

```swift:StartSmallForAPITests.swift
import XCTest
@testable import StartSmallForAPI


class StartSmallForAPITests: XCTestCase {

    func testRequest() {
        // リクエストを作成する。
        let input: Request = (
            // GitHub の Zen API を指定。
            url: URL(string: "https://api.github.com/zen")!,

            // Zen API はパラメータを取らない。
            queries: [],

            // 特にヘッダーもいらない。
            headers: [:],

            // HTTP メソッドは GET のみ対応している。
            methodAndPayload: .get
        )

        // この内容で API を呼び出す（注: WebAPI.call は後で定義する）。
        WebAPI.call(with: input)
    }

}
```

ここまで書き終わったら、⌘ + U でビルドできることを確認します。おっと、まだ `WebAPI.call` が定義されていないので、ビルドは失敗するはずです。とりあえず、ビルドを通すために次のような仮の実装をしておきましょう。なお、`WebAPI` を enum としたのは名前空間として扱いたいためです（記事末に解説があります）。

```swift:WebAPI.swift
// ...（前に書いた Input は省略）...

enum WebAPI {
    // ビルドを通すために call 関数を用意しておく。
    static func call(with input: Input) {
        // TODO: もう少しインターフェースが固まったら実装する。
    }
}
```

もう一度、⌘ + U でビルドできることを確認します。もし、これでビルドができなければどこかでコードを間違えてるので、読み返して確認してください。



### レスポンスの出力部分をコードにする

次に、レスポンスの出力部分をコードにしてみましょう。レスポンスについても構成要素はわかっているので、それを元にコードを書きます:

```swift:WebAPI.swift
// ...（前に書いた Input は省略）...

enum WebAPI {
    // ...（省略）...
}


/// API の出力にをあらわす enum。
/// API の出力でありえるのは、
enum Output {
    /// レスポンスがある場合か、
    case hasResponse(Response)

    /// 通信エラーでレスポンスがない場合。
    case noResponse(ConnectionError)
}



/// 通信エラー。
enum ConnectionError {
    /// データまたはレスポンスが存在しない場合のエラー。
    case noDataAndResponse(debugInfo: String)
}



/// API のレスポンス。構成要素は、以下の3つ。
typealias Response = (
    /// レスポンスの意味をあらわすステータスコード。
    statusCode: HTTPStatus,

    /// HTTP ヘッダー。
    headers: [String: String],

    /// レスポンスの本文。
    payload: Data
)


/// HTTPステータスコードを読みやすくする型。
enum HTTPStatus {
    /// OK の場合。HTTP ステータスコードでは 200 にあたる。
    case ok

    /// OK ではなかった場合の例。
    /// notFound の HTTP ステータスコードは 404 で、
    /// リクエストで要求された項目が存在しなかったことを意味する。
    case notFound

    /// 他にもステータスコードはあるが、全部定義するのは面倒なので、
    /// 必要ペースで定義できるようにする。
    case unsupported(code: Int)

    /// HTTP ステータスコードから HTTPステータス型を作る関数。
    static func from(code: Int) -> HTTPStatus {
        switch code {
        case 200:
            // 200 は OK の意味。
            return .ok
        case 404:
            // 404 は notFound の意味。
            return .notFound
        default:
            // それ以外はまだ対応しない。
            return .unsupported(code: code)
        }
    }
}
```

レスポンスが定義できたので、動作確認のコードを書きます:


```swift:SmallStartForAPITests.swift
import XCTest
@testable import StartSmallForAPI


class StartSmallForAPITests: XCTestCase {

    func testRequest() {
        // ... （省略） ...
    }


    func testResopnse() {
        // 仮のレスポンスを定義する。
        let response: Response = (
            // ステータスコードは 200 OK なはず。
            statusCode: .ok,

            // 読み取るべきヘッダーは特にない。
            headers: [:],

            // Zen API のレスポンスは、禅なフレーズの文字列。
            payload: "this is a response text".data(using: .utf8)!
        )

        // TODO: このままだとペイロードが Data になってしまっていて使いづらいので、
        // よりわかりやすいレスポンスのオブジェクトへと変換する。
    }

}
```

ここまで書き終わったら、⌘ + U でビルドできることを確認します。もしビルドできなかったら、写経をミスってるのでコードを見直してみてください。

さて、このままではレスポンスのペイロードが `Data` になっていて使いづらくなっています。そこで、レスポンスに対応するわかりやすいオブジェクトへと変換しましょう。



### レスポンスをわかりやすいオブジェクトへと変換する

ここからは GitHub API 固有の処理を書いていくので、`WebAPI.swift` とは別のファイルに書いていきましょう。そのために、`StartSmallForAPI` グループの下に `GitHubAPI.swift` というファイルを作成してください。このファイルのビルドターゲットは `StartSmallForAPI` にしてください。

さて、GitHub Zen API を例として、わかりやすいオブジェクトへの変換を実装します。このわかりやすいオブジェクトとは、下のようなものです:

```swift:GitHubAPI.swift
/// GitHub Zen API の結果。
struct GitHubZen {
    /// Zen（禅）なフレーズの文字列。
    let text: String
}
```

この定義をみただけで、GitHub Zen API が文字列だけを返す API だとわかります。そのため、レスポンスからこのようなわかりやすいオブジェクトへ変換してあげると、とても見通しがよくなります。つまり、下のような関数を用意してあげると良いということです:

```swift:GitHubAPI.swift
/// GitHub Zen API の結果。
struct GitHubZen {
    let text: String

    /// レスポンスからわかりやすいオブジェクトへと変換する関数。
    static func from(response: Response) -> GitHubZen {
        // TODO
    }
}
```

ただし、気をつけないといけないのは、常にわかりやすいオブジェクトへと変換できるというわけではないということです。たとえば、サーバーがエラーのレスポンスを返してきた場合、ペイロードは禅なフレーズではなくエラーを表す JSON 文字列になります。そのため、この from の戻り値の型は、禅なフレーズまたはエラーのどちらかの型をもつはずです。これを今まで通り enum で表現すると次のようになります:

```swift
// レスポンスごとに success と failure を定義していく…。
enum GitHubZenResponse {
    case success(GitHubZen)
    case failure(GitHubZen.TransformError)
}
```

しかし、もし `GitHubZen` 以外の API を足していくことを考えると、API を足すごとに `***Response` が増えていくことになってしまいます。これでは面倒なので `Either` という汎用の enum を作ります:

```swift:GitHubAPI.swift
// ...（前に書いた Input と WebAPI と Output は省略）...

/// 型 A か型 B のどちらかのオブジェクトを表す型。
/// たとえば、Either<String, Int> は文字列か整数のどちらかを意味する。
/// なお、慣例的にどちらの型かを左右で表現することが多い。
enum Either<Left, Right> {
    /// Eigher<A, B> の A の方の型。
    case left(Left)

    /// Eigher<A, B> の B の方の型。
    case right(Right)


    /// もし、左側の型ならその値を、右側の型なら nil を返す。
    var left: Left? {
        switch self {
        case let .left(x):
            return x

        case .right:
            return nil
        }
    }

    /// もし、右側の型ならその値を、左側の型なら nil を返す。
    var right: Right? {
        switch self {
        case .left:
            return nil

        case let .right(x):
            return x
        }
    }
}
```

この `Either` を使うと、`GitHubZenResponse` と同じ意味を次のように表現できます:

```
GitHubZenResponse.success(zen)   -> Either.left(zen)

GitHubZenResponse.failure(error) -> Either.right(error)
```

では、`Either` を使って `GitHubZen` の `from` 関数を次のように書いてみましょう:

```swift:GitHubAPI.swift
enum Either<Left, Right> {
    // ...（省略）...
}


/// GitHub Zen API の結果。
struct GitHubZen {
    let text: String

    /// レスポンスからわかりやすいオブジェクトへと変換する関数。
    ///
    /// ただし、サーバーがエラーを返してきた場合などは変換できないので、
    /// その場合はエラーを返す。つまり、戻り値はエラーがわかりやすいオブジェクトになる。
    /// このような、「どちらか」を意味する Either という型で表現する。
    /// GitHubZen が左でなく右なのは、正しいと Right をかけた慣例。
    static func from(response: Response) -> Either<TransformError, GitHubZen> {
        // TODO
    }


    /// GitHub Zen API の変換で起きうるエラーの一覧。
    enum TransformError {
        /// HTTP ステータスコードが OK 以外だった場合のエラー。
        case unexpectedStatusCode(debugInfo: String)

        /// ペイロードが壊れた文字列だった場合のエラー。
        case malformedData(debugInfo: String)
    }
}
```

この関数の実装へ移る前に、使い勝手をみてみましょう。この `GitHubZen.from` の使い勝手を検証するために、これまでと同じような動作確認のコードをかいてみます。この使い勝手を確かめるコードは次のようになるはずです:

```swift:SmallStartForAPITests.swift
import XCTest
@testable import StartSmallForAPI


class StartSmallForAPITests: XCTestCase {

    func testRequest() {
        // ... （省略） ...
    }


    func testResopnse()
        // 仮のレスポンスを定義する。
        let response: Response = (
            statusCode: .ok,
            headers: [:],
            payload: "this is a response text".data(using: .utf8)!
        )

        // GitHubZen.from 関数を呼び出してみる。
        let errorOrZen = GitHubZen.from(response: response)

        // 結果は、エラーか禅なフレーズのどちらか。
        switch errorOrZen {
        case let .left(error):
            // 上の仮のレスポンスであれば、エラーにはならないはず。
            // そういう場合は、XCTFail という関数でこちらにきてしまったことをわかるようにする。
            XCTFail("\(error)")

        case let .right(zen):
            // 上の仮のレスポンスの禅なフレーズをちゃんと読み取れたかどうか検証したい。
            // そういう場合は、XCTAssertEqual という関数で内容があっているかどうかを検証する。
            XCTAssertEqual(zen.text, "this is a response text")
        }
    }

}
```

このコードをみた通り、コード量はそこまで多くなく、意味も明快です。つまり、`GitHubZen.from` 関数の使い勝手はよいといえるでしょう。
このように、こまめに使い勝手を確認していくことは、使いやすい設計をしていく上でとても重要です。

さて、使い勝手がよいとわかったので、中身の実装にとりかかりましょう:

```swift:GitHubAPI.swift
// ...（前に書いた と Either は省略）...


struct GitHubZen {
    let text: String


    static func from(response: Response) -> Either<TransformError, GitHubZen> {
        switch response.statusCode {
        case .ok:
            // HTTP ステータスが OK だったら、ペイロードの中身を確認する。
            // Zen API は UTF-8 で符号化された文字列を返すはずので Data を UTF-8 として
            // 解釈してみる。
            guard let string = String(data: response.payload, encoding: .utf8) else {
                // もし、Data が UTF-8 の文字列でなければ、誤って画像などを受信してしまったのかもしれない。。
                // この場合は、malformedData エラーを返す（エラーの型は左なので .left を使う）。
                return .left(.malformedData(debugInfo: "not UTF-8 string"))
            }

            // もし、内容を UTF-8 で符号化された文字列として読み取れたなら、
            // その文字列から GitHubZen を作って返す（エラーではない型は右なので .right を使う）
            return .right(GitHubZen(text: string))

        default:
            // もし、HTTP ステータスコードが OK 以外であれば、エラーとして扱う。
            // たとえば、GitHub API を呼び出しすぎたときは 200 OK ではなく 403 Forbidden が
            // 返るのでこちらにくる。
            return .left(.unexpectedStatusCode(
                // エラーの内容がわかりやすいようにステータスコードを入れて返す。
                debugInfo: "\(response.statusCode)")
            )
        }
    }


    /// GitHub Zen API で起きうるエラーの一覧。
    enum TransformError {
        /// ペイロードが壊れた文字列だった場合のエラー。
        case malformedData(debugInfo: String)

        /// HTTP ステータスコードが OK 以外だった場合のエラー。
        case unexpectedStatusCode(debugInfo: String)
    }
}
```

中身はかなり単純なコードで、UTF-8 で符号化された文字列が渡されたらそれを取り出しているだけです。また、もし UTF-8 で符号化されていない文字がきた場合や、HTTP ステータスコードが `200 OK` でなければエラーを返します。

ここまで書き終わったら、⌘ + U でビルドできることを確認します。もしビルドできなかったら、写経をミスってるのでコードを見直してみてください。



これまでで、リクエストの入力部分と、レスポンスの出力部分を実装できました。ここからは、リクエストからレスポンスへ変換する非同期な部分をコードにしてみましょう。



### 非同期な部分をコードにする

非同期なコードの動作確認は少々複雑です。この場合、`XCTestExpectation` という動作確認完了までの待ち合わせをするオブジェクトを作成しなければなりません。この `XCTestExpectation` を使ったコードは次のようになります:

```swift
import XCTest

class ExampleAsyncTests: XCTestCase {
    func testAsync() {
        // XCTestExpectation オブジェクトを作成する。
        // これを作成した時点で、動作確認のモードが非同期モードになる。
        let expectation = self.expectation(description: "非同期に待つ")

        // 1秒経過したら、expectation.fulfill を実行する。
        Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
            expectation.fulfill()
        }

        // 動作確認が完了するまで、10 秒待つ。
        // 10 秒たっても expectation.fulfill が呼ばれなければ、
        // 何かがおかしいので、わかりやすいエラーがでるようにしておく。
        self.waitForExpectations(timeout: 10)

        // ここは expectation.fulfill が呼ばれるかタイムアウトするまで
        // 実行されない。
    }
}
```

この `XCTestExpectation` が作成されると、`XCTestCase` は非同期モードになります。非同期モードになった `XCTestCase` は `XCTestExpectation.fulfill` が呼ばれるまで待機するようになります。この待機を実際にする関数が、`XCTestCase.waitForExpectations` です。この `XCTestCase.waitForExpectations` 以降のコードは、`XCTestExpectation.fulfill` が呼ばれるかタイムアウトするまで実行されません。

さて、`XCTestExpectation` を使った動作確認のコードは次のようになります:

```swift:SmallStartForAPITests.swift
import XCTest
@testable import StartSmallForAPI


class StartSmallForAPITests: XCTestCase {

    func testRequest() {
        // ... （省略） ...
    }


    func testResopnse() {
        // ... （省略） ...
    }


    func testRequestAndResopnse() {
        let expectation = self.expectation(description: "API を待つ")

        // これまでと同じようにリクエストを作成する。
        let input: Input = (
            url: URL(string: "https://api.github.com/zen")!,
            queries: [],
            headers: [:],
            methodAndPayload: .get
        )

        // このリクエストで API を呼び出す。
        // WebAPI.call の結果は、非同期なのでコールバックになるはず。
        // また、コールバックの引数は Output 型（レスポンスありか通信エラー）になるはず。
        // （注: WebAPI.call がコールバックを受け取れるようにするようにあとで修正する）
        WebAPI.call(with: input) { output in
            // サーバーからのレスポンスが帰ってきた。

            // Zen API のレスポンスの内容を確認する。
            switch output {
            case let .noResponse(connectionError):
                // もし、通信エラーが起きていたらわかるようにしておく。
                XCTFail("\(connectionError)")
                

            case let .hasResponse(response):
                // レスポンスがちゃんときていた場合は、わかりやすいオブジェクトへと
                // 変換してみる。
                let errorOrZen = GitHubZen.from(response: response)

                // 正しく呼び出せていれば GitHubZen が帰ってくるはずなので、
                // 右側が nil ではなく値が入っていることを確認する。
                XCTAssertNotNil(errorOrZen.right)
            }

            expectation.fulfill()
        }

        self.waitForExpectations(timeout: 10)
    }
}
```

ただ、まだリクエストを実際に送信する部分は実装していません。そのため、`WebAPI.call` のインターフェースは「非同期ならコールバックになるだろう」という予想に基づいて実装しています。なお、このままではビルドが通らないので、`WebAPI.call` がコールバックを受け取れるようにします。

```swift:WebAPI.swift
// ...（前に書いた Input は省略）...

enum WebAPI {
    // コールバックつきの call 関数を用意する。
    // コールバック関数に与えられる引数は、Output 型（レスポンスか通信エラーのどちらか）。
    static func call(with input: Input, _ block: @escaping (Output) -> Void) {

        // 実際にサーバーと通信するコードはまだはっきりしていないので、
        // Timer を使って非同期なコード実行だけを再現する。
        Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in

            // 仮のレスポンスをでっちあげる。
            let response: Response = (
                statusCode: .ok,
                headers: [:],
                payload: "this is a response text".data(using: .utf8)! // 👈 最終的にこのコードは消えるので force unwrap しています
            )

            // 仮のレスポンスでコールバックを呼び出す。
            block(response)
        }
    }

    
    static func call(with input: Input) {
        self.call(with: input) { _ in
            // NOTE: コールバックでは何もしない
        }
    }
}

// ...（前に書いた Output と Either は省略）...
```

ただ、まだ実際にサーバーと通信するコードははっきりしていません。そのため、代わりに `Timer.scheduledTimer` 関数と仮のレスポンスでサーバーからのレスポンスがきた状態を再現しています。この状態で、ビルドが通ることを ⌘ + U で確認しましょう。

もしビルドが成功したら、残すは実際にサーバーと通信するコードのみです。まずは、サードパーティ製のライブラリに頼らず、標準ライブラリだけを使ってこの通信コードを実装してみましょう。



標準ライブラリから出発する
--------------------------

これまでは、リクエストとレスポンスの構成要素をもとに、API クライアントの入力部分と出力部分を実装してきました。ここからは、実際の通信部分を標準ライブラリを使って実装してきます。



### `URLSession` クラスを使う

Swift で通信を担当する標準ライブラリのクラスは `URLSession` です。この `URLSession` を使って通信するには、次のようなコードを書く必要があります:

```swift
// URLSession が受け付けられるリクエストの型。
// URL とクエリ文字列、HTTP ヘッダや HTTP メソッド、
// リクエストの本文などから構成される。
let urlRequest: URLRequest

// 与えられた URLRequest を使って、サーバーとの通信を準備しておく。
let task = URLSession.shared.dataTask(with: urlRequest) { (data, urlResponse, error) in 
    // data には、レスポンスのペイロードが入っている。
    dump(data)

    // urlResponse には HTTP ヘッダーと HTTP ステータスコードが入っている。
    dump(urlResponse)

    // 通信エラーが起きた時はエラーが入っている。それ以外の時は nil。
    dump(error)
}

// サーバーとの通信を始める。
task.resume()
```

`URLSession` は `URLRequest` というオブジェクトを受け取り、`resume()` 関数で通信を開始します。このとき、レスポンスを受け取るか通信エラーが発生すると、コールバックが呼ばれます。このコールバックには、レスポンスのデータとHTTPヘッダー、ステータスコード、通信エラーが与えられます。少し複雑に見えますが、取り扱っているのはどれも Web API の構成要素のみです。そのため、先ほどまで書いた `WebAPI.swift` から `URLSession` を呼び出すのは難しくありません。

それでは、リクエストの作成部分を書いてみましょう。



### リクエストを URLRequest へ変換する

`URLSession` への入力は `URLRequest` クラスが担当しています。私たちが前に書いた `Input` 型から `URLRequest` 型を作成する関数を書いてみましょう:

```swift
// ...（Input は省略）...

enum WebAPI {
    static func call(with input: Input) {
        // ...（省略）...
    }


    static func call(with input: Input, _ block: @escaping (Output) -> Void) {
        // ...（省略）...
    }


    // Input から URLRequest を作成する関数。
    static private func createURLRequest(by input: Input) -> URLRequest {
        // URL から URLRequeast を作成する。
        var request = URLRequest(url: input.url)

        // HTTP メソッドを設定する。
        request.httpMethod = input.methodAndPayload.method

        // リクエストの本文を設定する。
        request.httpBody = input.methodAndPayload.body

        // HTTP ヘッダを設定する。
        request.allHTTPHeaderFields = input.headers

        return request
    }
}

// ...（Output と Either は省略）...
```

特に説明が必要ないほど簡単なコードになっています。次に、`URLSession.dataTask` のコールバックに与えられた引数から Output 型を作る関数を書いてみましょう。



### `URLResponse` などからレスポンスを作成する

では `URLSession.dataTask` のコールバックの 3 つの引数をもう一度整理しましょう:

1. レスポンス本文のデータ。通信エラーなどでなければ nil。
2. HTTP ヘッダなどをもつ `URLResponse` オブジェクト。通信エラーなどでなければ nil。
3. 通信エラーがあればそのエラーオブジェクト。なければ nil。

これらを Output 型に変換するコードは次のようになります:

```swift
// ...（Input は省略）...

enum WebAPI {
    static func call(with input: Input) {
        // ...（省略）...
    }


    static func call(with input: Input, _ block: @escaping (Output) -> Void) {
        // ...（省略）...
    }


    static private func createURLRequest(by input: Input) -> URLRequest {
        // ...（省略）...
    }


    // URLSession.dataTask のコールバック引数から Output オブジェクトを作成する関数。
    static private func createOutput(
        data: Data?,
        urlResponse: HTTPURLResponse?,
        error: Error?
    ) -> Output {
        // データと URLResponse がなければ通信エラー。
        guard let data = data, let response = urlResponse else {
            // エラーの内容を debugInfo に格納して通信エラーを返す。
            return .noResponse(.noDataOrNoResponse(debugInfo: error.debugDescription))
        }

        // HTTP ヘッダーを URLResponse から取り出して Output 型の
        // HTTP ヘッダーの型 [String: String] と一致するように変換する。
        var headers: [String: String] = [:]
        for (key, value) in headers.enumerated() {
            headers[key.description] = String(describing: value)
        }

        // Output オブジェクトを作成して返す。
        return .hasResponse((
            // HTTP ステータスコードから HTTPStatus を作成する。
            statusCode: .from(code: response.statusCode),

            // 変換後の HTTP ヘッダーを返す。
            headers: headers,

            // レスポンスの本文をそのまま返す。
            payload: data
        ))
    }
}

// ...（Output と Either は省略）...
```

コードを見ての通り、HTTP ヘッダーの変換が少し複雑ですが、それ以外は単純にプロパティへ格納するだけになっています。

さて、これで `URLSession` への入力部分と出力部分を繋げられるようになりました。最後に `URLSession.dataTask` を `WebAPI` へ組み込んでみましょう。



### 通信部分を実装する

先ほど実装した `createURLRequest` と `createOutput` を使えば、`WebAPI.call` の実装は簡単です:

```swift
// ...（Input は省略）...

enum WebAPI {
    static func call(with input: Input) {
        // ...（省略）...
    }


    static func call(with input: Input, _ block: @escaping (Output) -> Void) {
        // URLSession へ渡す URLRequest を作成する。
        let urlRequest = self.createURLRequest(by: input)

        // レスポンス受信後のコールバックを登録する。
        let task = URLSession.shared.dataTask(with: urlRequest) { (data, urlResponse, error) in

            // 受信したレスポンスまたは通信エラーを Output オブジェクトへ変換する。
            let output = self.createOutput(
                data: data,
                urlResponse: urlResponse as? HTTPURLResponse,
                error: error
            )

            // コールバックに Output オブジェクトを渡す。
            block(output)
        }
        task.resume()
    }


    static private func createURLRequest(by input: Input) -> URLRequest {
        // ...（省略）...
    }


    static private func createOutput(data: Data?, urlResponse: HTTPURLResponse?, error: Error?) -> Output {
        // ...（省略）...
    }
}

// ...（Output は省略）...
```

この状態でビルドが通ることを ⌘ + U で確認しましょう。特に問題なければ、実際のサーバーとの通信がうまくいくとわかりました！

さて、これまでの実装で、`GitHubZen` オブジェクトを取得できるようになりました。この処理の流れを図にすると、次のようになります:

```
.....................|.......................
: GitHub Zen API :   |                      :
:`````````````````   |                      :
: ...................V..................... :
: : WebAPI :     +-------+                : :
: :`````````     | Input |                : :
: :              +-------*                : :
: : .................|................... : :
: : : URLSession :   |                  : : :
: : :`````````````   V                  : : :
: : :          +------------+           : : :
: : :          | URLRequest |           : : :
: : :          +------------+           : : :
: : :                |                  : : :
: : :                V                  : : :
: : :     +---------------------+       : : :
: : :     | URLSession.dataTask |       : : :
: : :     +---------------------+       : : :
: : :                |                  : : :
: : :                V                  : : :
: : : +-------------------------------+ : : :
: : : | (Data?, URLResponse?, Error?) | : : :
: : : +-------------------------------+ : : :
: : :................|..................: : :
: :                  V                    : :
: :              +--------+               : :
: :              | Output |               : :
: :              +--------+               : :
: :..................|....................: :
:                    V                      :
:  +------------------------------------+   :
:  | Either<TransformError, GitHubZen>  |   :
:  +------------------------------------+   :
:....................|......................:
                     V
```

この図をよく見ると、綺麗に抽象層が分かれていることがわかります。つまり過不足なく抽象化して設計できたということです。このようにうまく抽象化できた設計は、それぞれの層を交換できるようになるというメリットがあります。例えば、`WebAPI` より下の層は、他の Web API でも使いまわすことができます。したがって、別の API に対応したい場合でも、今回の `GitHubZen` のように Output を引数にとって `Either<Foo.TransformError, Foo>` を返す関数を実装するだけで対応できます。もちろん、レスポンスが JSON 形式の文字列の場合でも同様に対処できます。要するに、好きなようにカスタマイズできる柔軟な設計を手に入れられたということなのです。

しかし、使いやすさについてはどうでしょうか。WebAPI については使いやすいということはわかっていましたが、`GitHubZen` が使いやすいかどうかはまだわかっていません。そこで、動作確認のコードを書くことで、使いやすさを再点検してみましょう。



使いやすさを再点検する
----------------------

### API クライアントを使ってみる

今回使いやすさを点検するのは `GitHubZen` なので、これまで動作確認をしてきた `StartSmallForAPITests.swift` とは別のファイルに書いていきましょう。そこで、`StartSmallForAPITests` グループの下に `GitHubAPITests.swift` というファイルを作成してください。また、このファイルのビルドターゲットは `StartSmallForAPITests` にしてください。なお、ファイルの内容は次のボイラープレートのものにしておきましょう:

```swift:GitHubAPITests.swift
import XCTest
@testable import StartSmallForAPI


class GitHubAPITests: XCTestCase {
    func testZenFetch() {
        // TODO: 動作確認のコードをかく
    }
}
```

次に、GitHubZen を呼び出すコードを書いてみましょう。これまでみてきた通りのコードです：

```swift:GitHubAPITests.swift
import XCTest
@testable import StartSmallForAPI


class GitHubAPITests: XCTestCase {
    func testZenFetch() {
        // コードは StartSmallForAPITests.testRequestAndResopnse から拝借してきた。

        let expectation = self.expectation(description: "API")

        let input: Input = (
            url: URL(string: "https://api.github.com/zen")!,
            queries: [],
            headers: [:],
            methodAndPayload: .get
        )

        WebAPI.call(with: input) { output in
            switch output {
            case .noResponse:
                XCTFail("No response")

            case let .hasResponse(response):
                let errorOrZen = GitHubZen.from(response: response)
                XCTAssertNotNil(errorOrZen.right)
            }

            expectation.fulfill()
        }

        self.waitForExpectations(timeout: 10)
    }
}
```

しかし、この `GitHubZen` からみると、この Input の入力は余計に感じます。なぜなら、GitHub Zen API には何も入力がないはずなのに、毎度入力を用意しなければならないからです。この煩雑さは、次のように GitHub Zen API を複数回呼ぶコードを書いてみると顕在化します:

```swift:GitHubAPITests.swift
import XCTest
@testable import StartSmallForAPI


class GitHubAPITests: XCTestCase {
    func testZenFetch() {
        // ...(省略)...
    }


    // GitHubZen API を呼び出し、結果が返ってきたらさらにもう一度呼び出す関数
    // (初見で何をやってるかが掴みづらい…！)。
    func testZenFetchTwice() {
        let expectation = self.expectation(description: "API")

        let input: Input = (
            url: URL(string: "https://api.github.com/zen")!,
            queries: [],
            headers: [:],
            methodAndPayload: .get
        )

        WebAPI.call(with: input) { output in
            switch output {
            case .noResponse:
                XCTFail("No response")

            case let .hasResponse(response):
                let nextInput: Input = (
                    url: URL(string: "https://api.github.com/zen")!,
                    queries: [],
                    headers: [:],
                    methodAndPayload: .get
                )

                WebAPI.call(with: nextInput) { nextOutput in
                    switch nextOutput {
                    case .noResponse:
                        XCTFail("No response")

                    case let .hasResponse(response):
                        let errorOrZen = GitHubZen.from(response: response)
                        XCTAssertNotNil(errorOrZen.right)
                    }

                    expectation.fulfill()
                }
            }

            expectation.fulfill()
        }

        self.waitForExpectations(timeout: 10)
    }
}
```

よく内容を読めば難しいことはしていないことがわかりますが、読みづらいコードになっています。つまり、今のままでは、`GitHubZen` が使いやすいとはいえなさそうです。こういうときは、再度インターフェースの想像に戻りましょう。動作確認のコードに本来あるべき姿を想像して書いてみます:

```swift:call
import XCTest
@testable import StartSmallForAPI


class GitHubAPITests: XCTestCase {
    func testZenFetch() {
        let expectation = self.expectation(description: "API")

        // GitHub Zen API には入力パラメータがないので、関数呼び出し時には
        // 引数は指定しなくて済むようにしたい。また、API 呼び出しは非同期なので、
        // コールバックをとるはず（注: GitHubZen.fetch はあとで定義する）。
        GitHubZen.fetch { errorOrZen in
            // エラーかレスポンスがきたらコールバックが実行されて欲しい。
            // できれば、結果はすでに変換済みの GitHubZen オブジェクトを受け取りたい。

            switch errorOrZen {
            case let .left(error):
                // エラーがきたらわかりやすいようにする。
                XCTFail("\(error)")

            case let .right(zen):
                // 結果をきちんと受け取れたことを確認する。
                XCTAssertNotNil(zen)
            }

            expectation.fulfill()
        }

        self.waitForExpectations(timeout: 10)
    }


    // API を二度呼ぶ方もかなり可読性が上がっている。
    func testZenFetchTwice() {
        let expectation = self.expectation(description: "API")

        GitHubZen.fetch { errorOrZen in
            switch errorOrZen {
            case let .left(error):
                XCTFail("\(error)")

            case .right(_):
                GitHubZen.fetch { errorOrZen in
                    switch errorOrZen {
                    case let .left(error):
                        XCTFail("\(error)")

                    case let .right(zen):
                        XCTAssertNotNil(zen)
                        expectation.fulfill()
                    }
                }
            }
        }

        self.waitForExpectations(timeout: 10)
    }
}
```

このような要件を満たす `GitHubZen.fetch` 関数を用意できれば、`GitHubZen` の使い勝手もよくなりそうです。

では、実装にとりかかりましょう。



### API 呼び出し部分を簡略化する

`GitHubZen` に API 経由で禅なメッセージを取得する `fetch` 関数を実装します:

```swift:GitHubAPI.swift
import Foundation


enum Either<Left, Right> {
    // ...(省略)...
}



struct GitHubZen {
    let text: String


    static func from(response: Response) -> Either<TransformError, GitHubZen> {
        // ...(省略)...
    }


    /// GitHub Zen API を使って、禅なフレーズを取得する関数。
    static func fetch(
        // コールバック経由で、接続エラーか変換エラーか GitHubZen のいずれかを受け取れるようにする。
        _ block: @escaping (Either<Either<ConnenctionError, TransformError>, GitHubZen>) -> Void

        // コールバックの引数の型が少しわかりづらいが、次の3パターンになる。
        //
        // - 接続エラーの場合     → .left(.left(ConnenctionEither))
        // - 変換エラーの場合     → .left(.right(TransformError))
        // - 正常に取得できた場合 → .right(GitHubZen)
    ) {
        // URL が生成できない場合は不正な URL エラーを返す
        guard let url = URL(string: "https://api.github.com/zen") else {
            block(.left(.left(.malformedURL(debugInfo: String))))
            return
        }

        // GitHub Zen API は何も入力パラメータがないので入力は固定値になる。
        let input: Input = (
            url: url,
            queries: [],
            headers: [:],
            methodAndPayload: .get
        )

        // GitHub Zen API を呼び出す。
        WebAPI.call(with: input) { output in
            switch output {
            case let .noResponse(connectionError):
                // 接続エラーの場合は、接続エラーを渡す。
                block(.left(.left(connectionError)))

            case let .hasResponse(response):
                // レスポンスがわかりやすくなるように GitHubZen へと変換する。
                let errorOrZen = GitHubZen.from(response: response)

                switch errorOrZen {
                case let .left(error):
                    // 変換エラーの場合は、変換エラーを渡す。
                    block(.left(.right(error)))

                case let .right(zen):
                    // 正常に変換できた場合は、GitHubZen オブジェクトを渡す。
                    block(.right(zen))
                }
            }
        }
    }


    enum TransformError {
        // ...(省略)...
    }
}
```

また、接続エラーの種類に不正な URL であることを意味する `malformedURL` を追加しましょう。

```swift:WebAPI.swift
// ...（Input は省略）...

enum ConnectionError {
    case noDataOrNoResponse(debugInfo: String)

    /// 不正な URL の場合のエラー。
    case malformedURL(debugInfo: String)
}

// ...（Output は省略）...
```

実装できたら、⌘ + U で動作を確認しましょう。

さて、これで `GitHubZen` を使いやすくする対応が完了しました。これまでの作業を振り返ると、設計の見直しによって私たちは使いやすい API クライアントを手に入れられたことがわかります。さらに、これまでに `WebAPI` を使いやすい設計にしておいたおかげで、実装したコードもシンプルになっています。

しかし、実際に私たちが対応しなければならない API の数は 1 つでないはずです。そこで、対応する API を増やした場合でも、これまでの設計が耐えられるかどうかについても試してみましょう。



### 対応する API を増やす

今度は GitHub User API に対応してみます。この GitHub User API は、ユーザーのログイン名を指定すると、そのユーザーの詳細を返す API です。このユーザーの詳細は、次のようなオブジェクトになります:

```swift:GitHubAPI.swift
struct GitHubUser {
    /// GitHub の ID 番号。
    let id: Int

    /// GitHub のログイン名。
    let login: String

    // （プロパティは他にもあるが今回は省略して実装する）
}
```

さて、これまでと同じように、`Output` から `GitHubUser` への変換が必要と予想されます。そこで、インターフェースを想像するために変換部分の動作確認コードを書きます:

```swift:GitHubAPITests.swift
import XCTest
@testable import StartSmallForAPI


class GitHubAPITests: XCTestCase {
    func testZenFetch() {
        // ...(省略)...
    }


    func testZenFetchTwice() {
        // ...(省略)...
    }


    // レスポンスを GitHubUser へ変換できることを確かめる動作確認コード。
    func testUser() throws {
        // レスポンスを定義。
        let response: Response = (
            // 200 OK が必要。
            statusCode: .ok,

            // 必要なヘッダーは特にない。
            headers: [:],

            // API レスポンスを GitHubUser へ変換できるか試すだけなので、
            // 適当な ID とログイン名を指定。
            payload: try JSONSerialization.data(withJSONObject: [
                "id": 1,
                "login": "octocat"
            ])
        )

        switch GitHubUser.from(response: response) {
        case let .left(error):
            // ここにきてしまったらわかりやすいようにする。
            XCTFail("\(error)")

        case let .right(user):
            // ID とログイン名が正しく変換できたことを確認する。
            XCTAssertEqual(user.id, 1)
            XCTAssertEqual(user.login, "octocat")
        }
    }
}
```

変換部分の動作確認コードは、ほぼ `GitHubZen` と同じインターフェースになりました。そのため、`GitHubZen` と同じように使いやすいコードになっていると期待できます。次に、変換部分のコードを実装してみましょう:

```swift:GitHubAPI.swift
// ...(GitHubZen は省略)...

// JSON からこのオブジェクトを作成したいため、Codable を実装させる
// （Codable は Swift4 から追加されたシリアライズ/デシリアライズ用のプロトコル）。
struct GitHubUser: Codable {
    let id: Int
    let login: String


    /// レスポンスから GitHubUser オブジェクトへ変換する関数。
    static func from(response: Response) -> Either<TransformError, GitHubUser> {
        switch response.statusCode {
        // HTTP ステータスが OK だったら、ペイロードの中身を確認する。
        case .ok:
            do {
                // User API は JSON 形式の文字列を返すはずので Data を JSON として
                // 解釈してみる。
                let jsonDecoder = JSONDecoder()
                let user = try jsonDecoder.decode(GitHubUser.self, from: response.payload)

                // もし、内容を JSON として解釈できたなら、
                // その文字列から GitHubUser を作って返す（エラーではない型は右なので .right を使う）
                return .right(user)
            }
            catch {
                // もし、Data が JSON 文字列でなければ、何か間違ったデータを受信してしまったのかもしれない。
                // この場合は、malformedData エラーを返す（エラーの型は左なので .left を使う）。
                return .left(.malformedData(debugInfo: "\(error)"))
            }

        // もし、HTTP ステータスコードが OK 以外であれば、エラーとして扱う。
        // たとえば、GitHub API を呼び出しすぎたときは 200 OK ではなく 403 Forbidden が
        // 返るのでこちらにくる。
        default:
            // エラーの内容がわかりやすいようにステータスコードを入れて返す。
            return .left(.unexpectedStatusCode(debugInfo: "\(response.statusCode)"))
        }
    }


    /// GitHub User API の変換で起きうるエラーの一覧。
    enum TransformError {
        /// ペイロードが壊れた JSON だった場合のエラー。
        case malformedData(debugInfo: String)

        /// HTTP ステータスコードが OK 以外だった場合のエラー。
        case unexpectedStatusCode(debugInfo: String)
    }
}
```

ここまで実装できたら ⌘ + U で動作を確認してみましょう。

うまく実装できたら、最後に `GitHubUser` についてもサーバー経由で `GitHubUser` を取得する処理を `fetch` 関数へとまとめてしまいます:

```swift:GitHubAPITests.swift
import XCTest
@testable import StartSmallForAPI


class GitHubAPITests: XCTestCase {
    func testZenFetch() {
        // ...(省略)...
    }


    func testZenFetchTwice() {
        // ...(省略)...
    }


    func testUser() throws {
        // ...(省略)...
    }


    // サーバー経由で GitHubUser を取得する処理の動作確認コード。
    func testUserFetch() {
        let expectation = self.expectation(description: "API")

        // ログイン名から GitHubUser を取得する関数を呼び出す。
        // 非同期で結果を取得するのでコールバックになると推測。
        GitHubUser.fetch(byLogin: "Kuniwak") { errorOrUser in

            // 結果は、通信エラーや変換エラーか取得できたユーザーのいずれかになると推測。
            switch errorOrUser {
            case let .left(error):
                // エラーになったらわかりやすいようにしておく。
                XCTFail("\(error)")

            case let .right(user):
                // 取得できた実際の ID をログイン名を確認する。
                XCTAssertEqual(user.id, 1124024)
                XCTAssertEqual(user.login, "Kuniwak")
            }

            expectation.fulfill()
        }

        self.waitForExpectations(timeout: 10)
    }
}
```

こちらもほぼ `GitHubZen.fetch` と同じ使い勝手にできそうです。

では、使い勝手を確認できたので、中身の実装へと移りましょう:

```swift:GitHubAPI.swift
// ...(GitHubZen は省略)...

struct GitHubUser: Codable {
    let id: Int
    let login: String


    static func from(response: Response) -> Either<TransformError, GitHubUser> {
        // ...(省略)...
    }


    /// ログイン名から GitHubUser を取得する関数。
    static func fetch(
        // 取得したいユーザーのログイン名。
        by login: String,

        // コールバック経由で、接続エラーか変換エラーか GitHubUser のいずれかを受け取れるようにする。
        _ block: @escaping (Either<Either<ConnectionError, TransformError>, GitHubUser>) -> Void

        // コールバックの引数の型が少しわかりづらいが、次の3パターンのいずれかになる。
        //
        // - 接続エラーの場合     → .left(.left(ConnenctionEither))
        // - 変換エラーの場合     → .left(.right(TransformError))
        // - 正常に取得できた場合 → .right(GitHubUser)
    ) {
        // GitHub User API の URL の形式は https://api.github.com/users/<ログイン名> なので、
        // URL の末尾にログイン名を付加する。
        let urlString = "https://api.github.com/users"
        guard let url = URL(string: urlString)?.appendingPathComponent(login) else {
            // もし、不正な URL になったらコールバックにエラーを渡す。
            block(.left(.left(.malformedURL(debugInfo: "\(urlString)/\(login)"))))
            return
        }

        let input: Input = (
            url: url,
            queries: [],
            headers: [:],
            methodAndPayload: .get
        )

        // 指定したパラメーターで GitHub User API を呼び出す。
        WebAPI.call(with: input) { output in
            switch output {
            case let .noResponse(connectionError):
                // もし、接続エラーになったらコールバックにエラーを渡す。
                block(.left(.left(connectionError)))

            case let .hasResponse(response):
                // レスポンスを GitHubUser へと変換する。
                let errorOrUser = GitHubUser.from(response: response)

                switch errorOrUser {
                case let .left(transformError):
                    // もし、変換エラーになったらコールバックにエラーを渡す。
                    block(.left(.right(transformError)))

                case let .right(user):
                    // 正常に GitHubUser へ変換できたのでコールバックへ渡す。
                    block(.right(user))
                }
            }
        }
    }


    enum TransformError {
        // ...(省略)...
    }
}
```

ここまで実装できたら ⌘ + U で動作を確認してみましょう。もし確認に成功すれば、簡単に API を追加できたことがわかりました！

これまでの設計・再設計の流れを振り返ってみましょう。今回のように動作確認のコードを書きながら漸進的に設計を進めることで、使いやすい設計を得られることが体感できたのではないでしょうか。

さて、ここであなたのこれまでの経験を振り返ってみてください。**もし、これまでの実装で不足がなければ、実は標準ライブラリと動作確認のためのコードを書くことだけで十分綺麗な設計ができるのです**。今、あなたがサードパーティのライブラリを使っているのであれば、あなたの設計に本当に必要なのかどうかを自問してみてください。

次の章ではサードパーティ製のライブラリが必要になった場合の方法をみていきましょう。



サードパーティ製ライブラリを使う
--------------------------------

これまでは標準ライブラリだけを使って、API クライアントを設計してきました。しかし、世の中には数多くのサードパーティ製通信ライブラリが存在します。たとえば、有名なものでは、[Alamofire](https://github.com/Alamofire/Alamofire) や [APIKit](https://github.com/ishkawa/APIKit) などがあります。これらのライブラリは、皆さんもよく耳にするのではないでしょうか。

さて、これらのサードパーティ製のライブラリを使うという判断はどのようにするべきでしょうか。また、サードパーティ製のライブラリを使うと判断したとして、どのようなライブラリを使うべきでしょうか。

では、まずサードパーティ製のライブラリをなぜ使うのか整理してみましょう。



### なぜサードパーティ製のライブラリを使うのか

まず、Web API ライブラリにまつわる重要な事実がひとつあります。それは Web API ライブラリのほとんどが `URLSession` を内部的に使っており、実際のところ `URLSession` のラッパーに過ぎないということです。そのため、現時点のサードパーティ製ライブラリの役割は多くありません。私の知っている限りでは、サードパーティ製ライブラリの役割は次のように限定されています:

<dl>
    <dt>特的の仕様への特化
    <dd>RESTful API や JSON RPC への特化など。
    <dt>入出力形式の拡張
    <dd>標準ライブラリではまだ対応されていない <code>multipart/form-data</code> や <code>application/x-www-form-urlencoded</code> への対応など。</dd>
    <dt><code>URLSession</code> とは異なるインターフェースの提供</dt>
    <dd>メソッドチェーンによるインターフェースの導入や、コールバック以外の非同期処理インターフェース（Promise や Reactive Extensions）のサポートなど。
</dl>

このうち、「特定の仕様への特化」と「入出力形式の拡張」が目的であれば、ほぼ間違いなくライブラリを使う価値があります。しかし、「`URLSession` とは異なるインターフェースの提供」については注意が必要です。これを説明するには、インターフェースの Easy さと Simple さを説明しなければなりません。次の節では、それらの区別とメリット/デメリットについて説明します。



### Easy なインターフェースと Simple なインターフェース

まず、標準ライブラリのラッパーが提供するインターフェースは、Easy なものと Simple なものの2つに分類できます。この Easy と Simple の間には、利用できる構成要素を隠す/隠さないという違いがあります。

![](https://raw.githubusercontent.com/Kuniwak/StartSmallForAPI/master/Documentation/Images/easy-or-simple-1.png)

インターフェースを Easy にするライブラリは、構成要素理解を必要とせず使えるようにするため、多くの構成要素を隠しています。例えば、あまり使われない機能である HTTP ヘッダーの入力/出力インターフェースは隠してもいいかもしれません。また、リクエストのパラメーターの形式がクエリ文字列でレスポンスのパラメータの形式が JSON 文字列のみならば、入力形式の指定部分も隠せます。そうすることで見た目のコード量は減り、指示された通りにパーツを当てはめていけば動作してくれるため、レールに乗ったかのような使い心地を味わえます。

しかし、Easy にされたインターフェースには深刻な欠点もあります。構成要素が隠されるのですから、実現できない入力や出力がでてくるのです。つまり、**レールから外れてしまうと途端に難しくなるのが Easy にされたインターフェースの欠点です**。

そして、もう一方のインターフェースを Simple にするライブラリは、構成要素が多くても多いまま提供します。ただし、よくある共通の処理があるならば、それらを単純化したインターフェースとして提供します。たとえば、 `URLSession` は構成要素が多いため、Easy なインターフェースとはいえません。しかし、インターフェースはいたって Simple であり、構成要素をうまく利用できれば実現できない入出力はありません。**このような Simple なライブラリの強みは、構成要素をフルに使える表現力です**。なお、Simple なライブラリの欠点は、構成要素を理解していないと使い方も理解できないことです。しかし、構成要素を理解してしまえば、Simple なものほど心強いものはありません。そして、これこそが、今回の記事で Web API クライアントの構成要素の把握を最初に持ってきた理由なのです。

![](https://raw.githubusercontent.com/Kuniwak/StartSmallForAPI/master/Documentation/Images/easy-or-simple-2.png)

そこで、もしあなたが `URLSession` とは異なるインターフェースを提供するライブラリを使う際には、インターフェースが Easy と Simple のどちらなのか注意深く観察してみてください。もし、インターフェースが Easy だとすれば、将来的に対応できない入出力がでてくる可能性があります。したがって、そのようなライブラリの利用は避けたほうがよいでしょう。

さて、この節では Easy なインターフェースのリスクについて説明しました。しかし、インターフェースが Simple だからといって、すぐに使うという判断を下すのは早計です。実際にはインターフェースの Easy さや Simple さに関わらないリスクも存在するからです。次の節ではそれらについてみていきましょう。



### サードパーティ製ライブラリを使うメリットとリスク

サードパーティ製ライブラリのリスクは、次の 3 つに分けられます:

1. サードパーティ製ライブラリは自分で直せないかもしれない
2. 明日にはよりよいライブラリが使えるかもしれない
3. 明日にはこのライブラリは使えなくなるかもしれない

最初のリスクは、ライブラリのコードは他人のコードであるという根源的な悩みです。もし、ライブラリにバグがあったとしても、直すことを拒否されるかもしれません。ライブラリによっては、修正自体を許可されていない可能性もあります。

2つめと3つめのリスクは、どちらも Swift の速い変化に関係するものです。たとえば、Swift4 で導入された `Codable` によって、JSON から特定の struct や class へとマッピングするライブラリはその輝きを失いました。このように、標準ライブラリ自体の進化によって、特定のライブラリへの依存が負債となることがあります。さらに、Swift では API の廃止も頻繁におこなわれています。もし、あなたの使っているライブラリが廃止された API に依存していたなら、早急にこの問題を解消しなければなりません。

このように、ライブラリを使うことにはリスクもあります。したがって、サードパーティ製ライブラリのメリットとリスクを天秤にかけ、どちらかを選ぶ判断をしなければなりません。ここに参考例として、いくつかの私の判断を紹介しましょう:

<dl>
    <dt>メソッドチェーンによるインターフェースの導入
    <dd>
        <dl>
            <dt>メリット
            <dd>メソッドチェーンによる Swifty で Easy な実装が可能になる。しかし、メソッドチェーンや Easy なインターフェースには欠点も多く、メリットは少なめ。
            <dt>リスク
            <dd>Swift やライブラリのバージョンアップによって、コードが壊れるリスクは高い。
            <dt>最終的な判断
            <dd>導入しないことにした。リスクに比べてメリットが少なすぎるため。
        </dl>
    </dd>
    <dt>コールバックとは別の非同期インターフェースの導入
    <dd>
        <dl>
            <dt>メリット
            <dd>非同期なインターフェースへの変換を自分で書かなくてすむ。しかし、コード量はそこまで多くないため、メリットは少なめ。
            <dt>リスク
            <dd>Swift や非同期インターフェースライブラリのバージョンアップによって、コードが壊れるリスクは高い。
            <dt>最終的な判断
            <dd>ライブラリを使わず、自分で実装することにした。ライブラリの制約に囚われずに、好きなタイミングで Swift や非同期インターフェースのバージョンを選べることを重視。
        </dl>
    </dd>
</dl>




終わりに
--------

さて、これでこの長い記事も終わりになります。いかがだったでしょうか。最後に、これまでの内容を簡単にまとめましょう:

- ある設計が使いやすいかどうかは、動作確認のコードを書けばわかる
- 動作確認のコードを都度書いていれば、自然と過不足なく抽象化される
- 構成要素を把握して、Easy なライブラリではなく Simple なライブラリに依存しよう



解説: エラーの使い分け
----------------------
Swift では、エラーが起きたことを知らせる方法が4つあります：

<dl>
    <dt><code>throw</code> などの例外</dt>
    <dd>
        <dl>
            <dt>メリット
            <dd>Swift の標準の方法なのでわかりやすい。
            <dt>デメリット
            <dd>例外の型は強制的に <code>Error</code> になってしまい、情報量が落ちる。</dd>
        </dl>
    </dd>
    <dt><code>T?</code> などの optional</dt>
    <dd>
        <dl>
            <dt>メリット
            <dd>Foundation の一部のライブラリはこの形式なので、一貫性を出せる。
            <dt>デメリット
            <dd>例外の内容がわからないため、情報量が少ない。
        </dl>
    </dd>
    <dt><code>(MyError?, T?)</code> などの tuple</dt>
    <dd>
        <dl>
            <dt>メリット
            <dd>エラーの情報量が落ちない。
            <dt>デメリット
            <dd><code>(nil, nil)</code> などの無意味な組み合わせを許容してしまう。</dd>
        </dl>
    </dd>
    <dt><code>Either</code> や <code>Result</code> などの enum</dt>
    <dd>
        <dl>
            <dt>メリット
            <dd>エラーの情報量が落ちない。
            <dt>デメリット
            <dd>特にない。
        </dl>
    </dd>
</dl>

約束3「エラーの情報量を落とさない」を重視すると、約束にあった手法は 3つめの tuple か4つめの enum に絞り込まれます。
そのうち、デメリットの少ない enum を採用しています。



解説: 名前空間としての enum
---------------------------

この記事では名前空間として enum を使っています。struct や class ではなく enum を使う理由は、名前空間のインスタンス化という無意味な操作ができないことです。前者は、`init` を隠さない限り名前空間をインスタンス化できてしまいます:

```swift
struct Namespace {
    static func doSomething() {}
}


// 名前空間をインスタンス化するという意味のないことができてしまう。
let whatIsThis = Namespace()
```

また、`init` を隠すことで名前空間のインスタンス化は防げるようになりますが、都度このコードを書くのは煩雑です:

```swift
struct Namespace {
    // 煩雑な記述が増えてしまう
    private init() {}


    static func doSomething() {}
}
```

そこで、enum を使えば煩雑な記述を必要とせずにインスタンス化できない名前空間が作成できます:

```swift
enum Namespace {
    static func doSomething() {}
}

// 名前空間はインスタンス化できないので、純粋に名前空間として使える。
```

そのため、この記事では名前空間の作成に enum を使っています。



付録: 最終的なコード
--------------------

```swift:WebAPI.swift
import Foundation



typealias Input = Request
typealias Request = (
    url: URL,
    queries: [URLQueryItem],
    headers: [String: String],
    methodAndPayload: HTTPMethodAndPayload
)



enum HTTPMethodAndPayload {
    case get
    // case post(payload: Data?)

    var method: String {
        switch self {
        case .get:
            return "GET"
        }
    }

    var body: Data? {
        switch self {
        case .get:
            return nil
        }
    }
}



enum Output {
    case hasResponse(Response)
    case noResponse(ConnectionError)
}


enum ConnectionError {
    case malformedURL(debugInfo: String)
    case noDataOrNoResponse(debugInfo: String)
}



typealias Response = (
    statusCode: HTTPStatus,
    headers: [String: String],
    payload: Data
)



enum HTTPStatus {
    case ok
    case notFound
    case unsupported(code: Int)


    static func from(code: Int) -> HTTPStatus {
        switch code {
        case 200:
            return .ok
        case 404:
            return .notFound
        default:
            return .unsupported(code: code)
        }
    }
}



enum WebAPI {
    static func call(with input: Input) {
        self.call(with: input) { _ in
            // 何もしない
        }
    }


    static func call(with input: Input, _ block: @escaping (Output) -> Void) {
        let urlRequest = self.createURLRequest(by: input)
        let task = URLSession.shared.dataTask(with: urlRequest) { (data, urlResponse, error) in
            let output = self.createOutput(
                data: data,
                urlResponse: urlResponse as? HTTPURLResponse,
                error: error
            )

            block(output)
        }
        task.resume()
    }


    static private func createURLRequest(by input: Input) -> URLRequest {
        var request = URLRequest(url: input.url)
        request.httpMethod = input.methodAndPayload.method
        request.httpBody = input.methodAndPayload.body
        request.allHTTPHeaderFields = input.headers
        return request
    }


    static private func createOutput(
        data: Data?,
        urlResponse: HTTPURLResponse?,
        error: Error?
    ) -> Output {
        guard let data = data, let response = urlResponse else {
            return .noResponse(.noDataOrNoResponse(debugInfo: error.debugDescription))
        }

        var headers: [String: String] = [:]
        for (key, value) in headers.enumerated() {
            headers[key.description] = String(describing: value)
        }

        return .hasResponse((
            statusCode: .from(code: response.statusCode),
            headers: headers,
            payload: data
        ))
    }
}
```

```swift:GitHubAPI.swift
import Foundation


enum Either<Left, Right> {
    case left(Left)
    case right(Right)

    var left: Left? {
        switch self {
        case let .left(x):
            return x

        case .right:
            return nil
        }
    }

    var right: Right? {
        switch self {
        case .left:
            return nil

        case let .right(x):
            return x
        }
    }
}



struct GitHubZen {
    let text: String


    static func from(response: Response) -> Either<TransformError, GitHubZen> {
        switch response.statusCode {
        case .ok:
            guard let string = String(data: response.payload, encoding: .utf8) else {
                return .left(.malformedData(debugInfo: "not UTF-8 string"))
            }

            return .right(GitHubZen(text: string))

        default:
            return .left(.unexpectedStatusCode(
                debugInfo: "\(response.statusCode)")
            )
        }
    }


    static func fetch(
        _ block: @escaping (Either<Either<ConnectionError, TransformError>, GitHubZen>) -> Void
    ) {
        let urlString = "https://api.github.com/zen"
        guard let url = URL(string: urlString) else {
            block(.left(.left(.malformedURL(debugInfo: urlString))))
            return
        }

        let input: Input = (
            url: url,
            queries: [],
            headers: [:],
            methodAndPayload: .get
        )
        WebAPI.call(with: input) { output in
            switch output {
            case let .noResponse(connectionError):
                block(.left(.left(connectionError)))

            case let .hasResponse(response):
                let errorOrZen = GitHubZen.from(response: response)

                switch errorOrZen {
                case let .left(error):
                    block(.left(.right(error)))

                case let .right(zen):
                    block(.right(zen))
                }
            }
        }
    }


    enum TransformError {
        case malformedData(debugInfo: String)
        case unexpectedStatusCode(debugInfo: String)
    }
}



struct GitHubUser: Codable {
    let id: Int
    let login: String


    static func from(response: Response) -> Either<TransformError, GitHubUser> {
        switch response.statusCode {
            case .ok:
                do {
                    let jsonDecoder = JSONDecoder()
                    let user = try jsonDecoder.decode(GitHubUser.self, from: response.payload)
                    return .right(user)
                }
                catch {
                    return .left(.malformedData(debugInfo: "\(error)"))
                }

            default:
                return .left(.unexpectedStatusCode(debugInfo: "\(response.statusCode)"))
        }
    }


    static func fetch(
        byLogin login: String,
        _ block: @escaping (Either<Either<ConnectionError, TransformError>, GitHubUser>) -> Void
    ) {
        let urlString = "https://api.github.com/users"
        guard let url = URL(string: urlString)?.appendingPathComponent(login) else {
            block(.left(.left(.malformedURL(debugInfo: "\(urlString)/\(login)"))))
            return
        }

        let input: Input = (
            url: url,
            queries: [],
            headers: [:],
            methodAndPayload: .get
        )

        WebAPI.call(with: input) { output in
            switch output {
            case let .noResponse(connectionError):
                block(.left(.left(connectionError)))

            case let .hasResponse(response):
                let errorOrUser = GitHubUser.from(response: response)

                switch errorOrUser {
                case let .left(transformError):
                    block(.left(.right(transformError)))

                case let .right(user):
                    block(.right(user))
                }
            }
        }
    }


    enum TransformError {
        case malformedUsername(debugInfo: String)
        case malformedData(debugInfo: String)
        case unexpectedStatusCode(debugInfo: String)
    }
}
```

```swift:StartSmallForAPITests.swift
import XCTest
@testable import StartSmallForAPI


class StartSmallForAPITests: XCTestCase {
    func testRequest() {
        let input: Input = (
            url: URL(string: "https://api.github.com/zen")!,
            queries: [],
            headers: [:],
            methodAndPayload: .get
        )
        WebAPI.call(with: input)
    }


    func testResponse() {
        let text = "this is a response text"
        let response: Response = (
            statusCode: .ok,
            headers: [:],
            payload: text.data(using: .utf8)!
        )

        let errorOrZen = GitHubZen.from(response: response)
        switch errorOrZen {
        case let .left(error):
            XCTFail("\(error)")

        case let .right(zen):
            XCTAssertEqual(zen.text, text)
        }
    }


    func testRequestAndResponse() {
        let expectation = self.expectation(description: "API")

        let input: Input = (
            url: URL(string: "https://api.github.com/zen")!,
            queries: [],
            headers: [:],
            methodAndPayload: .get
        )

        WebAPI.call(with: input) { output in
            switch output {
            case let .noResponse(connectionError):
                XCTFail("\(connectionError)")

            case let .hasResponse(response):
                let errorOrZen = GitHubZen.from(response: response)
                XCTAssertNotNil(errorOrZen.right)
            }

            expectation.fulfill()
        }

        self.waitForExpectations(timeout: 10)
    }
}
```

```swift:GitHubAPITests.swift
import XCTest
@testable import StartSmallForAPI


class GitHubAPITests: XCTestCase {
    func testZenFetch() {
        let expectation = self.expectation(description: "API")

        GitHubZen.fetch { errorOrZen in
            switch errorOrZen {
            case let .left(error):
                XCTFail("\(error)")

            case let .right(zen):
                XCTAssertNotNil(zen)
            }

            expectation.fulfill()
        }

        self.waitForExpectations(timeout: 10)
    }


    func testZenFetchTwice() {
        let expectation = self.expectation(description: "API")

        GitHubZen.fetch { errorOrZen in
            switch errorOrZen {
            case let .left(error):
                XCTFail("\(error)")

            case .right(_):
                GitHubZen.fetch { errorOrZen in
                    switch errorOrZen {
                    case let .left(error):
                        XCTFail("\(error)")

                    case let .right(zen):
                        XCTAssertNotNil(zen)
                        expectation.fulfill()
                    }
                }
            }
        }

        self.waitForExpectations(timeout: 10)
    }


    func testUser() throws {
        let response: Response = (
            statusCode: .ok,
            headers: [:],
            payload: try JSONSerialization.data(withJSONObject: [
                "id": 1,
                "login": "octocat"
            ])
        )

        switch GitHubUser.from(response: response) {
        case let .left(error):
            XCTFail("\(error)")

        case let .right(user):
            XCTAssertEqual(user.id, 1)
            XCTAssertEqual(user.login, "octocat")
        }
    }


    func testUserFetch() {
        let expectation = self.expectation(description: "API")

        GitHubUser.fetch(byLogin: "Kuniwak") { errorOrUser in
            switch errorOrUser {
            case let .left(error):
                XCTFail("\(error)")

            case let .right(user):
                XCTAssertEqual(user.id, 1124024)
                XCTAssertEqual(user.login, "Kuniwak")
            }

            expectation.fulfill()
        }

        self.waitForExpectations(timeout: 10)
    }
}
```
