# 创建DNS记录

接口请求域名： teo.tencentcloudapi.com 。

在创建完站点后，并且站点为 NS 模式接入时，您可以通过本接口创建 DNS 记录。

默认接口请求频率限制：20次/秒。

推荐使用 API Explorer
点击调试
API Explorer 提供了在线调用、签名验证、SDK 代码生成和快速检索接口等能力。您可查看每次调用的请求内容和返回结果以及自动生成 SDK 调用示例。
2. 输入参数
以下请求参数列表仅列出了接口请求参数和部分公共参数，完整公共参数列表见 公共请求参数。

参数名称	必选	类型	描述
Action	是	String	公共参数，本接口取值：CreateDnsRecord。
Version	是	String	公共参数，本接口取值：2022-09-01。
Region	否	String	公共参数，此参数为可选参数。
ZoneId	是	String	站点 ID。
Name	是	String	DNS 记录名，如果是中文、韩文、日文域名，需要转换为 punycode 后输入。
Type	是	String	DNS 记录类型，取值有：
A：将域名指向一个外网 IPv4 地址，如 8.8.8.8；
AAAA：将域名指向一个外网 IPv6 地址；
MX：用于邮箱服务器。存在多条 MX 记录时，优先级越低越优先；
CNAME：将域名指向另一个域名，再由该域名解析出最终 IP 地址；
TXT：对域名进行标识和说明，常用于域名验证和 SPF 记录（反垃圾邮件）；
NS：如果需要将子域名交给其他 DNS 服务商解析，则需要添加 NS 记录。根域名无法添加 NS 记录；
CAA：指定可为本站点颁发证书的 CA；
SRV：标识某台服务器使用了某个服务，常见于微软系统的目录管理。

不同的记录类型呢例如 SRV、CAA 记录对主机记录名称、记录值格式有不同的要求，各记录类型的详细说明介绍和格式示例请参考：解析记录类型介绍。
Content	是	String	DNS 记录内容，根据 Type 值填入与之相对应的内容，如果是中文、韩文、日文域名，需要转换为 punycode 后输入。
Location	否	String	DNS 记录解析线路，不指定默认为 Default，表示默认解析线路，代表全部地域生效。

- 解析线路配置仅适用于当 Type（DNS 记录类型）为 A、AAAA、CNAME 时。
- 解析线路配置仅适用于标准版、企业版套餐使用，取值请参考：解析线路及对应代码枚举。
TTL	否	Integer	缓存时间，用户可指定值范围 60~86400，数值越小，修改记录各地生效时间越快，默认为 300，单位：秒。
Weight	否	Integer	DNS 记录权重，用户可指定值范围 -1~100，设置为 0 时表示不解析，不指定默认为 -1，表示不设置权重。权重配置仅适用于当 Type（DNS 记录类型）为 A、AAAA、CNAME 时。
注意：同一个子域名下，相同解析线路的不同 DNS 记录，应保持同时设置权重或者同时都不设置权重。
Priority	否	Integer	MX 记录优先级，该参数仅在当 Type（DNS 记录类型）为 MX 时生效，值越小优先级越高，用户可指定值范围0~50，不指定默认为0。
3. 输出参数
参数名称	类型	描述
RecordId	String	DNS 记录 ID。
RequestId	String	唯一请求 ID，由服务端生成，每次请求都会返回（若请求因其他原因未能抵达服务端，则该次请求不会获得 RequestId）。定位问题时需要提供该次请求的 RequestId。
4. 示例
示例1 创建 DNS 记录
在 ZoneId 为 zone-225qgrnvbi9w 的站点下，创建一个记录名为 www.example.com，记录类型为 A，记录内容为1.2.3.4，缓存时间为60秒的 DNS 记录。

输入示例
POST / HTTP/1.1
Host: teo.tencentcloudapi.com
Content-Type: application/json
X-TC-Action: CreateDnsRecord
<公共请求参数>

