 <?php
// 1. Composerのオートローダーを読み込む
require __DIR__ . '/../vendor/autoload.php';

use Twig\Loader\FilesystemLoader;
use Twig\Environment;

// --- 設定 ---
$template_dir = __DIR__ . '/templates'; // Twigテンプレートを置くディレクトリ
// ---

// 2. Twig環境のセットアップ
// テンプレートファイルのロードパスを設定
$loader = new FilesystemLoader($template_dir);
$twig = new Environment($loader, [
    // キャッシュを有効にすることでパフォーマンスが向上します
    // 'cache' => __DIR__ . '/cache',
]);

## 3. POSTデータの取得と検証
$required_params = array('ip', 'ipv6', 'hostname', 'user', 'serial');
// パラメータがすべて存在するか確認
foreach ($required_params as $param) {
    if (!isset($_POST[$param])) {
        echo "Error: Missing required parameter: " . $param . "\n";
        exit;
    }
}
// POSTデータから値を取得
$ip = $_POST['ip'];
$ipv6 = $_POST['ipv6'];
$hostname = $_POST['hostname'];
$user = $_POST['user'];
$serial = $_POST['serial'];

$data = array($hostname =>
            array("address" => $ip,
                "visible" => true,
                "user" => $user,
                "color" => "blue"
                )
        );

// JSONにエンコード
$jsonData = json_encode($data, JSON_PRETTY_PRINT);

$dir = '/etc/cockpit/machines.d/'; // 保存先のディレクトリを指定
$date = new DateTime();
$timestamp = $date->format('Y_m_d_H:i:s_u'); // マイクロ秒6桁
$filename = $dir . '/05_tmp_' . $timestamp . "_" . $hostname . '.json'; // ファイル名を日付と時刻に基づいて生成

// ファイルに書き込み
if (file_put_contents($filename, $jsonData)) {
    echo "Data saved to " . $filename . "\n";
} else {
    echo "Error saving data to file!\n";
}
?>
