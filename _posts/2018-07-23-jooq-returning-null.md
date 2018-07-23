---
layout: post
title: JOOQ returning Null 解析
category: code
---

在使用jooq完成数据库更新的时候有类似这样的的操作：

```java
UserRecord userRecord = dslContext.insertInto(USER)
        .set(USER.USERNAME, userinfoRequest.getUsername())
        .set(USER.CREATE_TIME, timestamp)
        .onDuplicateKeyIgnore()
        .returning()
        .fetchOne();
```
这里使用 <code>onDuplicateKeyIgnore</code> 如果有主键或者唯一索引，重复时不进行插入操作，并且返回插入的或者返回已经存在的记录，但是在这里是返回的Null。

debug发现在在 <code>org.jooq.impl.AbstractDMLQuery</code>有这样的逻辑：
```java
case MYSQL:
    listener.executeStart(ctx);
    result = ctx.statement().executeUpdate();
    ctx.rows(result);
    listener.executeEnd(ctx);
    rs = ctx.statement().getGeneratedKeys();

    int var6;
    try {
        List<Object> list = new ArrayList();
        if (rs != null) {
            while(rs.next()) {
                list.add(rs.getObject(1));
            }
        }

        this.selectReturning(ctx.configuration(), list.toArray());
        var6 = result;
    } finally {
        JDBCUtils.safeClose(rs);
    }

    return var6;
```
这里如果数据库的自增键为空，那么直接执行 <code>this.selectReturning()</code> 函数。

```java
private final void 
selectReturning(Configuration configuration, Object... values) {
    if (values != null && values.length > 0 
    	&& this.table.getIdentity() != null) {

        final Field<Object> field = this.table.getIdentity().getField();
        Object[] ids = new Object[values.length];

        for(int i = 0; i < values.length; ++i) {
            ids[i] = field.getDataType().convert(values[i]);
        }

        if (this.returning.size() == 1 
        	&& (new Fields(this.returning)).field(field) != null) {
            //...
        } else {
            this.returned = this.create(configuration)
            .select(this.returning)
            .from(this.table)
            .where(new Condition[]{field.in(ids)}).fetchInto(this.table);
        }
    }

}
```
第一个if语句是进不去的，<code>this.table.getIdentity() == null</code> 继续接下来的步骤。
```java
public final Result<R> getReturnedRecords() {
    if (this.returned == null) {
        this.returned = 
        new ResultImpl(this.configuration(), this.returning);
    }

    return this.returned;
}
///...
public final R fetchOne() {
    ((InsertQuery)this.getDelegate()).execute();
    return Tools.filterOne(((InsertQuery)this.getDelegate())
    	.getReturnedRecords());
}

static final <R extends Record> 
R filterOne(List<R> list) throws TooManyRowsException {
    int size = list.size();
    if (size == 1) {
        return (Record)list.get(0);
    } else if (size > 1) {
        throw new TooManyRowsException("Too many rows selected : " + size);
    } else {
        return null;
    }
}
```


所以当数据库的没有自增键的时候，返回的结果是Null。
