# StoreKit Testing Guide

本文用于验证 Jupiter 的“一次性购买解锁下载”能力。

## 1. 基础配置

1. App 内产品 ID 目前配置为：
   - `com.bigfa.jupiter.download.unlock`
2. 配置位置：
   - `Jupiter/Resources/AppConfig.swift`
3. App Store Connect 产品类型：
   - `Non-Consumable`（非消耗型）

## 2. 本地 StoreKit 配置测试（推荐先做）

### 2.1 创建本地配置文件

1. Xcode 菜单 `File > New > File... > StoreKit Configuration File`
2. 文件建议命名：`Jupiter.storekit`
3. 在配置文件内新增一个产品：
   - Product ID: `com.bigfa.jupiter.download.unlock`
   - Type: `Non-Consumable`
   - Display Name: 下载权益
   - Price: 任意测试价格（例如 CNY 6）

### 2.2 绑定到 Scheme

1. 打开 `Product > Scheme > Edit Scheme...`
2. 选择 `Run > Options`
3. 在 `StoreKit Configuration` 选择 `Jupiter.storekit`

### 2.3 验证流程

1. 打开 App 设置页，点击 `下载权益`
2. 进入 paywall，点击购买按钮
3. 期望结果：
   - 按钮变为 `已购买`
   - 状态显示 `已解锁下载权益`
4. 进入照片详情 metadata，点击下载：
   - 不再弹 paywall，直接触发保存逻辑
5. 删除 App 重装后，点击 `恢复购买`：
   - 状态恢复为已解锁

## 3. 真机沙盒测试（发布前必做）

### 3.1 前置条件

1. App Store Connect 已创建同 Product ID 商品
2. 商品状态满足测试条件（可用于沙盒）
3. 使用 `Apple Sandbox Tester` 账号登录设备（设置中媒体与购买）

### 3.2 验证流程

1. 通过 Xcode 安装到真机
2. 打开设置页 `下载权益`
3. 购买后退出并重启 App，确认权益仍然有效
4. 卸载重装后测试 `恢复购买`
5. 在照片 metadata 页测试下载动作

## 4. 关键检查点

1. 购买成功后 `DownloadAccessViewModel.isPurchased == true`
2. 设置页入口状态与 metadata 页行为一致
3. `restore` 后权益可恢复
4. 未授权相册权限时，提示文案正确

## 5. 常见问题排查

1. 提示“购买项不可用”
   - 检查 Product ID 与 `AppConfig` 是否完全一致
   - 本地测试确认 Scheme 已绑定 `.storekit`
2. 购买后仍显示未解锁
   - 检查 `Transaction.currentEntitlements` 是否命中该产品
   - 确认交易是否调用 `finish()`
3. 恢复购买无效
   - 检查是否使用同一 Apple 账号
   - 在沙盒环境中重新登录测试账号后重试

## 6. 手工回归清单

1. 设置页能打开 paywall
2. metadata 页未解锁时跳转 paywall
3. 购买成功后 metadata 页可直接下载
4. 恢复购买可生效
5. 购买失败/取消/等待状态提示正确
