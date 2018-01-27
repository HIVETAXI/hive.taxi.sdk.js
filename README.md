# hive.taxi.sdk.js

//change only normal

rake api:contractor (cartographer, driver, client)
rake browser:build

1) Меняем файл  cartographer-1.0.normal.json
2) rake api:cartographer
3) rake browser:build
4) npm publish

Привет. Думаю самым простым тогда будет просто чутка изменить метод в cartographer-1.0.normal.json

Поменять в поле requestUri 1.0 на 1.1 и обновить описание поля, которое хотите изменить.
Затем rake api:cartographer
А потом rake browser:build