# hive.taxi.sdk.js

//change only normal

rake api:contractor (cartographer, driver, client)
rake browser:build

1) Меняем файл cartographer-1.0.normal.json
2) rake api:cartographer - получаем cartographer-1.0.min.json
3) rake browser:build
5) комит и пуш
4) поменять версию пакет в файле package.json
5) npm publish
6) затем нужно обновить весрию библиотеки там, где вы её собираетесь использовать