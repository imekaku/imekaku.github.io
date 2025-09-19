---
layout: post
title: iOS开发过程中的一些SwiftUI问题
category: code
---

# 1. 重复onAppear

在SwiftUI中，`onAppear`修饰符包裹的逻辑被调用多次。

有三个页面，ChannelView、ChannelPostEditView、DetailView，ChannelView页面可以跳转到ChannelPostEditView、DetailView页面。

ChannelView可以简化为：

```
struct ChannelView: View {
    
    // 省略其他代码
    var body: some View {
        VStack(spacing: 0) {
            NavigationLink(
                destination: ChannelPostEditView(), 
                isActive: $toChannelPostEditView) 
            {
                EmptyView()
            }
            NavigationLink(
                destination: DetailView(),
                isActive: $toDetailView)
            {
                EmptyView()
            }
            // 省略其他代码
        }
    }
}
```

ChannelPostEditView 可以简化为：

```
struct ChannelPostEditView: View {
    
    @ObservedObject var viewModel = ChannelPostEditModel()
    @ObservedObject var aliyunOssModel = AliyunOssModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // 省略其他代码
        }
    }
}
```

DetailView可以简化为：

```
struct DetailView: View {
            
    var body: some View {
        VStack(spacing: 0) {
            // 省略其他代码
        }
        .onAppear {
            log.info("DetailView onAppear")
        }
    }
}
```

从ChnnelView跳转到DetailView时，DetailView的`onAppear`会被调用两次。即是：进入DetailView时，`DetailView onAppear`被打印一次，然后从DetailView返回ChannelView时，`DetailView onAppear`又被打印一次。

排查之后发现居然是由于 ChannelPostEditView中声明的两个model引起的。

```
    @ObservedObject var viewModel = ChannelPostEditModel()
    @ObservedObject var aliyunOssModel = AliyunOssModel()
```

将这两行代码删除之后，`DetailView onAppear`只会被打印一次。

但是我在其他页面上实验这个问题，却没有复现。怪怪的。

我讲ObservedObject改成了StateObject之后，这个问题没有复现。