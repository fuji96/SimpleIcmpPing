SimpleIcmpPing
=====

ICMPでのシンプルな機能のPingです。

## Usage

SimpleIcmpPing.rb <送信先ホスト> 

以下のオプションを任意で指定できます。
 -i 送信インターバル。ミリ秒で指定。(デフォルト：1000)
 -r 繰り返し回数。(デフォルト：3回)
 -t タイムアウト値。ミリ秒で指定。(デフォルト：5000)
 -d 詳細表示。疎通確認失敗時にタイプとコードを表示する。"true"もしくは"false"で指定。(デフォルト：false)
