---
layout: post
title: 写一段SQL聚合最大值的SQL
category: code
---

## 背景

这样一个需求：

有一张表，里面有video_id,user_id,hashtag等字段。hashtag有大小写，现在需要将数据行聚集到某一hashtag中，且这个hashtag为数据表中同一hashtag(不区分大小写的hashtag)出现次数最多的。

## 例子

原始数据表

```
|        video_id |         user_id |         hashtag |
| --------------- | --------------- | --------------- |
|            id_1 |           uid_1 |           happy |
|            id_2 |           uid_2 |           Happy |
|            id_3 |           uid_3 |           Happy |
```
Happy这个hashtag出现得最多，所以需要将所有不区分大小写的happy hashtag 都换成 Happy，然后聚合在一个。

中间表

```
|        video_id |         user_id |         hashtag |
| --------------- | --------------- | --------------- |
|            id_1 |           uid_1 |           Happy |
|            id_2 |           uid_2 |           Happy |
|            id_3 |           uid_3 |           Happy |
```

结果表
```
|         hashtag |                    video_items |             cnt |
| --------------- | ------------------------------ | --------------- |
|           Happy | [{"video_id":"id_1", "user_id":|                3|
|                 |  "uid_1", "hashtag":"Happy"},  |                 |
|                 |  {"video_id":"id_2", "user_id":|                 |
|                 |  "uid_2", "hashtag":"Happy"},  |                 |
|                 |  {"video_id":"id_3", "user_id":|                 |
|                 |  "uid_3", "hashtag":"Happy"},] |                 |
```

<a class="extra" href="https://github.com/imekaku/imekaku.github.io/blob/master/resource/code/2019-10-24-hive-sql-calculate-max-hashtag.md/1.sql"> SQL参考 </a>
