---
layout: post
title: 用户画像设计，行为分数计算
category: architecture
---

# 画像数据流动

client -> (log-server -> )log-distribution -> user-profile -> recommend

用户在客户端上操作，此处由客户端同学埋点，埋点上报数据进入日志服务，会在本地存储一份同步到数据分析平台，另一份进入MetaQ，分发到各处需要日志的服务，log-distribution服务用来为画像采集日志，此处单独起一个服务是为画像聚集日志数据，因为部分日志可能不从MetaQ上报，可能通过接口。如果在画像侧开一个额外接收日志的接口会增加耦合度。

用户画像服务得到日志，并计算存储画像数据。当推荐服务请求画像时，再根据画像数据，按照时间衰减得出当前的兴趣列表以及对应的分数。在根据兴趣列表拉取到内容列表，根据内容的item_ctr * 拉取到的分数进行排序。

<br>

# 画像数据存储

根据行为来计算分数的画像，在画像服务侧只存储了两个数据，一个标识对何种类型感兴趣的分数，以及事件发生的时间。这里采用的redis zset存储(使用两个zset，一个存储感兴趣的类型，一个存储兴趣发生的时间)。

zset 分为三个部分：key,value,score。

- key: Type-PrefixKey-Id 根据用户id和感兴趣的类型拼接的key,type标识这是score键/eventTime键
- value: 感兴趣的类型的id/name
- score: 为分数或者事件发生的时间

<br>

# 画像分数计算

用户发生的事件之后，推荐根据用户id拉取兴趣列表和分数时，计算规则如下

$$ nowScore = \dfrac{score}{e^{k({g_{0} - t_{0}})}}$$

- score: 用户对应行为的分数
- g_0: 推荐拉取用户行为的时间
- t_0: 事件发生的时间
- k: 时间衰减系数

那么再一次发生事件，推荐再一次根据id拉取兴趣列表和分数时的计算方式应该为：

$$ nowScore = \dfrac{score_{0}}{e^{k({g_{1} - t_{0}})}} +  \dfrac{score_{1}}{e^{k({g_{1} - t_{1}})}}$$

- g_1: 第二次推荐拉取用户画像的时间
- t_1: 第二次时间发生的时间

并且依次类推，以及相加之后发生事件的分数和对应的时间。

<br>

# 画像分数使用存储数据计算

使用zset存储的分数以及事件发生的时间只有一个值(一个score 和 一个eventTime)，所以就需要将每次的分数和对应的时间运算得出一个最新的结果。计算方式如下：

- 第一次事件发生时间的时候，两个zset上存在的score为 score_0, 时间为 t_0。

- 第一次推荐拉取画像的时候g_0，两个zset上存在的score为 score_1, 时间为 g_0，计算规则如下：

$$ score_{1} = \dfrac{score_{0}}{e^{k({g_{0} - t_{0}})}}$$

- 第二次事件发生的时候，两个zset上存在的score为 score_3, 时间为 t_1，计算规则如下：

$$ score_{3} =  \dfrac{score_{1}}{e^{k({t_{1} - g_{0}})}} + score_{2}$$

- 第二次推荐拉取画像的时候，两个zset上存在的score为 nowScore, 时间为 g_1，计算规则如下：

$$ nowScore =  \dfrac{score_{3}}{e^{k({g_{1} - t_{1}})}} $$

把公式叠加在一起就是：

$$ nowScore =  \dfrac{\dfrac{\dfrac{score_{0}}{e^{k({g_{0} - t_{0}})}}}{e^{k({t_{1} - g_{0}})}} + score_{1}}{e^{k({g_{1} - t_{1}})}} $$

展开之后得到和原本的计算逻辑的公式：

$$ nowScore = \dfrac{score_{0}}{e^{k({g_{1} - t_{0}})}} +  \dfrac{score_{1}}{e^{k({g_{1} - t_{1}})}}$$

<br>

# 画像合并

使用zset还有一个好处是，zset提供了zunionstore方法，可以直接合并两个用户的画像，比如需要合并匿名用户和登录用户的画像。

<br>

# 计算逻辑

```java
/**
 * 当新事件发生时，需要将缓存中的分数以及事件发生的时间取出来，
 * 进行衰减后，加上刚发生的事件分数。
 * 如果缓存中没有值，则直接更新。
 */
@Override
public <T extends BaseTargetBean> 
void incrbyTargetCache(List<T> targetList) {
    targetList.forEach(target -> {
        executorService.execute(() -> {

            String targetKey = 
                    zsetKeyFunctionMap.get(target.getClass())
                            .apply(target.getId());
            String targetEventTimeKey = 
                    eventTimeZsetKeyFunctionMap.get(target.getClass())
                            .apply(target.getId());

            // 完整的计算公式
            Double score = 
                    jedisCluster.zscore(targetKey, target.getElement()
                            .toString());
            if (score == null) {
                jedisCluster.zadd(
                        targetKey, 
                        target.getScore(), 
                        target.getElement().toString()
                );
                jedisCluster.zadd(
                        targetEventTimeKey, 
                        System.currentTimeMillis(), 
                        target.getElement().toString()
                );
                jedisCluster.expire(targetKey, EXPIRE_SECOND_TIME);
                jedisCluster.expire(targetEventTimeKey, EXPIRE_SECOND_TIME);
            } else {
                Double eventTime = 
                        jedisCluster.zscore(
                                targetEventTimeKey, 
                                target.getElement().toString()
                        );
                jedisCluster.zadd(
                        targetEventTimeKey, 
                        System.currentTimeMillis(), 
                        target.getElement().toString()
                );
                if (eventTime != null) {
                    double finalScore = score 
                            / coolingService.getCurrentTimeScore(
                                    eventTime.longValue()) 
                            + target.getScore();
                    jedisCluster.zadd(
                            targetKey, 
                            finalScore, 
                            target.getElement().toString()
                    );
                }
                jedisCluster.expire(targetKey, EXPIRE_SECOND_TIME);
                jedisCluster.expire(targetEventTimeKey, EXPIRE_SECOND_TIME);
            }
        });
    });
}
```