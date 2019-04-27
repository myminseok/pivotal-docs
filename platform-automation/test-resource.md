## Ref
- http://docs.pivotal.io/platform-automation/v2.1/index.html

## Prepare s3

```
-- platform-automation
    |-- platform-automation-image-2.1.1-beta.1.tgz
    `-- platform-automation-tasks-2.1.1-beta.1.zip

```

## Pipeline
- sample: https://github.com/myminseok/platform-automation-pipelines-template
```
fly -t demo sp -p test-resources -c test-resources.yml -l ./test-resources-params.yml

```