{
    "ZoneId": "zone-225qgrnvbi9w",
    "Name": "www.example.com",
    "Type": "A",
    "Content": "1.2.3.4",
    "TTL": 60
}
输出示例
{
    "Response": {
        "RequestId": "5e0a2b4e-df6d-4d2a-ac39-1706cbf8a707",
        "RecordId": "record-225rcy8bw85g"
    }
}
示例2 创建分配权重的 DNS 记录
在 ZoneId 为 zone-225qgrnvbi9w 的站点下，创建一个记录名为 www.example.com，记录类型为 A，记录内容为1.2.3.4，缓存时间为60秒，记录权重为100的 DNS 记录。

输入示例
POST / HTTP/1.1
Host: teo.tencentcloudapi.com
Content-Type: application/json
X-TC-Action: CreateDnsRecord
<公共请求参数>

{
    "ZoneId": "zone-225qgrnvbi9w",
    "Name": "www.example.com",
    "Type": "A",
    "Content": "1.2.3.4",
    "TTL": 60,
    "Weight": 100
}
输出示例
{
    "Response": {
        "RequestId": "5e0a2b4e-df6d-4d2a-ac39-1706cbf8a707",
        "RecordId": "record-225rcy8bw85g"
    }
}
示例3 创建分配解析线路的 DNS 记录
在 ZoneId 为 zone-225qgrnvbi9w 的站点下，创建一个记录名为 www.example.com，记录类型为 A，解析线路为北京（CN.BJ），记录内容为1.2.3.4，缓存时间为60秒的 DNS 记录。

输入示例
POST / HTTP/1.1
Host: teo.tencentcloudapi.com
Content-Type: application/json
X-TC-Action: CreateDnsRecord
<公共请求参数>

{
    "ZoneId": "zone-225qgrnvbi9w",
    "Name": "www.example.com",
    "Type": "A",
    "Location": "CN.BJ",
    "Content": "1.2.3.4",
    "TTL": 60
}
输出示例
{
    "Response": {
        "RequestId": "5e0a2b4e-df6d-4d2a-ac39-1706cbf8a707",
        "RecordId": "record-225rcy8bw85g"
    }
}

# 查询 DNS 记录列表

1. 接口描述
接口请求域名： teo.tencentcloudapi.com 。

您可以用过本接口查看站点下的 DNS 记录信息，包括 DNS 记录名、记录类型以及记录内容等信息，支持指定过滤条件查询对应的 DNS 记录信息。

默认接口请求频率限制：20次/秒。

推荐使用 API Explorer
点击调试
API Explorer 提供了在线调用、签名验证、SDK 代码生成和快速检索接口等能力。您可查看每次调用的请求内容和返回结果以及自动生成 SDK 调用示例。
2. 输入参数
以下请求参数列表仅列出了接口请求参数和部分公共参数，完整公共参数列表见 公共请求参数。

参数名称	必选	类型	描述
Action	是	String	公共参数，本接口取值：DescribeDnsRecords。
Version	是	String	公共参数，本接口取值：2022-09-01。
Region	否	String	公共参数，此参数为可选参数。
ZoneId	是	String	站点 ID。
Offset	否	Integer	分页查询偏移量，默认为 0。
Limit	否	Integer	分页查询限制数目，默认值：20，上限：1000。
Filters.N	否	Array of AdvancedFilter	过滤条件，Filters.Values 的上限为20。详细的过滤条件如下：
id： 按照 DNS 记录 ID 进行过滤，支持模糊查询；
name：按照 DNS 记录名称进行过滤，支持模糊查询；
content：按照 DNS 记录内容进行过滤，支持模糊查询；
type：按照 DNS 记录类型进行过滤，不支持模糊查询。可选项：
   A：将域名指向一个外网 IPv4 地址，如 8.8.8.8；
   AAAA：将域名指向一个外网 IPv6 地址；
   CNAME：将域名指向另一个域名，再由该域名解析出最终 IP 地址；
   TXT：对域名进行标识和说明，常用于域名验证和 SPF 记录（反垃圾邮件）；
   NS：如果需要将子域名交给其他 DNS 服务商解析，则需要添加 NS 记录。根域名无法添加 NS 记录；
   CAA：指定可为本站点颁发证书的 CA；
   SRV：标识某台服务器使用了某个服务，常见于微软系统的目录管理；
   MX：指定收件人邮件服务器。
