## Git & Commit Discipline

You must create atomic git commits for every discrete logical unit of work without waiting for explicit reminders. A logical unit is the smallest independently functional or coherent change. Use the already configured user.name and user.email in git config.

## External Depencencies
Usage of external dependencies are encouraged as long as they are well maintained and supported. You should always attempt to query the current latest version of the dependencies whenever possible. This includes GitHub Actions. Do not use wildcard major version, e.g. never use "latest" in docker image tag. Wildcard patch version is usually acceptable, and wildcard minor version are situationally acceptable.

## Environment & Testing

You are inside an isolated docker container. You are free to install any dependencies you deem necessary for testing the functionality of the code you have written. Avoid one-time only tests and write reusable tests instead.
