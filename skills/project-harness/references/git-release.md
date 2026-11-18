# Versions, deployment and rollback

Use the existing repository, version convention, build script and deployment entry point. Keep related code changes together and preserve others' work. For a delivery, show the existing identifier with a date and a short change description meaningful to the user.

In the project's existing release or task record, connect the exact source revision to the actual package (digest, immutable build ID or equivalent). Record the target environment, last verified time, version observed there and relevant health or business checks. Link to that record from other documents. A package can be ready while the deployment or user acceptance is still pending.

Test the package that will run in production when the platforms match. Keep runtime paths and configuration meanings aligned between environments. Store credentials, site configuration and live data separately from replaceable application files. For distinct platforms, identify and test the corresponding artifact.

For a rollback, identify the requested environment and target using the user's description. Check the actual program and data compatibility, especially data written after the upgrade. Report what the old version can display and process, the tested recovery path, and any known loss of access or data. A retained backup or equal schema number alone cannot establish compatibility. Use an isolated copy to test a quick switch before describing it as supported.

Run real deployment, program rollback, or restoration of a database backup within the scope authorized for that operation. Keep the result and any remaining business checks in the existing delivery record.
