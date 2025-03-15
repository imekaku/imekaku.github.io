---
layout: post
title: Sublime Tips以及Java反射
category: code
---

## 背景

今天需要写这么一段代码，把protobuf生成的Java类转成业务bean。

业务bean中的字段我由线上抓取得到，可以大致理解为如下：

```json
{
    "music_id": "tmp_music_id",
    "music_title": "tmp_music_title",
    "music_author": "tmp_music_author"
}
```


## Sublime 替换步骤

步骤：
```
- 将json中的结构粘贴至sublime，command + A ：全选
- command + shift + L ：光标移至每一行
- command + ← ：移至空格后行首
- command + shift + ← ： 选中每一行行首空格，delete 删除
- alt + → ： 单词跳跃，依次删除第一个引号，以及第二个引号之后都内容
- 用以上类似的方法，添加中间行的信息，以及其他词和分号等
```
得到：
```java
@JSONProperty(value = "music_id")
private String music_id;
@JSONProperty(value = "music_title")
private String music_title;
@JSONProperty(value = "music_author")
private String music_author;
```

需要将该bean中的字段更改为驼峰形式。

步骤：
```
- alt + command + F ：打开替换栏，并勾选正则+大小写
- Find： (_)([a-z])([a-zA-Z]*);
- Replace：\u$2$3;
```

得到：
```java
@JSONProperty(value = "music_id")
private String musicId;
@JSONProperty(value = "music_title")
private String musicTitle;
@JSONProperty(value = "music_author")
private String musicAuthor;
```

如果有多个下划线，就多替换几次。

## Java反射

protobuf生成的Java类中的每一个字段后面都有一个下划线，类似于
```java
private String musicId_;
private String musicTitle_;
private String musicAuthor_;
```
而且为了后面业务需要，也最好转成业务中定义的bean，于是有这样的拷贝一个类的字段值至另一个类的方法：
```java
public static <T, S> void copySourceToTarget(T target, S source)
        throws IllegalAccessException, NoSuchFieldException {

    Field[] targetFields = target.getClass().getDeclaredFields();
    Set<String> targetFieldsNameSet
            = Stream
            .of(targetFields)
            .map(Field::getName)
            .collect(Collectors.toSet());

    Field[] sourceFields = source.getClass().getDeclaredFields();
    for (Field sourceField : sourceFields) {
        
        sourceField.setAccessible(true);
        String fieldName = sourceField.getName().replace("_", "");

        if (targetFieldsNameSet.contains(fieldName)) {

            Field targetField 
            = target.getClass().getDeclaredField(fieldName);

            targetField.setAccessible(true);
            targetField.set(target, sourceField.get(source));
            targetField.setAccessible(false);
        }
        sourceField.setAccessible(false);
    }
}
```
但是对于抓包抓到的返回bean中与protobuf中字段名差异很大的，还需要手动设置一下。

后来发现，使用反射的方式要比直接new来设置对象属性的方式慢很多，就弃用这种方式了。

