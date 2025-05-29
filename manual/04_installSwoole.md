# Install Swoole

[Go Back](./../README.md)

Login into Ubuntu

```bash
sudo apt-get install -y libcurl4-openssl-dev libc-ares-dev postgresql postgresql-contrib libpq-dev
wget https://github.com/swoole/swoole-src/archive/refs/tags/v6.0.2.tar.gz
tar --extract --gzip --file v6.0.2.tar.gz
rm -f v6.0.2.tar.gz
cd swoole-src-6.0.2
phpize && \
./configure \
--enable-openssl --enable-swoole-curl --enable-cares --enable-swoole-pgsql --enable-swoole-thread
sudo make

# If no errors

sudo make install
php --ini

# Add extension
echo 'extension=swoole.so' | sudo tee -a /usr/local/lib/php.ini
```

## Test

php test.php

```php
<?php

use Swoole\Thread;

$args = Thread::getArguments();
$c = 4;

if (empty($args)) {
    // # Parent thread
    for ($i = 0; $i < $c; $i++) {
        $threads[] = new Thread(__FILE__, $i);
    }
    for ($i = 0; $i < $c; $i++) {
        $threads[$i]->join();
    }
} else {
    // # Child thread
    echo "Swoole Thread #" . $args[0] . "\n";
    sleep(1);
    var_dump(strlen(file_get_contents('https://www.baidu.com/')));
}

```


php server.php

```php
<?php

use Swoole\Process;
use Swoole\Thread;
use Swoole\Http\Server;

$http = new Server("0.0.0.0", 9503, SWOOLE_THREAD);
$http->set([
    'worker_num' => 2,
    'task_worker_num' => 3,
    'bootstrap' => __FILE__,
    // 通过init_arguments实现线程间的数据共享。
    'init_arguments' => function () use ($http) {
        $map = new Swoole\Thread\Map;
        return [$map];
    }
]);

$http->on('Request', function ($req, $resp) use ($http) {
    $resp->end('hello world');
});

$http->on('pipeMessage', function ($http, $srcWorkerId, $msg) {
    echo "[worker#" . $http->getWorkerId() . "]\treceived pipe message[$msg] from " . $srcWorkerId . "\n";
});

$http->addProcess(new Process(function () {
   echo "user process, id=" . Thread::getId();
   sleep(2000);
}));

$http->on('Task', function ($server, $taskId, $srcWorkerId, $data) {
    var_dump($taskId, $srcWorkerId, $data);
    return ['result' => uniqid()];
});

$http->on('Finish', function ($server, $taskId, $data) {
    var_dump($taskId, $data);
});

$http->on('WorkerStart', function ($serv, $wid) {
    // 通过Swoole\Thread::getArguments()获取配置中的init_arguments传递的共享数据
    var_dump(Thread::getArguments(), $wid);
});

$http->on('WorkerStop', function ($serv, $wid) {
    var_dump('stop: T' . Thread::getId());
});

$http->start();
```

[Go Back](./../README.md)