import re
import sys

import boto3

s3_conn = boto3.client('s3', region_name='us-east-1')


def list_objects(bucket, prefix: str = ""):
    print("Listing objects...")
    s3_result = s3_conn.list_objects_v2(
        Bucket=bucket,
        Prefix=prefix,
    )
    if 'Contents' not in s3_result:
        return []

    file_list = []
    for file in s3_result['Contents']:
        file_list.append(file)

    while s3_result['IsTruncated']:
        continuation_key = s3_result['NextContinuationToken']
        s3_result = s3_conn.list_objects_v2(
            Bucket=bucket,
            Prefix=prefix,
            ContinuationToken=continuation_key
        )
        for file in s3_result['Contents']:
            file_list.append(file)
        print(f"{len(file_list)}...", end='', flush=True)
    print('\n')
    return file_list


def sizeof_fmt(num, suffix="B"):
    for unit in ["", "Ki", "Mi", "Gi", "Ti", "Pi", "Ei", "Zi"]:
        if abs(num) < 1024.0:
            return f"{num:3.1f}{unit}{suffix}"
        num /= 1024.0
    return f"{num:.1f}Yi{suffix}"


def get_size(bucket, prefix: str = "", regex: str = None, top_num: int = None):
    total_size = 0
    count = 0
    output = []
    for file in list_objects(bucket, prefix):
        key = file['Key']
        if regex is not None and re.search(regex, key) is None:
            continue

        count += 1
        total_size += file['Size']
        output.append(file)

    if top_num is not None:
        output.sort(key=lambda f: -f['Size'])
        for o in output[:top_num]:
            print(o)

    size_fmt = sizeof_fmt(total_size)
    print(f'{count} files - {size_fmt}')
    return count, size_fmt


if __name__ == "__main__":
    if len(sys.argv) < 2:
        raise Exception("Invalid num args")

    bucket = sys.argv[1]
    prefix = sys.argv[2] if len(sys.argv) > 2 else ""
    regex = sys.argv[3] if len(sys.argv) > 3 else None
    top_num = sys.argv[4] if len(sys.argv) > 4 else None

    get_size(bucket, prefix, regex, top_num)