ttl：按照解析生效时间进行过滤，不支持模糊查询。
SortBy	否	String	排序依据，取值有：
content：DNS 记录内容；
created-on：DNS 记录创建时间；
name：DNS 记录名称；
ttl：缓存时间；
type：DNS 记录类型。
默认根据 type, name 属性组合排序。
SortOrder	否	String	列表排序方式，取值有：
asc：升序排列；
desc：降序排列。
默认值为 asc。
Match	否	String	匹配方式，取值有：
all：返回匹配所有查询条件的记录；
any：返回匹配任意一个查询条件的记录。
默认值为 all。
3. 输出参数
参数名称	类型	描述
TotalCount	Integer	DNS 记录总数。
DnsRecords	Array of DnsRecord	DNS 记录列表。
RequestId	String	唯一请求 ID，由服务端生成，每次请求都会返回（若请求因其他原因未能抵达服务端，则该次请求不会获得 RequestId）。定位问题时需要提供该次请求的 RequestId。
4. 示例
示例1 查询指定记录 ID 的 DNS 记录列表
在 ZoneId 为 zone-2zo8myp3av8i 的站点下，查询记录 ID 为 record-3277epj0rm2y 的 DNS 记录列表，并且按照记录创建时间进行降序排序。

输入示例
POST / HTTP/1.1
Host: teo.tencentcloudapi.com
Content-Type: application/json
X-TC-Action: DescribeDnsRecords
<公共请求参数>

{
    "ZoneId": "zone-2zo8myp3av8i",
    "Offset": 0,
    "Limit": 100,
    "Filters": [
        {
            "Fuzzy": false,
            "Values": [
                "record-3277epj0rm2y"
            ],
            "Name": "id"
        }
    ],
    "SortBy": "created-on",
    "SortOrder": "desc"
}
输出示例
{
    "Response": {
        "TotalCount": 1,
        "RequestId": "3c140219-cfe9-470e-b241-907877d6fb03",
        "DnsRecords": [
            {
                "ZoneId": "zone-2zo8myp3av8i",
                "RecordId": "record-3277epj0rm2y",
                "Name": "test.example.com",
                "Type": "A",
                "Location": "Default",
                "Content": "1.1.1.1",
                "TTL": 300,
                "Weight": -1,
                "Priority": 5,
                "Status": "enable",
                "CreatedOn": "2024-09-18T05:03:46Z",
                "ModifiedOn": "2024-09-18T05:03:46Z"
            }
        ]
    }
}
示例2 模糊查询指定记录名的 DNS 记录列表
在 ZoneId 为 zone-2zo8myp3av8i 的站点下，模糊查询记录名为 example 的 DNS 记录列表，并且按照记录名进行升序排序。

输入示例
POST / HTTP/1.1
Host: teo.tencentcloudapi.com
Content-Type: application/json
X-TC-Action: DescribeDnsRecords
<公共请求参数>

