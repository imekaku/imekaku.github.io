---
layout: post
title: 使用awscli创建并更新AWS Lambda
category: code
---

# 1. 背景

在平时工作开发的过程中，代码发布走的是pipeline（包括build VersionSet，代码打包，编译，以及在cloudformation设置资源和部署），整个流程快的话也需要半小时左右。所以debug使用单独推的lambda代码可能更为方便。

<br>

# 2. Python方式

## 2.1 Lambda执行role

首先需要为创建的lambda创建一个role `lambda-ex`（当然也可以使用现存的role）：

```
aws iam create-role --role-name lambda-ex \
--assume-role-policy-document file://trust-policy.json
```

对应的policy内容如下：

```
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

附加AWSLambdaBasicExecutionRole策略，该策略提供了Lambda函数在CloudWatch中记录日志的权限:

```
aws iam attach-role-policy --role-name lambda-ex \
--policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
```

<br>

## 2.2 打包Lambda执行文件

由于可能python代码中需要其他起来包，比如依赖`requests`，那么就需要先安装这个依赖包本地，如当前python项目的文件夹为 `DemoPython`，其中的代码文件为 `demo.py`。
目录结构为:
```
DemoPython/
└── demo.py
```

进入DemoPython文件夹，在其中执行依赖包 `requests` 的安装命令：
```
pip install requests -t .
```

安装好之后，目录结构应为：
```
DemoPython/
├── bin
├── certifi
├── certifi-2024.7.4.dist-info
├── charset_normalizer
├── charset_normalizer-3.3.2.dist-info
├── demo.py
├── idna
├── idna-3.8.dist-info
├── requests
├── requests-2.32.3.dist-info
├── urllib3
└── urllib3-2.2.2.dist-info
```

然后在DemoPython文件夹内进行打包，执行命令（重复打包能够覆盖之前的文件）：

```
zip -r ../function.zip .
```

<br>

## 2.3 创建并推送Lambda

假设设定aws上lambda名字为：`DemoPython`，则使用下面命令创建远程lambda（在`function.zip`文件那一层执行）：

```
aws lambda create-function --function-name DemoPython \
--zip-file fileb://function.zip --handler demo.lambda_handler \
--runtime python3.9 --role arn:aws:iam::【your aws account id】:role/lambda-ex
```

当修改了代码或者添加了依赖，需要重新打包，并更新lambda，使用下面的命令：
```
aws lambda update-function-code --function-name DemoPython \
--zip-file fileb://function.zip
```

<br>

## 2.4 附

如果是已存在的python lambda，则不需要使用上面的创建role，创建lambda等步骤，直接打包，然后update-function-code即可推送至aws。

<br>

# 3. Java方式

## 3.1 Lambda执行role

与上面python的方式相同，这里不再赘述。

## 3.2 创建并打包Java文件

首先需要在idea中创建一个maven项目，创建完成之后，项目结构应该为：

```
DemoJava/
├── DemoJava.iml
├── pom.xml
└── src
    ├── main
    │   ├── java
    │   │   └── com
    │   │       └── example
    │   │           └── demo
    │   │               └── DemoJava.java
    │   └── resources
    └── test
        └── java
```

然后对应在pom.xml文件中添加依赖，以及`DemoJava.java`中的实现逻辑，`DemoJava.java`中的代码示例如下：

```
package com.example.demo;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import 
com.amazonaws.services.lambda.runtime.events.APIGatewayProxyRequestEvent;
import 
com.amazonaws.services.lambda.runtime.events.APIGatewayProxyResponseEvent;

public class DemoJava 
implements RequestHandler<
        APIGatewayProxyRequestEvent, 
        APIGatewayProxyResponseEvent
> {

    @Override
    public APIGatewayProxyResponseEvent handleRequest(
            APIGatewayProxyRequestEvent event, Context context) {
        APIGatewayProxyResponseEvent response 
                = new APIGatewayProxyResponseEvent();
        response.setStatusCode(200);
        response.setBody("success");
        return response;
    }
}
```

pom.xml文件示例如下：

```
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation=
"http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
<modelVersion>4.0.0</modelVersion>

<groupId>org.example</groupId>
<artifactId>DemoJava</artifactId>
<version>1.0-SNAPSHOT</version>
<packaging>jar</packaging>

<dependencies>
    <dependency>
        <groupId>com.amazonaws</groupId>
        <artifactId>aws-lambda-java-core</artifactId>
        <version>1.2.1</version>
    </dependency>
    <dependency>
        <groupId>com.amazonaws</groupId>
        <artifactId>aws-lambda-java-events</artifactId>
        <version>3.10.0</version>
    </dependency>
</dependencies>

<build>
<plugins>
    <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-shade-plugin</artifactId>
        <version>3.2.4</version>
        <executions>
            <execution>
                <phase>package</phase>
                <goals>
                    <goal>shade</goal>
                </goals>
                <configuration>
    <createDependencyReducedPom>false</createDependencyReducedPom>
                </configuration>
            </execution>
        </executions>
    </plugin>
    <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-compiler-plugin</artifactId>
        <configuration>
            <source>6</source>
            <target>6</target>
        </configuration>
    </plugin>
</plugins>
</build>
</project>
```

进行打包，在项目目录执行命令：
```
mvn clean package
```

执行完成之后，会生成一个target文件夹，并在其下得到一个jar文件，如：`DemoJava-1.0-SNAPSHOT.jar`

## 3.3 创建并推送Lambda

这一步和python的也相似，只不过推送的是Java代码，命令如下：
```
aws lambda create-function --function-name DemoJava \
--zip-file fileb://./target/DemoJava-1.0-SNAPSHOT.jar \
--handler com.example.demo.DemoJava::handleRequest \
--runtime java8 --role arn:aws:iam::【your aws account id】:role/lambda-ex
```

更新lambda：
```
aws lambda update-function-code --function-name DemoJava \
--zip-file fileb://./target/DemoJava-1.0-SNAPSHOT.jar
```

<br>

# 4. 更新handle入口函数

更新handle入口函数需要先上传更新后的代码，然后再将handle更新。

python代码更新handle命令为：
```
aws lambda update-function-configuration \
--function-name DemoPython --handle demo.handle
```

Java代码更新handle命令为（因为Java代码需要继承接口，一般函数名不会变动，可能类名更改，比如更改为DemoJava1）：
```
aws lambda update-function-configuration \
--function-name DemoJava --handler com.example.demo.DemoJava1::handleRequest
```