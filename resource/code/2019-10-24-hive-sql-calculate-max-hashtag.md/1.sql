-- 拼接信息
SELECT  origin_hashtag
        ,COLLECT_LIST(item_map) AS video_items
        ,COUNT(*) AS cnt
FROM    (
            SELECT  origin_hashtag
                    ,STR_TO_MAP(
                        CONCAT(
                            'video_id:'
                            ,nvl(video_id,'')
                            ,'&user_id:'
                            ,nvl(user_id, '')
                            ,'&hashtag:'
                            ,nvl(origin_hashtag, '')
                        )
                        ,'&'
                        ,':'
                    ) AS item_map
            FROM    (
                        -- 完成获取视频信息，以及数量最多的原始hashtag
                        SELECT  video_id
                                ,user_id
                                ,t6.origin_hashtag AS origin_hashtag
                        FROM    (
                                    -- 原始视频信息
                                    SELECT  video_id
                                            ,user_id
                                            ,upper(hashtag) AS hashtag
                                    FROM    d.table1
                                ) t5 LEFT
                        JOIN    (
                                    -- 求出不区分大小写的hashtag数量，以及对应的数量最多原始hashtag(origin_hashtag)
                                    SELECT  t1.hashtag AS hashtag
                                            ,t1.origin_hashtag AS origin_hashtag
                                            ,origin_cnt
                                    FROM    (
                                                -- 求出不区分大小写的hashtag的数量，即origin_cnt
                                                SELECT  origin_hashtag
                                                        ,hashtag
                                                        ,COUNT(1) AS origin_cnt
                                                FROM    (
                                                            SELECT  hashtag AS origin_hashtag
                                                                    ,upper(hashtag) AS hashtag
                                                            FROM    d.table1
                                                        ) t1
                                            ) INNER
                                    JOIN    (
                                                -- 求出不区分大小写的hashtag数量最多的数值，即max_origin_cnt
                                                SELECT  hashtag
                                                        ,MAX(origin_cnt) AS max_origin_cnt
                                                FROM    (
                                                            -- 求出不区分大小写的hashtag的数量，即origin_cnt
                                                            SELECT  origin_hashtag
                                                                    ,hashtag
                                                                    ,COUNT(1) AS origin_cnt
                                                            FROM    (
                                                                        SELECT  hashtag AS origin_hashtag
                                                                                ,upper(hashtag) AS hashtag
                                                                        FROM    d.table1
                                                                    ) t2
                                                        ) t3
                                                GROUP BY hashtag
                                            ) t4
                                    ON      t1.hashtag = t4.hashtag
                                    AND     t1.origin_cnt = t4.max_origin_cnt
                                ) t6
                    ) t7
        ) t8
GROUP BY origin_hashtag