{
    "ZoneId": "zone-2zo8myp3av8i",
    "Offset": 0,
    "Limit": 100,
    "Filters": [
        {
            "Fuzzy": true,
            "Values": [
                "example"
            ],
            "Name": "name"
        }
    ],
    "SortBy": "name",
    "SortOrder": "asc"
}
输出示例
{
    "Response": {
        "TotalCount": 2,
        "RequestId": "3c140219-cfe9-470e-b241-907877d6fb03",
        "DnsRecords": [
            {
                "ZoneId": "zone-2zo8myp3av8i",
                "RecordId": "record-3277epj0rm2y",
                "Name": "test.example.com",
                "Type": "A",
                "Location": "Default",
                "Content": "1.1.1.1",
                "TTL": 300,
                "Weight": 40,
                "Priority": 5,
                "Status": "enable",
                "CreatedOn": "2024-09-18T05:03:46Z",
                "ModifiedOn": "2024-09-18T05:03:46Z"
            },
            {
                "ZoneId": "zone-2zo8myp3av8i",
                "RecordId": "record-3277epj0rm2y",
                "Name": "test.example.com",
                "Type": "A",
                "Location": "Default",
                "Content": "2.2.2.2",
                "TTL": 300,
                "Weight": 60,
                "Priority": 5,
                "Status": "enable",
                "CreatedOn": "2024-09-18T05:03:46Z",
                "ModifiedOn": "2024-09-18T05:03:46Z"
            }
        ]
    }
}
示例3 查询指定记录类型的 DNS 记录列表
在 ZoneId 为 zone-2zo8myp3av8i 的站点下，查询记录类型为 CNAME 的 DNS 记录列表，并且按照记录内容进行升序排序。

输入示例
POST / HTTP/1.1
Host: teo.tencentcloudapi.com
Content-Type: application/json
X-TC-Action: DescribeDnsRecords
<公共请求参数>

{
    "ZoneId": "zone-2zo8myp3av8i",
    "Offset": 0,
    "Limit": 100,
    "Filters": [
        {
            "Fuzzy": false,
            "Values": [
                "CNAME"
            ],
            "Name": "type"
        }
    ],
    "SortBy": "content",
    "SortOrder": "asc"
}
输出示例
{
    "Response": {
        "TotalCount": 2,
        "RequestId": "3c140219-cfe9-470e-b241-907877d6fb03",
        "DnsRecords": [
            {
                "ZoneId": "zone-2zo8myp3av8i",
                "RecordId": "record-3277epj0rm2y",
                "Name": "test.example.com",
                "Type": "CNAME",
                "Location": "CN.BJ",
                "Content": "test1.eo.dnse2.com",
                "TTL": 300,
                "Weight": -1,
                "Priority": 0,
                "Status": "enable",
                "CreatedOn": "2024-09-18T05:03:46Z",
                "ModifiedOn": "2024-09-18T05:03:46Z"
            },
            {
                "ZoneId": "zone-2zo8myp3av8i",
                "RecordId": "record-3277epj0rm2y",
                "Name": "test.example.com",
                "Type": "CNAME",
                "Location": "CN.FJ",
                "Content": "test2.eo.dnse2.com",
                "TTL": 300,
                "Weight": -1,
                "Priority": 0,
                "Status": "enable",
                "CreatedOn": "2024-09-18T05:03:46Z",
                "ModifiedOn": "2024-09-18T05:03:46Z"
            }
        ]
    }
}

# 批量修改 DNS 记录

1. 接口描述
接口请求域名： teo.tencentcloudapi.com 。

您可以通过本接口批量修改 DNS 记录。

默认接口请求频率限制：20次/秒。

推荐使用 API Explorer
点击调试
API Explorer 提供了在线调用、签名验证、SDK 代码生成和快速检索接口等能力。您可查看每次调用的请求内容和返回结果以及自动生成 SDK 调用示例。
2. 输入参数
以下请求参数列表仅列出了接口请求参数和部分公共参数，完整公共参数列表见 公共请求参数。

参数名称	必选	类型	描述
Action	是	String	公共参数，本接口取值：ModifyDnsRecords。
Version	是	String	公共参数，本接口取值：2022-09-01。
Region	否	String	公共参数，此参数为可选参数。
ZoneId	是	String	站点 ID 。
DnsRecords.N	否	Array of DnsRecord	DNS 记录修改数据列表，一次最多修改100条。
3. 输出参数
参数名称	类型	描述
RequestId	String	唯一请求 ID，由服务端生成，每次请求都会返回（若请求因其他原因未能抵达服务端，则该次请求不会获得 RequestId）。定位问题时需要提供该次请求的 RequestId。
4. 示例
示例1 批量修改指定记录 ID 的 DNS 记录
在 ZoneId 为 zone-225qgrnvbi9w 的站点下，将记录 ID 为 record-3d5dg39c 的 DNS 记录的记录名改成 eo-test1.com，记录类型改成 CNAME，记录内容改成 eo-test1.c4games.com.eo.dnse2.com；将记录 ID 为 record-gkd9gyrv 的 DNS 记录的记录名改成 eo-test2.com，记录类型改成 A，记录内容改成 1.2.3.4。

