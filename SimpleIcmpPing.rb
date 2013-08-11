require 'ipaddr'
require 'socket'
require 'timeout'
require "optparse"

include Socket::Constants



# 送信するデータ
SEND_DATA = "abcdefghijklmnopqrstuvwabcdefghi"
# ICMPエコー要求通知
ICMP_ECHO      = 8
# ICMPエコー応答通知
ICMP_REPLY    = 0
# 受信する応答の最大サイズ
MAX_REPLY_SIZE = 65535
# デフォルトの繰り返し回数
DEFAULT_REPEAT_NUM = 3
# デフォルトの実行間隔
DEFAULT_INTERVAL = 1000
# デフォルトのタイムアウト時間
DEFAULT_TIMEOUT = 5000



# チェックサムを返す
def checksum(mesg)

  # メッセージの長さ
  length = mesg.length
  # アンパック時のフォーマット
  unpackFormat = "n" + (length / 2).to_s
  # 計算結果
  res = 0

  # パケットを足し合わせる
  mesg.unpack(unpackFormat).each do |str|
    res += str
  end

  # オーバーフロー分を足し合わせる
  res = (res & 0xffff) + (res >> 16)
  res = (~((res >> 16) + res) & 0xffff)

  return res
end



# 引数処理
# 繰り返し回数
repeatNum = DEFAULT_REPEAT_NUM
# 実行間隔
interval = DEFAULT_INTERVAL
# タイムアウト
timeout = DEFAULT_TIMEOUT
# 処理時間
exeTime = 0
# 処理開始時間
startTime = 0
# 詳細表示
detail = false
# 引数から送信先を取得
host = ARGV.shift



# オプション定義
opt = OptionParser.new
opt.on("-i [VAL]"){|v| interval = v.to_i}
opt.on("-r [VAL]") {|v| repeatNum = v.to_i}
opt.on("-t [VAL]") {|v| timeout = v.to_i}
opt.on("-d [BOOLEAN]") {|v| detail = v}
opt.parse!(ARGV)



# メイン処理
# ソケットを生成
socket = Socket.new(AF_INET, SOCK_RAW, IPPROTO_ICMP)
# SOCKADDRを取得
soaddr = Socket.pack_sockaddr_in(0, host)
# パック時のフォーマット
packFormat = "C2 n3 A" + (SEND_DATA.length).to_s
# 自プロセスのPIDを取得
pid = Process.pid & 0xffff



for num in 0...repeatNum do
  # 送信するメッセージを生成
  mesg = [ICMP_ECHO, 0, 0, pid, num, SEND_DATA].pack(packFormat)
  checksum = checksum(mesg)
  mesg = [ICMP_ECHO, 0, checksum, pid, num, SEND_DATA].pack(packFormat)

  # インターバルが経過していない場合は待機
  exeTime =(Time.now.instance_eval { self.to_i * 1000 + (usec/1000) })  - startTime
  if startTime != 0 && exeTime < interval then
    sleep((interval - exeTime) / 1000.0)
  end

  # メッセージを送信
  socket.send(mesg, 0, soaddr)
  startTime = Time.now.instance_eval { self.to_i * 1000 + (usec/1000) }

  # 受信処理
  begin
    Timeout.timeout(timeout / 1000.0){
      
      while true
        # メッセージを受信
        data = socket.recv(MAX_REPLY_SIZE)
        # タイプを取得
        type = data[20, 2].unpack('C2').first
        
        # タイプを判定
        if type == ICMP_REPLY then
          # PID、シーケンスIDを取得して比較
          rPid, rNum = data[24, 4].unpack('n3')
          
          if pid == rPid && num == rNum then
            puts "success!"
            break
          end
          
        else
          # PID、シーケンスIDを取得して比較
          rPid, rNum = data[52, 4].unpack('n3')
          
          if pid == rPid && num == rNum then
            puts "false!"
            
            # 詳細表示がtrueの場合はtypeとコードを表示
            if detail then
              code = data[21,2].unpack('C2').first
              puts "type=" + type.to_s + ", code=" + code.to_s
            end
            
            break
          end
          
          break
        end
        
      end
      
    }
  rescue Timeout::Error
    puts "timeout!"
  end
end



socket.close if socket
