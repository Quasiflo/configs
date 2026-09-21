# Renovate Shared Configurations

## Installation

<!-- x-release-please-start-version -->

```json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": [
    "local>Quasiflo/configs//renovate/renovate.json5#v0.1.0"
    "local>Quasiflo/configs//renovate/ignoreGithubApp.json5#-v0.1.0(123456789,gh-app-name)" // Optionally ignore commits from our repo ci app
  ]
}
```

<!-- x-release-please-end -->
