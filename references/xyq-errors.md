# 小云雀 API 错误码字典

xyq_poll.sh **退出码 4** 时,读 `<WORKDIR>/xyq_error.txt`,对照下表给用户**可执行**的解决方案。

## 已知错误码

| code | starling_key | 含义 | 应对 |
|---|---|---|---|
| 11001 | `insufficient_credit_key` | 账户积分不足 | 打开 https://xyq.jianying.com 充值 / 等待月度额度刷新 / 切到更便宜的模型(如果支持) |
| 10xxx | `rate_limit_*` | 限流 | 等 5-10 分钟再 resume |
| 12xxx | `content_audit_*` | 内容审核未通过 | 改 brief,去掉敏感词(暴力/政治/血腥/品牌) |
| 13xxx | `asset_*` | 资产相关(上传/解析失败) | 重新上传源视频;检查文件大小 ≤ 200MB |
| 14xxx | `model_*` | 模型暂时不可用 | 等待或换模型 |

## 给用户的诊断模板

```
小云雀返回错误:
- 错误码: <code>
- 错误描述: <message>
- 这通常表示: <根据上表>

建议:
1. <可执行解决方案>
2. <备选方案>

任务保留在 thread_id: <tid>,问题解决后可以 resume 继续。
```

## 积分不足的特殊处理(11001)

`extra.commercial_info_list` 里 `used_quota_count` 字段是**这个任务预估要消耗的积分**(不是已消耗)。

例:`used_quota_count: 30` = 这条 demo 任务要 30 个积分,账户没有,所以被拦下。

充值后**不需要重新上传/重新提交**,直接用同一个 thread_id 跑 `xyq_resume.sh` 发"继续生成"即可。
