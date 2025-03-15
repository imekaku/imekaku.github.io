---
layout: post
title: 在本地和AWS上部署ollama/DeepSeek
category: code
---

# 1. 本地安装部署

ollama官网地址(下载并安装)：[https://ollama.com/download](https://ollama.com/download), 校验是否安装成功：
```
ollama -v
```

拉取deepseek模型：[https://ollama.com/library/deepseek-r1](https://ollama.com/library/deepseek-r1) 这里可以选择哪个版本的模型，选择后使用命令拉取：
```
ollama run deepseek-r1:8b
```

安装完成之后，即服务启动完成。关闭服务之后，下次再启动也是使用同样的命令：
```
ollama run deepseek-r1:8b
```

# 2. 本地文档训练

添加chrome插件：

[https://chromewebstore.google.com/detail/page-assist-a-web-ui-for/jfgfiigpkhlkbnfnbobbkinehhfdhndo](https://chromewebstore.google.com/detail/page-assist-a-web-ui-for/jfgfiigpkhlkbnfnbobbkinehhfdhndo)

向量化模型：[https://ollama.com/library/nomic-embed-text](https://ollama.com/library/nomic-embed-text)，执行命令：
```
ollama pull nomic-embed-text
```

打开chrome插件，在 Setting -> RAG Setting -> Embedding Model，选择 `nomic-embed-text`, 并保存。

然后添加本地文档，在 Setting -> Manage Knowledge -> Add new Knowledge, 上传本地文档，并等待状态变成`Finished`。

测试本地文档训练结果：

在新对话聊天中，在对话框 Submit按钮旁边的按钮中选择知识库，并开启对话。

# 3. 在AWS上部署DeepSeek R1

## 3.1 下载模型文件到本地：

选择 `DeepSeek-R1-Distill-Llama-8B` 或 `DeepSeek-R1-Distill-Llama-70B`


在 HuggingFace上下载model，地址：[https://huggingface.co/deepseek-ai/DeepSeek-R1-Distill-Llama-8B](https://huggingface.co/deepseek-ai/DeepSeek-R1-Distill-Llama-8B)

> AWS目前不支持qwen2的模型架构，会报错：Amazon bedrock does not support the architecture (qwen2) of the model that you are importing. Try again with one of the following supported architectures: [llama, mistral, t5, mixtral, gpt_bigcode, mllama, poolside]

可以使用python 脚本：
```
from huggingface_hub import snapshot_download

model_name = "deepseek-ai/DeepSeek-R1-Distill-Llama-8B"
local_dir = "./DeepSeek-R1-Distill-Llama-8B"

snapshot_download(repo_id=model_name, local_dir=local_dir)
```

## 3.2 上传模型文件到S3

下载好模型之后，在S3中创建对应的bucket和文件夹，如S3: 
```
s3://ollama-deepseek-model/model/DeepSeek-R1-Distill-Llama-8B/
```

使用awscli上传至S3（我试过使用console上传会因为文件过大导致超时），S3可以在`~/.aws/config`中进行配置，配置如下：

```
[default]
region = us-west-2
output = json
multipart_threshold = 64MB
multipart_chunksize = 256MB
```

awscli命令如下：
```
aws s3 sync "/Users/lee/Workspace/ollama/DeepSeek-R1-Distill-Llama-8B" \
s3://ollama-deepseek-model/model/DeepSeek-R1-Distill-Llama-8B/ \
--storage-class STANDARD \
--acl private
```

## 3.3 在Amazon Bedrock导入模型并开启对话

上传完成之后，在AWS Console上:

Amazon Bedrock -> (Foundation models) Imported models -> (Button) Import model

在页面上只需填写模型名字（符合要求即可）`DeepSeek-R1-Distill-Llama-8B`，然后在 **Model import settings** 中选择对应的S3的文件夹，然后点击 `Import Model` 按钮即可。

可能需要等待一些时间创建 Import Model的Job。

完成之后，回到 (Foundation models) Imported models 页面，即可看到页面中有 Model: `DeepSeek-R1-Distill-Llama-8B`, 点击这个Model，并在新页面点击右上角 `Open in playgroud` 即开启对话。

> 但是实际上，对话并不能成功，这里AWS会提示（需要在Support中处理）：To access Amazon Bedrock, you must provide further information so we can verify you are a corporate customer and that we can grant you access given applicable law and internal policy. Please submit a request here: [link](https://support.console.aws.amazon.com/support/home#/case/create?issueType=customer-service&serviceCode=account-management&categoryCode=bedrock-allowlisting&locale=en)

## 3.4 AWS 知识库

由于3.3没有成功，所以我只是了解到是在`AWS Console`上的以下路径打开并建立知识库：

Amazon Bedrock -> (Build tools) Knowledge Bases


