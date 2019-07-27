---
layout: post
title: Java 线程池浅析
category: code
---

## 背景

之前出现过这样的一个状况：
使用 java.util.concurrent.CompletableFuture 类中 runAsync 提交任务，由于没有指定线程池，使用的是ForkJoinPool.commonPool()作为线程池执行异步代码。
线上任务提交得太快，线程池中线程执行任务太慢，导致创建太多线程，以及提交到任务队列，任务队列不断增加，耗光内存，线上大量的GC。

<br>
## 优化

首先这边先使用自定义线程池，还是发现队列过长，以及创建线程数过多的情况

```json
{
  "threadInfo": {
    "active": 768,
    "finished": 240087,
    "queue": 401621
  }
}
```
其实关键是maximumPoolSize和workQueue，控制好最大线程数以及任务队列(最好为阻塞的)，以及拒接策略。

<br>
## ThreadPoolExecutor线程池的构造函数

```java
public ThreadPoolExecutor(int corePoolSize,
                          int maximumPoolSize,
                          long keepAliveTime,
                          TimeUnit unit,
                          BlockingQueue<Runnable> workQueue,
                          ThreadFactory threadFactory,
                          RejectedExecutionHandler handler) {
}
```

<br>
### 线程池参数说明

int corePoolSize 线程池中保留的线程数量
int maximumPoolSize 线程池的最大大小
long keepAliveTime 当前线程数超过corePoolSize时，空闲线程的最长保留时间
TimeUnit unit 时间单位
BlockingQueue<Runnable> workQueue 任务队列
ThreadFactory threadFactory 线程创建工厂
RejectedExecutionHandler handler 当到达最大线程数和队列最大容量的时候，拒绝策略

### 任务提交顺序

当提交任务当线程中时，由corePoolSize数量的线程去执行(假设线程执行的时间无限长)，并且达到corePoolSize，
再次提交任务时，任务会被放置于workQueue，并且达到workQueue size,
再次提交任务时，线程池会重新创建线程，来执行任务，并且达到maximumPoolSize，
再次提交任务时，由于此时已经达到最大线程数并且达到最大队列容量，所以执行拒绝策略。

### 默认拒绝策略

拒绝该任务，并且把该任务放置于调用者线程中去执行，当线程池中的线程被shutdown之后，任务会被丢弃。

```java
public static class CallerRunsPolicy implements RejectedExecutionHandler {
    public CallerRunsPolicy() { }

    /**
     * Executes task r in the caller's thread, unless the executor
     * has been shut down, in which case the task is discarded.
     *
     * @param r the runnable task requested to be executed
     * @param e the executor attempting to execute this task
     */
    public void rejectedExecution(Runnable r, ThreadPoolExecutor e) {
        if (!e.isShutdown()) {
            r.run();
        }
    }
}
```

拒绝任务，并抛出异常

```java
public static class AbortPolicy implements RejectedExecutionHandler {

    public AbortPolicy() { }

    /**
     * Always throws RejectedExecutionException.
     *
     * @param r the runnable task requested to be executed
     * @param e the executor attempting to execute this task
     * @throws RejectedExecutionException always
     */
    public void rejectedExecution(Runnable r, ThreadPoolExecutor e) {
        throw new RejectedExecutionException("Task " + r.toString() +
                                             " rejected from " +
                                             e.toString());
    }
}
```

抛弃任务

```java
public static class DiscardPolicy implements RejectedExecutionHandler {
    /**
     * Creates a {@code DiscardPolicy}.
     */
    public DiscardPolicy() { }

    /**
     * Does nothing, which has the effect of discarding task r.
     *
     * @param r the runnable task requested to be executed
     * @param e the executor attempting to execute this task
     */
    public void rejectedExecution(Runnable r, ThreadPoolExecutor e) {
    }
}
```

丢弃队列中第一个任务，并将任务加入队列

```java
public static class DiscardOldestPolicy implements RejectedExecutionHandler {
    public DiscardOldestPolicy() { }

    /**
     * Obtains and ignores the next task that the executor
     * would otherwise execute, if one is immediately available,
     * and then retries execution of task r, unless the executor
     * is shut down, in which case task r is instead discarded.
     *
     * @param r the runnable task requested to be executed
     * @param e the executor attempting to execute this task
     */
    public void rejectedExecution(Runnable r, ThreadPoolExecutor e) {
        if (!e.isShutdown()) {
            e.getQueue().poll();
            e.execute(r);
        }
    }
}
```

<br>
## 备忘：直接创建Thread两种方式

```java
public class ThreadTest {

    public static class MyRunnable implements Runnable {
        @Override
        public void run() {
            System.out.println("hello");
        }
    }

    public static class MyThread extends Thread {
        @Override
        public void run() {
            System.out.println("myThread hello");
        }
    }

    @Test
    public void test() {
        Thread thread = new Thread(new MyRunnable());
        thread.start();

        Thread thread1 = new MyThread();
        thread1.start();
    }

}
```


参考：

- [ForkJoinPool解读](https://kaimingwan.com/post/java/forkjoinpooljie-du)
- [Java CompletableFuture 详解](https://colobu.com/2016/02/29/Java-CompletableFuture/#%E5%88%9B%E5%BB%BACompletableFuture%E5%AF%B9%E8%B1%A1%E3%80%82)