输入示例
POST / HTTP/1.1
Host: teo.tencentcloudapi.com
Content-Type: application/json
X-TC-Action: ModifyDnsRecords
<公共请求参数>

{
    "DnsRecords": [
        {
            "RecordId": "record-3d5dg39c",
            "Name": "eo-test1.com",
            "Type": "CNAME",
            "Content": "eo-test1.c4games.com.eo.dnse2.com"
        },
        {
            "RecordId": "record-gkd9gyrv",
            "Name": "eo-test2.com",
            "Type": "A",
            "Content": "1.2.3.4"
        }
    ],
    "ZoneId": "zone-20hzkd4rdmy0"
}
输出示例
{
    "Response": {
        "RequestId": "d08bed0d-15bf-4d65-ab56-906aee0c845"
    }
}
示例2 批量修改指定记录 ID 的 DNS 记录的记录权重
在 ZoneId 为 zone-225qgrnvbi9w 的站点下，将记录 ID 为 record-3d5dg39c 的 DNS 记录的记录权重改成40；将记录 ID 为 record-gkd9gyrv 的 DNS 记录的记录权重改成60。

输入示例
POST / HTTP/1.1
Host: teo.tencentcloudapi.com
Content-Type: application/json
X-TC-Action: ModifyDnsRecords
<公共请求参数>

{
    "DnsRecords": [
        {
            "RecordId": "record-3d5dg39c",
            "Weight": 40
        },
        {
            "RecordId": "record-gkd9gyrv",
            "Weight": 60
        }
    ],
    "ZoneId": "zone-20hzkd4rdmy0"
}
输出示例
{
    "Response": {
        "RequestId": "d08bed0d-15bf-4d65-ab56-906aee0c845"
    }
}
示例3 批量修改指定记录 ID 的 DNS 记录的解析线路和记录内容
在 ZoneId 为 zone-225qgrnvbi9w 的站点下，将记录 ID 为 record-3d5dg39c 的 DNS 记录的记录解析线路改成北京（CN.BJ），记录内容改成 eo-test1.c4games.com.eo.dnse2.com；将记录 ID 为 record-gkd9gyrv 的 DNS 记录的记录解析线路改成福建（CN.FJ），记录内容改成 eo-test2.c4games.com.eo.dnse2.com。

输入示例
POST / HTTP/1.1
Host: teo.tencentcloudapi.com
Content-Type: application/json
X-TC-Action: ModifyDnsRecords
<公共请求参数>

{
    "DnsRecords": [
        {
            "RecordId": "record-3d5dg39c",
            "Location": "CN.BJ",
            "Content": "eo-test1.c4games.com.eo.dnse2.com"
        },
        {
            "RecordId": "record-gkd9gyrv",
            "Location": "CN.FJ",
            "Content": "eo-test2.c4games.com.eo.dnse2.com"
        }
    ],
    "ZoneId": "zone-20hzkd4rdmy0"
}
输出示例
{
    "Response": {
        "RequestId": "d08bed0d-15bf-4d65-ab56-906aee0c845"
    }
}

# 批量修改 DNS 记录状态

1. 接口描述
接口请求域名： teo.tencentcloudapi.com 。

您可以通过本接口批量修改 DNS 记录的状态，批量对记录进行开启和停用。

默认接口请求频率限制：20次/秒。

推荐使用 API Explorer
点击调试
API Explorer 提供了在线调用、签名验证、SDK 代码生成和快速检索接口等能力。您可查看每次调用的请求内容和返回结果以及自动生成 SDK 调用示例。
2. 输入参数
以下请求参数列表仅列出了接口请求参数和部分公共参数，完整公共参数列表见 公共请求参数。

