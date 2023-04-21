# S3のクロスアカウントでのデータ移行

新環境のCloudShellに入り実行する

```shell
OLD_BUCKET_NAME=hs-s3-cross-sync-old-bucket
NEW_BUCKET_NAME=hs-s3-cross-sync-new-bucket
S3_SYNC_ROLE=xxxxx

# 実行前の確認
# 権限なしでエラーになる
aws s3 ls s3://$OLD_BUCKET_NAME
# 正常に出力される
aws s3 ls s3://$NEW_BUCKET_NAME

# STSで旧アカウントで作成したIAMロールでの認証情報を取得する
OUTPUT=`aws sts assume-role \
--role-arn $S3_SYNC_ROLE \
--role-session-name s3-cross-sync \
--duration-second 900`

# 必要な認証情報を環境変数で設定する
export AWS_ACCESS_KEY_ID=`echo $OUTPUT | jq -r .Credentials.AccessKeyId`
export AWS_SECRET_ACCESS_KEY=`echo $OUTPUT | jq -r .Credentials.SecretAccessKey`
export AWS_SESSION_TOKEN=`echo $OUTPUT | jq -r .Credentials.SessionToken`

# スイッチロール後の権限の確認
# 正常に出力される
aws s3 ls s3://$OLD_BUCKET_NAME
# 正常に出力される
aws s3 ls s3://$NEW_BUCKET_NAME

# 旧アカウントのバケットのデータを、新アカウントのバケットに同期する
aws s3 sync s3://$OLD_BUCKET_NAME s3://$NEW_BUCKET_NAME
```