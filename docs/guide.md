# Guide for developing a DNS API for acme.sh

This guide is to help any developer interested to build a brand new DNS API for acme.sh

## Some useful tips

1. It's normal to run into errors, so do use `--debug 2` when testing.  For e.g., `acme.sh --issue --debug 2 -d example.com  --dns  dns_myapi`
2. It's normal to burst rate limits for Let's Encrypt, so do use `--staging` when testing. For e.g., `acme.sh --issue --staging --debug 2 -d example.com  --dns  dns_myapi` Read [issue 1787](https://github.com/acmesh-official/acme.sh/issues/1787) for details. Remember to remove `--staging` after testing.
3. It's normal that the dns script is not run if the domain was validated before. Forcing execution of the DNS API script can be achieved by clearing the "valid" status of a domain at Let’s Encrypt via the `--deactivate` command. Wildcard domains have their own status, so these have to be deactivated separately.
   ```
   acme.sh --deactivate [--server letsencrypt_test] -d 'test.example.com' -d '*.test.example.com'
   ```


Let's assume your API name is `myapi`, and you will use your API like:

```sh
export MYAPI_Username=myname
export MYAPI_Password=mypass
acme.sh --issue -d example.com --dns dns_myapi

```

Here we go:

### 1. The Cloudflare DNS API is a recommended reference:
Read it first:
https://github.com/acmesh-official/acme.sh/blob/master/dnsapi/dns_cf.sh

### 2. The script file name must be `dns_myapi.sh`
The file name must be in this format: `dns_yourApiName.sh`, in this example, it should be `dns_myapi.sh`

### 3. The file can be placed in `acme.sh/` folder, or in `acme.sh/dnsapi/` subfolder.

If you want to contribute your script to `acme.sh` project,  it must be placed in `acme.sh/dnsapi/` folder.  
If you just want to use your script on your machine, you can put it in `.acme.sh/` or `.acme.sh/dnsapi/` folders.
acme.sh searches the script files in either the  acme.sh home dir(`.acme.sh/`) or in the  `dnsapi` subfolder(`.acme.sh/dnsapi`).


### 4. There must be 2 functions in your script:

```sh
# Usage: add  _acme-challenge.www.domain.com   "XKrxpRBosdIKFzxW_CT3KLZNf6q0HG9i01zxXp5CPBs"
# Used to add txt record
dns_myapi_add() { }

# Usage: fulldomain txtvalue
# Used to remove the txt record after validation
dns_myapi_rm() { }
```

Actually, the `dns_myapi_add()` is required, but `dns_myapi_rm()` is optional.  You can just write the add function at the beginning for testing purposes, it's `highly recommended` to implement the rm function too. Otherwise, your TXT records will increase 1 every 2 months.


### 5. Guide for the add function
Steps when you write the `dns_myapi_add()` function:
#### 1. Get the full domain and the txt record:

```sh
dns_myapi_add() {
  fulldomain=$1
  txtvalue=$2
...

}

```

#### 2. You must save your username and password in the add function:
The credentials such as username, password, API key or API token etc, must be saved so that acme.sh can renew the cert automatically in future. It will reuse the credentials automatically.


```sh
dns_myapi_add() {
...

  MYAPI_Username="${MYAPI_Username:-$(_readaccountconf_mutable MYAPI_Username)}"
  MYAPI_Password="${MYAPI_Password:-$(_readaccountconf_mutable MYAPI_Password)}"
  if [ -z "$MYAPI_Username" ] || [ -z "$MYAPI_Password" ]; then
    MYAPI_Username=""
    MYAPI_Password=""
    _err "You don't specify cloudflare api key and email yet."
    _err "Please create your key and try again."
    return 1
  fi

  #save the credentials to the account conf file.
  _saveaccountconf_mutable MYAPI_Username "$MYAPI_Username"
  _saveaccountconf_mutable MYAPI_Password "$MYAPI_Password"
...

}

```

#### 3. Detect which part is your root zone.

The full domain could be in either one of the following formats: 
1. `_acme-challenge.www.example.com` 
2. `_acme-challenge.example.com` 
3. `_acme-challenge.example.co.uk`
4. `_acme-challenge.www.example.co.uk`
5. `_acme-challenge.sub1.sub2.www.example.co.uk`
6. `sub1.sub2.example.co.uk`
7. `example.com`  (For [DNS alias mode](https://github.com/acmesh-official/acme.sh/wiki/DNS-alias-mode))
8. `example.co.uk` (For [DNS alias mode](https://github.com/acmesh-official/acme.sh/wiki/DNS-alias-mode))

For most of the DNS providers, you must determine which part is the domain root zone(example.com or example.co.uk), and which part is the subdomain(_acme-challenge or _acme-challenge.www)

*You can not just split the full domain, and get the first part as a subdomain, and the rest as root zone.
Please make sure you can handle all the formats above.*

A good practice is to list all your root zones through your DNS API, then compare and detect which part is the root zone. Then the rest is the subdomain.

See: https://github.com/acmesh-official/acme.sh/blob/master/dnsapi/dns_cf.sh#L142

```sh
dns_myapi_add() {
...

  _debug "First detect the root zone"
  if ! _get_root "$fulldomain"; then
    _err "invalid domain"
    return 1
  fi

...


```

#### 4. Call your DNS API to add a TXT record.

Most of the DNS providers provide an HTTP API or REST API.

So, you can just use the HTTP GET/POST/PUT/DELETE method to call their API to add/remove the TXT record.

acme.sh defined two functions to make http GET/POST/PUT/DELETE connections.

See: 
- https://github.com/acmesh-official/acme.sh/blob/8ded524236347d5a1f7a3169809cab9cf363a1c8/acme.sh#L2013
- https://github.com/acmesh-official/acme.sh/blob/8ded524236347d5a1f7a3169809cab9cf363a1c8/acme.sh#L1887

```
_get() {}
_post() {}
```

You can use them directly.

Please take care that the `_post()` function can send POST/PUT/DELETE requests, not just `POST`.

See: 
- https://github.com/acmesh-official/acme.sh/blob/975a7359a23cd5f8335aca58ceab552d8d967ea7/dnsapi/dns_infoblox.sh#L85
- https://github.com/acmesh-official/acme.sh/blob/ded7a5438ce94c4dd0435068de5c0c384b60e4dd/dnsapi/dns_cf.sh#L73

Do not use `curl` or `wget` directly in your script. 

**Note:** Wildcard certificates require two TXT values. When implementing the method make sure that you append the value instead of replacing it

dig -t txt _acme-challenge.example.com   should return 
```
; <<>> DiG 9.10.3-P4-Ubuntu <<>> -t txt _acme-challenge.example.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 35476
;; flags: qr rd ra; QUERY: 1, ANSWER: 2, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4000
;; QUESTION SECTION:
;_acme-challenge.example.com.        IN TXT

;; ANSWER SECTION:
_acme-challenge.example.com. 3600 IN TXT "tye6yGOxJEffnXDzZKNJjOHSsCFtKwU_5L0ykmY8CzE"
_acme-challenge.example.com. 3600 IN TXT "XhVGx_0VVeR5yiaGLHHXrRl2sAbZhI7IugMSdbfR4go"
```

#### 5. Additional HTTP headers.

Your HTTP method call may require additional headers for Authorization, ContentType, Accept, Cookies, etc. for the  DNS providers API to add/remove the txt record. You can export _H*n* (_H1, _H2, _H3, etc.) environment variables with the [HTTP header](https://en.wikipedia.org/wiki/List_of_HTTP_header_fields) needed:

```sh
...

  myusername="$MYAPI_username"
  mypassword="$MYAPI_password"
  mycredentials="$(printf "%s" "$myusername:$mypassword" | _base64)"

  export _H1="Authorization: Basic $mycredentials"
  export _H2="Content-Type: application/json"

...
```

Just number the _H*n* in the order that you need the headers. Please review [these](https://github.com/acmesh-official/acme.sh/blob/master/dnsapi/dns_zone.sh#L110) [few](https://github.com/acmesh-official/acme.sh/blob/master/dnsapi/dns_desec.sh#L151) [examples](https://github.com/acmesh-official/acme.sh/blob/master/dnsapi/dns_jd.sh#L184) for inspiration.

This is the only way to pass the equivalent wget's _--user_ and _--password_ and curl's _--user_ parameters. 

#### 6. Process the API Response.

The API response could be in text, JSON or XML format. Here are a lot of functions to process strings:

```sh
...
_startswith()
_endswith()
_contains()
_egrep_o()

...
```

You can use `sed`, `grep`, `cut`, `paste` etc, Do not use `awk` at all.


### 7. Guide for the rm function.

The steps are the same as the add function.

Please take care that the rm function and add function are called in 2 different isolated subshells.  So, you can not pass any env vars from the add function to the rm function.

You must re-do all the preparations of the add function here too.

See: https://github.com/acmesh-official/acme.sh/blob/8ded524236347d5a1f7a3169809cab9cf363a1c8/dnsapi/dns_cf.sh#L106


### 8. Please also check this bug to support the V2 wildcard cert:
https://github.com/acmesh-official/acme.sh/issues/1261


### 9. Please create a new issue for future bugs
Please report a new issue here: `" Report bugs to xxxx DNS API"`  https://github.com/acmesh-official/acme.sh/issues

And please watch to that issue. Any future bug will be reported there.

Example: https://github.com/acmesh-official/acme.sh/issues/2057

### 10. Update the docs to include your DNS API usage.
Please append your API at the end: https://github.com/acmesh-official/acme.sh/wiki/dnsapi2

You must to add an anchor with your DNS API name like `<a name="dns_yourapi"/>`.
This will allow to quickly lookup your API instruction by a link https://github.com/acmesh-official/acme.sh/wiki/dnsapi2#dns_yourapi

Also don't forget to add the issue link from step 9 like `Report any bugs or issues here`.

### 11. Add structural info description

Your script should start with a [structured info description](https://github.com/acmesh-official/acme.sh/wiki/DNS-API-Structural-Info-description) to automatically generate a list of APIs and their variables.

### 12. Please read and follow the instruction before creating a pull request
Please follow the guide: https://github.com/acmesh-official/acme.sh/wiki/DNS-API-Test

See more code of conduct:  https://github.com/acmesh-official/acme.sh/wiki/Code-of-conduct