参数名称	必选	类型	描述
Action	是	String	公共参数，本接口取值：ModifyDnsRecordsStatus。
Version	是	String	公共参数，本接口取值：2022-09-01。
Region	否	String	公共参数，此参数为可选参数。
ZoneId	是	String	站点 ID。
RecordsToEnable.N	否	Array of String	待启用的 DNS 记录 ID 列表，上限：200。
注意：同个 DNS 记录 ID 不能同时存在于 RecordsToEnable 和 RecordsToDisable。
RecordsToDisable.N	否	Array of String	待停用的 DNS 记录 ID 列表，上限：200。
注意：同个 DNS 记录 ID 不能同时存在于 RecordsToEnable 和 RecordsToDisable。
3. 输出参数
参数名称	类型	描述
RequestId	String	唯一请求 ID，由服务端生成，每次请求都会返回（若请求因其他原因未能抵达服务端，则该次请求不会获得 RequestId）。定位问题时需要提供该次请求的 RequestId。
4. 示例
示例1 批量修改 DNS 记录状态
在 ZoneId 为 zone-25ryyvog1qih 的站点下，修改记录ID 为 record-25ryzh92h8qh 和 record-dldu75sgz4r1 的 DNS 记录状态为启用，修改记录ID 为 record-gkd9gyrvk8d7 和 record-lgubhs6rf9s3 的 DNS 记录状态为停用。

输入示例
POST / HTTP/1.1
Host: teo.tencentcloudapi.com
Content-Type: application/json
X-TC-Action: ModifyDnsRecordsStatus
<公共请求参数>

{
    "RecordsToEnable": [
        "record-25ryzh92h8qh",
        "record-dldu75sgz4r1"
    ],
    "RecordsToDisable": [
        "record-gkd9gyrvk8d7",
        "record-lgubhs6rf9s3"
    ],
    "ZoneId": "zone-25ryyvog1qih"
}
输出示例
{
    "Response": {
        "RequestId": "952c708d-abaf-464c-84cf-d1447887cf65"
    }
}

# 批量删除 DNS 记录

1. 接口描述
接口请求域名： teo.tencentcloudapi.com 。

您可以用本接口批量删除 DNS 记录。

默认接口请求频率限制：20次/秒。

推荐使用 API Explorer
点击调试
API Explorer 提供了在线调用、签名验证、SDK 代码生成和快速检索接口等能力。您可查看每次调用的请求内容和返回结果以及自动生成 SDK 调用示例。
2. 输入参数
以下请求参数列表仅列出了接口请求参数和部分公共参数，完整公共参数列表见 公共请求参数。

参数名称	必选	类型	描述
Action	是	String	公共参数，本接口取值：DeleteDnsRecords。
Version	是	String	公共参数，本接口取值：2022-09-01。
Region	否	String	公共参数，此参数为可选参数。
ZoneId	是	String	站点 ID。
RecordIds.N	是	Array of String	待删除的 DNS 记录 ID 列表，上限：1000。
3. 输出参数
参数名称	类型	描述
RequestId	String	唯一请求 ID，由服务端生成，每次请求都会返回（若请求因其他原因未能抵达服务端，则该次请求不会获得 RequestId）。定位问题时需要提供该次请求的 RequestId。
4. 示例
示例1 删除 DNS 记录
在 ZoneId 为 zone-25ryyvog1qih 的站点下，删除记录 ID 为 record-25ryzh92h8qh 和 record-3suf7slrsobi 的 DNS 记录。

输入示例
POST / HTTP/1.1
Host: teo.tencentcloudapi.com
Content-Type: application/json
X-TC-Action: DeleteDnsRecords
<公共请求参数>

{
    "RecordIds": [
        "record-25ryzh92h8qh",
        "record-3suf7slrsobi"
    ],
    "ZoneId": "zone-25ryyvog1qih"
}
输出示例
{
    "Response": {
        "RequestId": "6ef60bec-0242-43af-bb20-270359fb54a7"
    }
}