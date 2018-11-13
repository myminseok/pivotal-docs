https://github.com/cloudfoundry-attic/vcap

python support docs: https://github.com/cloudfoundry-attic/vcap/blob/master/docs/python.md
```

### Accessing the database

Cloud Foundry makes the service connection credentials available as JSON via the
`VCAP_SERVICES` environment variable. Using this knowledge, you can use the
following snippet in your own settings.py:

    ## Pull in CloudFoundry's production settings
    if 'VCAP_SERVICES' in os.environ:
        import json
        vcap_services = json.loads(os.environ['VCAP_SERVICES'])
        # XXX: avoid hardcoding here
        mysql_srv = vcap_services['mysql-5.1'][0]
        cred = mysql_srv['credentials']
        DATABASES = {
            'default': {
                'ENGINE': 'django.db.backends.mysql',
                'NAME': cred['name'],
                'USER': cred['user'],
                'PASSWORD': cred['password'],
                'HOST': cred['hostname'],
                'PORT': cred['port'],
                }
            }
    else:
        DATABASES = {
            "default": {
                "ENGINE": "django.db.backends.sqlite3",
                "NAME": "dev.db",
                "USER": "",
                "PASSWORD": "",
                "HOST": "",
                "PORT": "",
                }
            }

```
