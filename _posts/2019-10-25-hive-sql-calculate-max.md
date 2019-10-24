---
layout: post
title: 写一段SQL聚合最大值的SQL
category: architecture
---

这样一个需求：

有一张表，里面有video_id,user_id,hashtag等字段。hashtag有大小写，现在需要将数据行聚集到某一hashtag中(即当前数据行的hashtag不区分大小写形式的)，且这个hashtag为数量出现表中同一hashtag出现次数最多的。

## 例子

原始数据表

| video_id      |    user_id | hashtag |
| :--------: | :--------:| :----------: |
| id_1  | uid_1 | happy |
| id_2  | uid_2 | Happy |
| id_3  | uid_3 | Happy |

聚合之后

| hashtag | items | cnt |
| Happy   | [{"video_id":"id_1", "user_id":"uid_1", "hashtag":"happy"},{"video_id":"id_2", "user_id":"uid_2", "hashtag":"Happy"},{"video_id":"id_3", "user_id":"uid_3", "hashtag":"Happy"},]|3|
