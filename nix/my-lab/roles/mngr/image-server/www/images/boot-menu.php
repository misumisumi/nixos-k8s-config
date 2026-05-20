<?php

// 1. Composerのオートローダーを読み込む
require __DIR__ . '/../vendor/autoload.php';

use Twig\Loader\FilesystemLoader;
use Twig\Environment;

// --- 設定 ---
$image_dir = __DIR__ . '/ipxe'; // /var/www/images/ipxe を指す
$template_dir = __DIR__ . '/templates'; // Twigテンプレートを置くディレクトリ
// ---

// 2. Twig環境のセットアップ
// テンプレートファイルのロードパスを設定
$loader = new FilesystemLoader($template_dir);
$twig = new Environment($loader, [
    // キャッシュを有効にすることでパフォーマンスが向上します
    // 'cache' => __DIR__ . '/cache',
]);

// 3. /var/www/ipxe/ 以下のディレクトリを走査してメニューデータを生成
$boot_items = [];
// GLOB_ONLYDIR フラグでディレクトリのみを取得
$directories = glob($image_dir . '/*', GLOB_ONLYDIR);

foreach ($directories as $dir_path) {
    $dir_name = basename($dir_path);
    // . や ..、特定の除外ディレクトリを除外
    if (!in_array($dir_name, ['.', '..'])) {
        $boot_items[] = [
            'name' => $dir_name,
            'path' => $dir_path,
        ];
    }
}

// 4. Twigテンプレートのレンダリング
try {
    $ipxe_script = $twig->render('menu.ipxe.twig', [
        'boot_items' => $boot_items,
    ]);
} catch (\Exception $e) {
    // エラー処理（デバッグ時のみ）
    header('Content-Type: text/plain');
    echo "#!ipxe\necho Template rendering error: " . $e->getMessage();
    exit;
}

// 5. iPXEスクリプトとして応答
header('Content-Type: text/plain'); // iPXEはtext/plainを期待
echo $ipxe_script;
