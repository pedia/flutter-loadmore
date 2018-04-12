# Flutter 下拉刷新控件整体流程梳理

## 系统流程
```
    ScrollStartNotification  						// 滚动开始
    UserScrollNotification   						// 用户拖动
    ScrollUpdateNotification						// 向下滚动
    ScrollUpdateNotification (detail is null) 		// 用户松手
    ScrollEndNotification							// 归位
    UserScrollNotification							// 停止
```

## 状态变化

    ScrollStartNotification  						// 滚动开始  
    UserScrollNotification   						// 用户拖动
    
    => 记录开始拖动状态
    
    ScrollUpdateNotification						// 向下滚动
    
    => 监听变化判断过程
    
        -> 根据变化过程更新UI
        => 超过位置	记录松手时需要刷新/加载
        => 未超过		记录松手则直接归位
    
    ScrollUpdateNotification (detail is null) 		// 用户松手
    
    => 根据状态判断是否要显示
        => 回调 加载刷新/更多方法
    
    ScrollEndNotification							// 归位
    UserScrollNotification							// 停止


## 状态统计
1. 空闲
2. 拖动中 释放归位
3. 拖动中 释放刷新
4. 刷新中
5. 结束